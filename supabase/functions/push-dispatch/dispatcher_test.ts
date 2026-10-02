import type { FcmMessage, FcmSendResult, PushSender } from "../_shared/fcm.ts";
import { assert, assertEquals, makeDevice, makeJob, NOW } from "../_shared/test_utils.ts";
import type { ClaimedJob, DispatchDevice, GuardResult, JobResult, UserDevices } from "../_shared/types.ts";
import { type DispatchStore, runDispatch } from "./dispatcher.ts";

class FakeStore implements DispatchStore {
  batches: ClaimedJob[][];
  guardResults = new Map<string, GuardResult>();
  inbox: Array<{ job: ClaimedJob; late: boolean }> = [];
  completed: JobResult[] = [];
  heartbeats: string[] = [];
  constructor(jobs: ClaimedJob[], readonly devicesByUser: Record<string, UserDevices>) {
    this.batches = [jobs];
  }
  claim() {
    return Promise.resolve(this.batches.shift() ?? []);
  }
  guards(jobs: ClaimedJob[]) {
    return Promise.resolve(
      jobs.map((j) => this.guardResults.get(j.id) ?? { job_id: j.id, ok: true, reason: null }),
    );
  }
  upsertInbox(items: Array<{ job: ClaimedJob; late: boolean }>) {
    this.inbox.push(...items);
    return Promise.resolve();
  }
  devices(userIds: string[]) {
    return Promise.resolve(
      Object.fromEntries(userIds.map((u) => [u, this.devicesByUser[u] ?? { policy: {}, devices: [] }])),
    );
  }
  complete(results: JobResult[]) {
    this.completed.push(...results);
    return Promise.resolve();
  }
  heartbeat(name: string) {
    this.heartbeats.push(name);
    return Promise.resolve();
  }
}

class FakeSender implements PushSender {
  sent: FcmMessage[] = [];
  constructor(private readonly respond: (m: FcmMessage) => FcmSendResult) {}
  send(message: FcmMessage) {
    this.sent.push(message);
    return Promise.resolve(this.respond(message));
  }
}

const ok = (): FcmSendResult => ({ ok: true, kind: "ok", messageId: "projects/p/messages/1" });
const user = makeJob().user_id;
const store = (jobs: ClaimedJob[], devices: DispatchDevice[], policy = {}) =>
  new FakeStore(jobs, { [user]: { policy, devices } });
const run = (s: DispatchStore, sender: PushSender | null) =>
  runDispatch({ store: s, sender, now: () => NOW, random: () => 0.5 });

Deno.test("guard false → skipped, no inbox row, no push", async () => {
  const s = store([makeJob()], [makeDevice()]);
  s.guardResults.set(makeJob().id, { job_id: makeJob().id, ok: false, reason: "occurrence_closed" });
  const sender = new FakeSender(ok);
  const summary = await run(s, sender);
  assertEquals(s.completed[0].status, "skipped");
  assertEquals(s.completed[0].reason, "guard:occurrence_closed");
  assertEquals(s.inbox.length, 0);
  assertEquals(sender.sent.length, 0);
  assertEquals(summary.skipped, 1);
});

Deno.test("expired job → expired, never pushed (inbox only when configured)", async () => {
  const expired = makeJob({ expires_at: "2026-09-22T09:00:00Z" });
  const s = store([expired], [makeDevice()]);
  const sender = new FakeSender(ok);
  await run(s, sender);
  assertEquals(s.completed[0].status, "expired");
  assertEquals(sender.sent.length, 0);
  assertEquals(s.inbox.length, 0);

  const s2 = store([
    makeJob({ expires_at: "2026-09-22T09:00:00Z", payload: { title: "x", inboxWhenExpired: true } }),
  ], []);
  await run(s2, sender);
  assertEquals(s2.inbox.map((i) => i.late), [true]);
});

Deno.test("FCM not configured → inbox row written, job skipped (push_not_configured)", async () => {
  const s = store([makeJob()], [
    makeDevice(),
    makeDevice({ id: "covered", local_coverage_until: "2026-09-23T00:00:00Z", schedule_rev: 100 }),
  ]);
  const summary = await run(s, null);
  assertEquals(s.inbox.length, 1);
  assertEquals(s.completed[0].status, "skipped");
  assertEquals(s.completed[0].reason, "push_not_configured");
  assertEquals(s.completed[0].deliveries.map((d) => d.outcome), ["skipped_local"]);
  assertEquals(summary.pushConfigured, false);
});

