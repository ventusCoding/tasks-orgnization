import type { FcmMessage, PushSender } from "../_shared/fcm.ts";
import { assertEquals, NOW } from "../_shared/test_utils.ts";
import { createHandler, parseNudgeEvent } from "./handler.ts";
import { type NudgeDevice, type NudgeStore, runNudge, selectNudgeTargets } from "./nudge.ts";

const dev = (o: Partial<NudgeDevice>): NudgeDevice => ({
  id: "d",
  platform: "android",
  push_token: "tok",
  push_enabled: true,
  revoked_at: null,
  last_seen_at: "2026-09-22T08:00:00Z",
  last_nudged_at: null,
  ...o,
});

const USER = "00000000-0000-4000-8000-0000000000b1";
const ORIGIN = "00000000-0000-4000-8000-0000000000d0";

Deno.test("selectNudgeTargets skips origin, foreground, throttled and unusable devices", () => {
  const devices = [
    dev({ id: ORIGIN }),
    dev({ id: "fg", last_seen_at: "2026-09-22T09:59:00Z" }),
    dev({ id: "android-recent", last_nudged_at: "2026-09-22T09:59:30Z" }),
    dev({ id: "android-ok", last_nudged_at: "2026-09-22T09:58:00Z" }),
    dev({ id: "ios-throttled", platform: "ios", last_nudged_at: "2026-09-22T09:45:00Z" }),
    dev({ id: "ios-ok", platform: "ios", last_nudged_at: "2026-09-22T09:30:00Z" }),
    dev({ id: "no-token", push_token: null }),
    dev({ id: "disabled", push_enabled: false }),
    dev({ id: "revoked", revoked_at: "2026-09-01T00:00:00Z" }),
  ];
  const { targets, skipped } = selectNudgeTargets(devices, ORIGIN, NOW);
  assertEquals(targets.map((d) => d.id), ["android-ok", "ios-ok"]);
  assertEquals(Object.fromEntries(skipped.map((s) => [s.id, s.reason])), {
    [ORIGIN]: "origin",
    "fg": "foreground",
    "android-recent": "throttled",
    "ios-throttled": "throttled",
    "no-token": "no_token",
    "disabled": "push_disabled",
    "revoked": "revoked",
  });
});

function fakeStore(devices: NudgeDevice[]) {
  const marked: string[][] = [];
  const cleared: string[][] = [];
  const store: NudgeStore = {
    devices: () => Promise.resolve(devices),
    markNudged: (ids) => {
      marked.push(ids);
      return Promise.resolve();
    },
    clearTokens: (ids) => {
      cleared.push(ids);
      return Promise.resolve();
    },
  };
  return { store, marked, cleared };
}

Deno.test("runNudge sends a data-only sync message, marks devices and drops invalid tokens", async () => {
  const { store, marked, cleared } = fakeStore([
    dev({ id: "a", push_token: "ta" }),
    dev({ id: "b", push_token: "tb" }),
    dev({ id: ORIGIN, push_token: "to" }),
  ]);
  const sent: FcmMessage[] = [];
  const sender: PushSender = {
    send: (m) => {
      sent.push(m);
      return Promise.resolve(
        m.token === "tb"
          ? { ok: false, kind: "unregistered", tokenInvalid: true, retryable: false }
          : { ok: true, kind: "ok", messageId: "m" },
      );
    },
  };
  const summary = await runNudge(
    { user_id: USER, head_rev: 77, origin_device_id: ORIGIN },
    store,
    sender,
    NOW,
  );
  assertEquals(sent.map((m) => [m.token, m.data]), [["ta", { type: "sync", head: "77" }], ["tb", {
    type: "sync",
    head: "77",
  }]]);
  assertEquals(marked, [["a", "b"]]);
  assertEquals(cleared, [["b"]]);
  assertEquals(summary, { targets: 2, sent: 1, failed: 1, invalidTokens: 1, skipped: { origin: 1 } });
});

Deno.test("parseNudgeEvent validates the webhook body", () => {
  assertEquals(parseNudgeEvent({ user_id: USER, head_rev: 5, origin_device_id: ORIGIN }), {
    user_id: USER,
    head_rev: 5,
    origin_device_id: ORIGIN,
  });
  assertEquals(
    parseNudgeEvent({ user_id: USER, head_rev: "9", origin_device_id: "nope" }).origin_device_id,
    null,
  );
});

Deno.test("sync-nudge handler: auth, validation and graceful degradation", async () => {
  const { store } = fakeStore([]);
  const handler = (sender: PushSender | null) =>
    createHandler({
      isAuthorized: (req) => req.headers.get("x-cron-secret") === "s",
      createStore: () => store,
      createSender: () => sender,
      now: () => NOW,
    });
  const req = (body: unknown, secret = "s") =>
    new Request("http://localhost/sync-nudge", {
      method: "POST",
      headers: { "x-cron-secret": secret, "content-type": "application/json" },
      body: JSON.stringify(body),
    });

  assertEquals((await handler(null)(req({ user_id: USER }, "wrong"))).status, 401);
  assertEquals((await handler(null)(req({ user_id: "x" }))).status, 400);
  const skipped = await handler(null)(req({ user_id: USER, head_rev: 1 }));
  assertEquals(skipped.status, 200);
  assertEquals(await skipped.json(), { skipped: "push_not_configured" });
  const sender: PushSender = { send: () => Promise.resolve({ ok: true, kind: "ok", messageId: "m" }) };
  const done = await handler(sender)(req({ user_id: USER, head_rev: 1 }));
  assertEquals((await done.json()).targets, 0);
});
