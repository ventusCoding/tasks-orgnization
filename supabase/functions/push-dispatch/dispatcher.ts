// push-dispatch orchestration (arch §6.13 step 4, T7.4.07):
//   claim → lateness/expiry → guards → inbox upsert → per-device decision → FCM → deliveries → job status.
// All I/O goes through the DispatchStore / PushSender ports so every branch is unit tested.

import { mapWithConcurrency } from "../_shared/background.ts";
import type { FcmMessage, FcmSendResult, PushSender } from "../_shared/fcm.ts";
import { type EmailSender, renderDigestEmail, unsubscribeUrl } from "../_shared/email.ts";
import type { Logger } from "../_shared/log.ts";
import type { ClaimedJob, DeliveryRecord, GuardResult, JobResult, UserDevices } from "../_shared/types.ts";
import { backoffSeconds, classifyJob, decideDevices } from "./decisions.ts";
import { buildBurstMessage, buildJobMessage, BURST_MIN_JOBS } from "./payload.ts";

export interface DispatchStore {
  claim(limit: number, leaseSeconds: number): Promise<ClaimedJob[]>;
  guards(jobs: ClaimedJob[]): Promise<GuardResult[]>;
  upsertInbox(items: Array<{ job: ClaimedJob; late: boolean }>): Promise<void>;
  devices(userIds: string[]): Promise<Record<string, UserDevices>>;
  complete(results: JobResult[]): Promise<void>;
  heartbeat(name: string, details: Record<string, unknown>): Promise<void>;
  /** Opted-in digest email recipients (T7.4.18); absent = email not wired. */
  emailTargets?(userIds: string[]): Promise<Record<string, EmailTarget>>;
}

export interface EmailTarget {
  email: string;
  locale: string;
  /** Digest kinds to email (empty = all). */
  kinds: string[];
}

/** Pseudo device id of the email channel in push_deliveries (one email per job, never re-sent). */
export const EMAIL_DEVICE_ID = "00000000-0000-4000-8000-00000000e3a1";

export interface EmailOptions {
  sender: EmailSender;
  /** Secret signing the unsubscribe links. */
  linkSecret: string;
  /** Public project URL (unsubscribe endpoint). */
  baseUrl: string;
}

export interface DispatchOptions {
  store: DispatchStore;
  /** null when FCM is not configured: inbox rows are still written, pushes are skipped. */
  sender: PushSender | null;
  now?: () => Date;
  batchSize?: number;
  leaseSeconds?: number;
  maxBatches?: number;
  /** Wall-clock budget for one invocation (hosted limit: 150 s free / 400 s paid). */
  budgetMs?: number;
  concurrency?: number;
  random?: () => number;
  log?: Logger;
  /** Digest emails (T7.4.18); null/absent = not configured. */
  email?: EmailOptions | null;
}

export interface DispatchSummary {
  claimed: number;
  sent: number;
  skipped: number;
  expired: number;
  failed: number;
  retried: number;
  pushes: number;
  pushFailures: number;
  pushConfigured: boolean;
  batches: number;
  emails: number;
}

interface PendingSend {
  /** Jobs delivered by this message (several for a coalesced burst). */
  jobs: ClaimedJob[];
  deviceId: string;
  message: FcmMessage;
}

export async function runDispatch(options: DispatchOptions): Promise<DispatchSummary> {
  const now = options.now ?? (() => new Date());
  const batchSize = options.batchSize ?? 200;
  const leaseSeconds = options.leaseSeconds ?? 120;
  const maxBatches = options.maxBatches ?? 20;
  const budgetMs = options.budgetMs ?? 25_000;
  const concurrency = options.concurrency ?? 32;
  const random = options.random ?? Math.random;
  const startedAt = Date.now();

  const summary: DispatchSummary = {
    claimed: 0,
    sent: 0,
    skipped: 0,
    expired: 0,
    failed: 0,
    retried: 0,
    pushes: 0,
    pushFailures: 0,
    pushConfigured: options.sender !== null,
    batches: 0,
    emails: 0,
  };

  while (summary.batches < maxBatches && Date.now() - startedAt < budgetMs) {
    const jobs = await options.store.claim(batchSize, leaseSeconds);
    if (jobs.length === 0) break;
    summary.batches++;
    summary.claimed += jobs.length;

    const results = await processBatch(jobs, options, now(), concurrency, random, summary);
    await options.store.complete(results);
    for (const r of results) {
      if (r.status === "sent") summary.sent++;
      else if (r.status === "skipped") summary.skipped++;
      else if (r.status === "expired") summary.expired++;
      else if (r.status === "failed") summary.failed++;
      else if (r.status === "retry") summary.retried++;
    }
    if (jobs.length < batchSize) break;
  }

  await options.store.heartbeat("push_dispatch", { ...summary }).catch(() => {});
  options.log?.("info", "push_dispatch.done", { ...summary });
  return summary;
}