Deno.test("successful push → sent, delivery recorded, message keyed by the dedupe key", async () => {
  const s = store([makeJob()], [makeDevice()]);
  const sender = new FakeSender(ok);
  const summary = await run(s, sender);
  assertEquals(s.completed[0].status, "sent");
  assertEquals(s.completed[0].pushed, true);
  assertEquals(s.completed[0].deliveries, [
    { device_id: makeDevice().id, outcome: "sent", fcm_message_id: "projects/p/messages/1" },
  ]);
  assertEquals(sender.sent[0].token, "token-d1");
  assertEquals(sender.sent[0].android?.notification?.tag, makeJob().dedupe_key);
  assertEquals(sender.sent[0].apns?.headers?.["apns-collapse-id"], makeJob().dedupe_key);
  assertEquals(summary.sent, 1);
  assertEquals(s.inbox.length, 1);
  assertEquals(s.heartbeats, ["push_dispatch"]);
});

Deno.test("covered device is skipped while another device is pushed", async () => {
  const covered = makeDevice({
    id: "phone",
    local_coverage_until: "2026-09-23T00:00:00Z",
    schedule_rev: 100,
  });
  const tablet = makeDevice({ id: "tablet", push_token: "token-tablet" });
  const s = store([makeJob()], [covered, tablet]);
  const sender = new FakeSender(ok);
  await run(s, sender);
  assertEquals(sender.sent.map((m) => m.token), ["token-tablet"]);
  assertEquals(s.completed[0].deliveries.map((d) => `${d.device_id}:${d.outcome}`), [
    "phone:skipped_local",
    "tablet:sent",
  ]);
});

Deno.test("all devices cover locally → skipped (covered_locally), no push", async () => {
  const covered = makeDevice({ local_coverage_until: "2026-09-23T00:00:00Z", schedule_rev: 100 });
  const s = store([makeJob()], [covered]);
  const sender = new FakeSender(ok);
  await run(s, sender);
  assertEquals(sender.sent.length, 0);
  assertEquals(s.completed[0].status, "skipped");
  assertEquals(s.completed[0].reason, "covered_locally");
});

Deno.test("UNREGISTERED → token_invalid, device token cleared, job failed", async () => {
  const s = store([makeJob()], [makeDevice()]);
  const sender = new FakeSender(() => ({
    ok: false,
    kind: "unregistered",
    tokenInvalid: true,
    retryable: false,
  }));
  await run(s, sender);
  assertEquals(s.completed[0].status, "failed");
  assertEquals(s.completed[0].invalid_device_ids, [makeDevice().id]);
  assertEquals(s.completed[0].deliveries[0].outcome, "token_invalid");
});

Deno.test("QUOTA_EXCEEDED → retry honouring Retry-After", async () => {
  const s = store([makeJob()], [makeDevice()]);
  const sender = new FakeSender(() => ({
    ok: false,
    kind: "quota_exceeded",
    tokenInvalid: false,
    retryable: true,
    retryAfterSeconds: 300,
  }));
  const summary = await run(s, sender);
  assertEquals(s.completed[0].status, "retry");
  assertEquals(s.completed[0].retry_after_seconds, 300);
  assertEquals(summary.retried, 1);
});

Deno.test("5xx → retry with exponential backoff; sent devices are final", async () => {
  const a = makeDevice({ id: "a", push_token: "ta" });
  const b = makeDevice({ id: "b", push_token: "tb" });
  const s = store([makeJob({ attempts: 2 })], [a, b]);
  const sender = new FakeSender((m) =>
    m.token === "ta" ? ok() : { ok: false, kind: "unavailable", tokenInvalid: false, retryable: true }
  );
  await run(s, sender);
  const r = s.completed[0];
  assertEquals(r.status, "retry");
  assertEquals(r.retry_after_seconds, 240); // attempt 3 → 4 min
  assertEquals(r.pushed, true);
  assertEquals(r.deliveries.map((d) => `${d.device_id}:${d.outcome}`), ["a:sent", "b:failed"]);

  // Next run: device a already has a sent delivery → only b is retried.
  const s2 = store([makeJob({ attempts: 3, sent_device_ids: ["a"] })], [a, b]);
  const sender2 = new FakeSender(ok);
  await run(s2, sender2);
  assertEquals(sender2.sent.map((m) => m.token), ["tb"]);
  assertEquals(s2.completed[0].status, "sent");
});

