import { assert, assertEquals, makeDevice, makeJob, NOW } from "../_shared/test_utils.ts";
import { backoffSeconds, classifyJob, coversLocally, decideDevices, ttlSeconds } from "./decisions.ts";

const covering = {
  local_coverage_until: "2026-09-23T00:00:00Z",
  schedule_rev: 100,
  last_seen_at: "2026-09-21T12:00:00Z",
};

const decide = (job = makeJob(), devices = [makeDevice()], policy = {}) =>
  decideDevices(job, devices, policy, NOW).map((
    d,
  ) => ("outcome" in d ? `${d.action}:${d.outcome}:${d.reason}` : d.action));

Deno.test("covered device is skipped (skipped_local)", () => {
  assertEquals(decide(makeJob(), [makeDevice(covering)]), ["skip:skipped_local:covered_locally"]);
});

Deno.test("stale device (last seen > 72 h ago) gets a push", () => {
  assertEquals(decide(makeJob(), [makeDevice({ ...covering, last_seen_at: "2026-09-19T09:00:00Z" })]), [
    "send",
  ]);
});

Deno.test("device with an older schedule_rev gets a push", () => {
  assertEquals(decide(makeJob(), [makeDevice({ ...covering, schedule_rev: 99 })]), ["send"]);
});

Deno.test("fire_at beyond local coverage gets a push, unless a repeating local rule covers it", () => {
  const beyond = { ...covering, local_coverage_until: "2026-09-22T09:59:00Z" };
  assertEquals(decide(makeJob(), [makeDevice(beyond)]), ["send"]);
  const repeating = { ...beyond, local_repeating_rules: ["00000000-0000-4000-8000-0000000000e1"] };
  assertEquals(decide(makeJob(), [makeDevice(repeating)]), ["skip:skipped_local:covered_locally"]);
});

Deno.test("high-importance jobs are pushed to Android devices without exact alarms", () => {
  const job = makeJob({ importance: "high" });
  assertEquals(decide(job, [makeDevice({ ...covering, capabilities: { exactAlarm: false } })]), ["send"]);
  assertEquals(decide(job, [makeDevice({ ...covering, capabilities: { exactAlarm: true } })]), [
    "skip:skipped_local:covered_locally",
  ]);
  assertEquals(decide(job, [makeDevice({ ...covering, platform: "ios", capabilities: {} })]), [
    "skip:skipped_local:covered_locally",
  ]);
});

Deno.test("devices with local notifications off are never considered covering", () => {
  assertEquals(decide(makeJob(), [makeDevice({ ...covering, local_notifications_enabled: false })]), [
    "send",
  ]);
});

Deno.test("push disabled / missing token / stale token are skipped", () => {
  assertEquals(decide(makeJob(), [makeDevice({ push_enabled: false })]), [
    "skip:skipped_policy:push_disabled",
  ]);
  assertEquals(decide(makeJob(), [makeDevice({ push_token: null })]), ["skip:skipped_stale_token:no_token"]);
  assertEquals(
    decide(makeJob(), [
      makeDevice({ push_token_updated_at: "2026-07-01T00:00:00Z", last_seen_at: "2026-07-15T00:00:00Z" }),
    ]),
    ["skip:skipped_stale_token:stale_token"],
  );
  // An old token on a device seen recently is still used.
  assertEquals(
    decide(makeJob(), [
      makeDevice({ push_token_updated_at: "2026-07-01T00:00:00Z", last_seen_at: "2026-09-10T00:00:00Z" }),
    ]),
    ["send"],
  );
});

Deno.test("rule device targeting (conditions.devices)", () => {
  const a = makeDevice({ id: "a" });
  const b = makeDevice({ id: "b" });
  assertEquals(decide(makeJob({ target_devices: ["b"] }), [a, b]), [
    "skip:skipped_policy:target_devices",
    "send",
  ]);
});

Deno.test("multi-device policy: primary only / last active", () => {
  const phone = makeDevice({ id: "phone", last_seen_at: "2026-09-22T09:30:00Z" });
  const tablet = makeDevice({ id: "tablet", last_seen_at: "2026-09-22T08:00:00Z" });
  assertEquals(
    decide(makeJob(), [phone, tablet], { multiDevicePolicy: "primary", primaryDeviceId: "tablet" }),
    [
      "skip:skipped_policy:primary_only",
      "send",
    ],
  );
  assertEquals(decide(makeJob(), [phone, tablet], { multiDevicePolicy: "last_active" }), [
    "send",
    "skip:skipped_policy:last_active_only",
  ]);
  // Unknown primary → falls back to all devices.
  assertEquals(
    decide(makeJob(), [phone, tablet], { multiDevicePolicy: "primary", primaryDeviceId: "gone" }),
    [
      "send",
      "send",
    ],
  );
});

Deno.test("revoked devices are ignored and already-pushed devices are not pushed twice", () => {
  const revoked = makeDevice({ id: "old", revoked_at: "2026-09-01T00:00:00Z" });
  const done = makeDevice({ id: "done" });
  assertEquals(decide(makeJob({ sent_device_ids: ["done"] }), [revoked, done]), ["none"]);
});

Deno.test("coversLocally requires a schedule revision", () => {
  assert(!coversLocally(makeDevice({ ...covering, schedule_rev: null }), makeJob(), NOW));
});

Deno.test("classifyJob: expired and late", () => {
  assertEquals(classifyJob(makeJob({ expires_at: "2026-09-22T09:59:59Z" }), NOW), { kind: "expired" });
  assertEquals(classifyJob(makeJob({ fire_at: "2026-09-22T09:50:00Z" }), NOW), {
    kind: "deliver",
    late: false,
  });
  assertEquals(classifyJob(makeJob({ fire_at: "2026-09-22T09:30:00Z" }), NOW), {
    kind: "deliver",
    late: true,
  });
  assertEquals(classifyJob(makeJob({ fire_at: "2026-09-22T09:30:00Z" }), NOW, { latenessMinutes: 60 }), {
    kind: "deliver",
    late: false,
  });
  assertEquals(classifyJob(makeJob({ expires_at: null, fire_at: "2026-09-22T09:59:00Z" }), NOW), {
    kind: "deliver",
    late: false,
  });
});

Deno.test("backoff doubles per attempt with ±20 % jitter", () => {
  assertEquals(backoffSeconds(0, () => 0.5), 60);
  assertEquals(backoffSeconds(1, () => 0.5), 120);
  assertEquals(backoffSeconds(3, () => 0.5), 480);
  assertEquals(backoffSeconds(9, () => 0.5), 480);
  assertEquals(backoffSeconds(0, () => 0), 48);
  assertEquals(backoffSeconds(0, () => 0.999999), 72);
});

Deno.test("TTL follows expires_at", () => {
  assertEquals(ttlSeconds(makeJob(), NOW), 3600);
  assertEquals(ttlSeconds(makeJob({ expires_at: "2026-09-22T10:05:00Z" }), NOW), 300);
  assertEquals(ttlSeconds(makeJob({ expires_at: null }), NOW), 3600);
});