async function processBatch(
  jobs: ClaimedJob[],
  options: DispatchOptions,
  now: Date,
  concurrency: number,
  random: () => number,
  summary: DispatchSummary,
): Promise<JobResult[]> {
  const { store, sender } = options;
  const results = new Map<string, JobResult>();
  const result = (job: ClaimedJob): JobResult => {
    let r = results.get(job.id);
    if (!r) {
      r = { job_id: job.id, status: "skipped", reason: null, deliveries: [], invalid_device_ids: [] };
      results.set(job.id, r);
    }
    return r;
  };

  const userIds = [...new Set(jobs.map((j) => j.user_id))];
  const devicesByUser = await store.devices(userIds);

  // 1. Expiry (lateness policy: never deliver after expires_at).
  const live: Array<{ job: ClaimedJob; late: boolean }> = [];
  const expiredInbox: Array<{ job: ClaimedJob; late: boolean }> = [];
  for (const job of jobs) {
    const policy = devicesByUser[job.user_id]?.policy ?? {};
    const c = classifyJob(job, now, policy);
    if (c.kind === "expired") {
      Object.assign(result(job), { status: "expired", reason: "expired" });
      if (job.payload?.inboxWhenExpired === true && job.payload?.inbox !== false) {
        expiredInbox.push({ job, late: true });
      }
    } else {
      live.push({ job, late: c.late });
    }
  }

  // 2. Guards (task still open, habit period not done, item still waiting, not muted…).
  const guardResults = live.length > 0 ? await store.guards(live.map((l) => l.job)) : [];
  const guardById = new Map(guardResults.map((g) => [g.job_id, g]));
  const passing = live.filter(({ job }) => {
    const g = guardById.get(job.id);
    if (g && !g.ok) {
      Object.assign(result(job), { status: "skipped", reason: `guard:${g.reason ?? "false"}` });
      return false;
    }
    return true;
  });

  // 3. Inbox rows (idempotent id = uuid_v5(dedupe_key); delivery fields merged on conflict).
  const inboxItems = [...expiredInbox, ...passing.filter(({ job }) => job.payload?.inbox !== false)];
  if (inboxItems.length > 0) await store.upsertInbox(inboxItems);

  // 4. Per-device decisions.
  const perDevice = new Map<string, { device: UserDevices["devices"][number]; jobs: ClaimedJob[] }>();
  for (const { job } of passing) {
    const r = result(job);
    if (job.payload?.system === false) {
      Object.assign(r, { status: "sent", reason: "inbox_only" });
      continue;
    }
    const { policy, devices } = devicesByUser[job.user_id] ?? { policy: {}, devices: [] };
    const decisions = decideDevices(job, devices, policy, now);
    let toSend = 0;
    for (const d of decisions) {
      if (d.action === "skip") {
        r.deliveries.push({ device_id: d.deviceId, outcome: d.outcome, error_code: d.reason });
      } else if (d.action === "send") {
        toSend++;
        if (sender) {
          const device = devices.find((x) => x.id === d.deviceId)!;
          const entry = perDevice.get(d.deviceId) ?? { device, jobs: [] };
          entry.jobs.push(job);
          perDevice.set(d.deviceId, entry);
        }
      }
    }
    const alreadySent = (job.sent_device_ids ?? []).length > 0;
    if (toSend === 0) {
      const local = r.deliveries.some((x) => x.outcome === "skipped_local");
      Object.assign(
        r,
        alreadySent ? { status: "sent", reason: "already_sent", pushed: true } : {
          status: "skipped",
          reason: decisions.length === 0 ? "no_devices" : local ? "covered_locally" : "policy",
        },
      );
    } else if (!sender) {
      Object.assign(r, { status: "skipped", reason: "push_not_configured" });
    }
  }

  // 5. Messages: same-minute bursts on one device become one push; everything else one push per job.
  const sends: PendingSend[] = [];
  for (const [deviceId, { device, jobs: deviceJobs }] of perDevice) {
    const byMinute = new Map<string, ClaimedJob[]>();
    for (const job of deviceJobs) {
      const key = job.fire_at.slice(0, 16);
      byMinute.set(key, [...(byMinute.get(key) ?? []), job]);
    }
    for (const group of byMinute.values()) {
      if (group.length >= BURST_MIN_JOBS) {
        sends.push({ jobs: group, deviceId, message: buildBurstMessage(group, device, now) });
      } else {
        for (const job of group) {
          sends.push({ jobs: [job], deviceId, message: buildJobMessage(job, device, now) });
        }
      }
    }
  }

  // 6. FCM sends (one request per token, bounded parallelism).
  if (sender && sends.length > 0) {
    const outcomes = await mapWithConcurrency(sends, concurrency, async (s): Promise<FcmSendResult> => {
      try {
        return await sender.send(s.message);
      } catch (err) {
        return {
          ok: false,
          kind: "network_error",
          tokenInvalid: false,
          retryable: true,
          message: err instanceof Error ? err.message : String(err),
        };
      }
    });
    summary.pushes += sends.length;

    const perJob = new Map<
      string,
      { job: ClaimedJob; sent: number; retry: number; retryAfter: number; codes: string[] }
    >();
    sends.forEach((s, i) => {
      const o = outcomes[i];
      if (!o.ok) summary.pushFailures++;
      for (const job of s.jobs) {
        const r = result(job);
        const agg = perJob.get(job.id) ?? { job, sent: 0, retry: 0, retryAfter: 0, codes: [] };
        perJob.set(job.id, agg);
        let delivery: DeliveryRecord;
        if (o.ok) {
          agg.sent++;
          delivery = { device_id: s.deviceId, outcome: "sent", fcm_message_id: o.messageId };
        } else {
          agg.codes.push(o.kind);
          if (o.tokenInvalid) {
            if (!r.invalid_device_ids.includes(s.deviceId)) r.invalid_device_ids.push(s.deviceId);
            delivery = { device_id: s.deviceId, outcome: "token_invalid", error_code: o.kind };
          } else {
            if (o.retryable) {
              agg.retry++;
              agg.retryAfter = Math.max(agg.retryAfter, o.retryAfterSeconds ?? 0);
            }
            delivery = { device_id: s.deviceId, outcome: "failed", error_code: o.kind };
          }
        }
        r.deliveries.push(delivery);
      }
    });

    for (const agg of perJob.values()) {
      const r = result(agg.job);
      const pushedBefore = (agg.job.sent_device_ids ?? []).length > 0;
      if (agg.retry > 0) {
        // Retry only the failed devices later (sent ones are final: push_deliveries unique per device).
        Object.assign(r, {
          status: "retry",
          reason: agg.codes.join(","),
          retry_after_seconds: Math.max(agg.retryAfter, backoffSeconds(agg.job.attempts, random)),
          pushed: agg.sent > 0 || pushedBefore,
        });
      } else if (agg.sent > 0 || pushedBefore) {
        Object.assign(r, { status: "sent", reason: null, pushed: true });
      } else {
        Object.assign(r, { status: "failed", reason: agg.codes.join(",") });
      }
    }
  }

  // 7. Digest emails for opted-in users (once per job; never individual reminders).
  const email = options.email;
  const digests = passing.filter(({ job }) =>
    (job.payload?.type === "digest" || job.payload?.category === "digest") &&
    !(job.sent_device_ids ?? []).includes(EMAIL_DEVICE_ID)
  );
  if (email && store.emailTargets && digests.length > 0) {
    const targets = await store.emailTargets([...new Set(digests.map(({ job }) => job.user_id))]);
    for (const { job } of digests) {
      const t = targets[job.user_id];
      const kind = typeof job.payload?.digestKind === "string" ? job.payload.digestKind : null;
      if (!t || (t.kinds.length > 0 && (kind === null || !t.kinds.includes(kind)))) continue;
      const message = renderDigestEmail({
        to: t.email,
        locale: t.locale,
        title: typeof job.payload?.title === "string" ? job.payload.title : "Everslot",
        body: typeof job.payload?.body === "string" ? job.payload.body : "",
        unsubscribeUrl: await unsubscribeUrl(email.baseUrl, email.linkSecret, job.user_id),
      });
      const sent = await email.sender.send(message);
      const r = result(job);
      r.deliveries.push(
        sent.ok ? { device_id: EMAIL_DEVICE_ID, outcome: "email_sent", fcm_message_id: sent.id } : {
          device_id: EMAIL_DEVICE_ID,
          outcome: "email_failed",
          error_code: String(sent.status ?? "error"),
        },
      );
      if (sent.ok) {
        summary.emails++;
        if (r.status === "skipped") Object.assign(r, { status: "sent", reason: "email" });
      }
    }
  }

  return jobs.map((j) => result(j));
}