Deno.test("inbox-only and push-only deliveries", async () => {
  const inboxOnly = makeJob({ id: "j-inbox", payload: { title: "Digest", system: false } });
  const pushOnly = makeJob({ id: "j-push", dedupe_key: "k2", payload: { title: "Ping", inbox: false } });
  const s = store([inboxOnly, pushOnly], [makeDevice()]);
  const sender = new FakeSender(ok);
  await run(s, sender);
  assertEquals(s.inbox.map((i) => i.job.id), ["j-inbox"]);
  assertEquals(sender.sent.length, 1);
  assertEquals(s.completed.map((r) => `${r.job_id}:${r.status}:${r.reason ?? ""}`), [
    "j-inbox:sent:inbox_only",
    "j-push:sent:",
  ]);
});

Deno.test("no devices → skipped (no_devices), inbox still written", async () => {
  const s = store([makeJob()], []);
  await run(s, new FakeSender(ok));
  assertEquals(s.completed[0].reason, "no_devices");
  assertEquals(s.inbox.length, 1);
});

Deno.test("keeps claiming batches until the queue is empty", async () => {
  const s = new FakeStore([], {});
  s.batches = [
    Array.from({ length: 3 }, (_, i) => makeJob({ id: `a${i}`, dedupe_key: `k${i}` })),
    [makeJob({ id: "b0", dedupe_key: "kb" })],
  ];
  const summary = await runDispatch({ store: s, sender: null, now: () => NOW, batchSize: 3 });
  assertEquals(summary.batches, 2);
  assertEquals(summary.claimed, 4);
  assert(s.completed.every((r) => r.reason === "no_devices"));
});

const jobN = (i: number, fire = "2026-09-22T10:00:00Z") =>
  makeJob({
    id: `00000000-0000-4000-8000-${String(i).padStart(12, "0")}`,
    dedupe_key: `dk-${i}`,
    fire_at: fire,
    payload: { title: `Task ${i}`, type: "reminder", channel: "planner_default" },
  });

Deno.test("a same-minute burst on one device becomes one merged push (T7.4.07 step 7)", async () => {
  const jobs = [jobN(1), jobN(2), jobN(3), jobN(4, "2026-09-22T10:01:00Z")];
  const s = store(jobs, [makeDevice()]);
  const sender = new FakeSender(ok);
  const summary = await run(s, sender);
  // Three 10:00 jobs → one digest push; the 10:01 job alone → its own push.
  assertEquals(sender.sent.length, 2);
  const merged = sender.sent.find((m) => m.data?.type === "digest")!;
  assertEquals(merged.data?.count, "3");
  assertEquals(merged.data?.dks, "dk-1,dk-2,dk-3");
  assert(String(merged.android?.notification?.body ?? "").includes("Task 2"));
  assertEquals(summary.sent, 4);
  for (const r of s.completed) {
    assertEquals(r.status, "sent");
    assertEquals(r.deliveries.length, 1);
    assertEquals(r.deliveries[0].outcome, "sent");
  }
  // Every job still gets its own inbox row.
  assertEquals(s.inbox.length, 4);
});

Deno.test("two same-minute jobs stay separate actionable pushes", async () => {
  const s = store([jobN(1), jobN(2)], [makeDevice()]);
  const sender = new FakeSender(ok);
  await run(s, sender);
  assertEquals(sender.sent.length, 2);
  assert(sender.sent.every((m) => m.data?.type === "reminder"));
});

Deno.test("load: 10 000 due jobs for 500 users drain in one run well under the 30 s cadence", async () => {
  const users = 500;
  const all: ClaimedJob[] = [];
  const devicesByUser: Record<string, UserDevices> = {};
  for (let u = 0; u < users; u++) {
    const userId = `00000000-0000-4000-9000-${String(u).padStart(12, "0")}`;
    devicesByUser[userId] = {
      policy: {},
      devices: [
        makeDevice({ id: `00000000-0000-4000-a000-${String(u).padStart(12, "0")}`, push_token: `t${u}` }),
      ],
    };
    for (let k = 0; k < 20; k++) {
      all.push(
        makeJob({
          id: `00000000-0000-4000-b${String(u).padStart(3, "0")}-${String(k).padStart(12, "0")}`,
          user_id: userId,
          dedupe_key: `u${u}-k${k}`,
          fire_at: `2026-09-22T09:${String(30 + k).padStart(2, "0")}:00Z`,
        }),
      );
    }
  }
  const s = new FakeStore([], devicesByUser);
  s.batches = [];
  for (let i = 0; i < all.length; i += 200) s.batches.push(all.slice(i, i + 200));
  const sender = new FakeSender(ok);
  const started = performance.now();
  const summary = await runDispatch({
    store: s,
    sender,
    now: () => NOW,
    random: () => 0.5,
    maxBatches: 100,
    budgetMs: 25_000,
  });
  const elapsed = performance.now() - started;
  assertEquals(summary.claimed, 10_000);
  assertEquals(summary.sent, 10_000);
  // Processing overhead (FCM latency excluded) must leave the 30 s cadence plenty of room.
  assert(elapsed < 5_000, `dispatch overhead ${elapsed.toFixed(0)} ms`);
});

// -- Digest emails (T7.4.18) -----------------------------------------------------------------------

import type { EmailMessage, EmailResult, EmailSender } from "../_shared/email.ts";
import { EMAIL_DEVICE_ID, type EmailTarget } from "./dispatcher.ts";

class FakeEmail implements EmailSender {
  sent: EmailMessage[] = [];
  constructor(private readonly result: EmailResult = { ok: true, id: "em_1" }) {}
  send(m: EmailMessage) {
    this.sent.push(m);
    return Promise.resolve(this.result);
  }
}

const digest = (over: Partial<ClaimedJob> = {}) =>
  makeJob({
    id: "00000000-0000-4000-8000-0000000000e1",
    dedupe_key: "digest-1",
    payload: {
      title: "Today: 3 tasks",
      body: "Gym 08:00\nReport 10:00",
      type: "digest",
      digestKind: "daily_agenda",
    },
    ...over,
  });

function emailStore(jobs: ClaimedJob[], targets: Record<string, EmailTarget>, devices = [makeDevice()]) {
  const s = store(jobs, devices) as FakeStore & {
    emailTargets: (ids: string[]) => Promise<Record<string, EmailTarget>>;
  };
  s.emailTargets = (ids) =>
    Promise.resolve(Object.fromEntries(ids.filter((i) => targets[i]).map((i) => [i, targets[i]])));
  return s;
}

Deno.test("digest jobs are emailed once to opted-in users with a signed unsubscribe link", async () => {
  const s = emailStore([digest()], { [user]: { email: "me@x.io", locale: "fr", kinds: [] } });
  const mail = new FakeEmail();
  const summary = await runDispatch({
    store: s,
    sender: new FakeSender(ok),
    now: () => NOW,
    random: () => 0.5,
    email: { sender: mail, linkSecret: "sec", baseUrl: "https://p.supabase.co" },
  });
  assertEquals(summary.emails, 1);
  assertEquals(mail.sent[0].to, "me@x.io");
  assertEquals(mail.sent[0].subject, "Today: 3 tasks");
  assert(mail.sent[0].html.includes("Se désabonner"));
  assert(String(mail.sent[0].headers?.["List-Unsubscribe"]).includes("/functions/v1/email-unsubscribe?u="));
  const r = s.completed[0];
  assert(r.deliveries.some((d) => d.device_id === EMAIL_DEVICE_ID && d.outcome === "email_sent"));
});

Deno.test("reminders are never emailed; kinds filter; already-emailed digests are not re-sent", async () => {
  const targets = { [user]: { email: "me@x.io", locale: "en", kinds: ["weekly_review"] } };
  const mail = new FakeEmail();
  const opts = { sender: mail, linkSecret: "sec", baseUrl: "https://p" };
  // A reminder and a daily digest the user did not choose.
  await runDispatch({
    store: emailStore([makeJob(), digest()], targets),
    sender: null,
    now: () => NOW,
    email: opts,
  });
  assertEquals(mail.sent.length, 0);
  // A weekly digest already emailed on a previous (retried) run.
  const weekly = digest({
    payload: { title: "Week", body: "x", type: "digest", digestKind: "weekly_review" },
    sent_device_ids: [EMAIL_DEVICE_ID],
  });
  await runDispatch({ store: emailStore([weekly], targets), sender: null, now: () => NOW, email: opts });
  assertEquals(mail.sent.length, 0);
});

Deno.test("an emailed digest counts as delivered even when every device covers it locally", async () => {
  const covered = makeDevice({ schedule_rev: 200, local_coverage_until: "2026-09-23T00:00:00Z" });
  const s = emailStore([digest()], { [user]: { email: "me@x.io", locale: "en", kinds: [] } }, [covered]);
  await runDispatch({
    store: s,
    sender: new FakeSender(ok),
    now: () => NOW,
    email: { sender: new FakeEmail(), linkSecret: "s", baseUrl: "https://p" },
  });
  assertEquals(s.completed[0].status, "sent");
  assertEquals(s.completed[0].reason, "email");
});
