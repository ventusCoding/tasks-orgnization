// Pure dispatcher decisions (arch §6.13 step 4, T7.4.07, T7.4.13). No I/O — unit tested.

import type {
  ClaimedJob,
  DeliveryOutcome,
  DevicePolicy,
  DispatchDevice,
  Importance,
} from "../_shared/types.ts";

export const COVERAGE_SEEN_WINDOW_MS = 72 * 3600 * 1000; // Android force-stop silently clears alarms
export const STALE_TOKEN_MS = 30 * 24 * 3600 * 1000; // FCM: tokens go stale after ~1 month idle
export const DEFAULT_LATENESS_MINUTES = 15;
export const MAX_ATTEMPTS = 5;
export const BACKOFF_SECONDS = [60, 120, 240, 480]; // 1, 2, 4, 8 min (+ jitter)

const IMPORTANCE_RANK: Record<Importance, number> = { min: 0, low: 1, default: 2, high: 3, urgent: 4 };

export type DeviceDecision =
  | { deviceId: string; action: "send" }
  | {
    deviceId: string;
    action: "skip";
    outcome: Exclude<DeliveryOutcome, "sent" | "failed" | "token_invalid">;
    reason: string;
  }
  | { deviceId: string; action: "none"; reason: "already_sent" };

export type JobClassification = { kind: "expired" } | { kind: "deliver"; late: boolean };

const ms = (iso: string | null | undefined): number | null => {
  if (!iso) return null;
  const t = Date.parse(iso);
  return Number.isNaN(t) ? null : t;
};

/** Expired jobs are never delivered; late ones are delivered and flagged. */
export function classifyJob(job: ClaimedJob, now: Date, policy: DevicePolicy = {}): JobClassification {
  const expires = ms(job.expires_at);
  if (expires !== null && now.getTime() > expires) return { kind: "expired" };
  const fire = ms(job.fire_at) ?? now.getTime();
  const lateness = numberOr(
    job.payload?.latenessMinutes,
    numberOr(policy.latenessMinutes, DEFAULT_LATENESS_MINUTES),
  );
  return { kind: "deliver", late: now.getTime() - fire > lateness * 60_000 };
}

function numberOr(value: unknown, fallback: number): number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 ? value : fallback;
}

/**
 * True when the device will show this job from its own local schedule:
 * fire_at ≤ local_coverage_until (or the rule is covered by a repeating local trigger), the schedule was
 * planned from a revision ≥ the job's, the app was foregrounded within 72 h, and — for high/urgent jobs —
 * the device can fire exact alarms (iOS local notifications are always exact).
 */
export function coversLocally(device: DispatchDevice, job: ClaimedJob, now: Date): boolean {
  if (!device.local_notifications_enabled) return false;
  if (device.schedule_rev === null || device.schedule_rev === undefined) return false;
  if (Number(device.schedule_rev) < Number(job.source_rev)) return false;
  const seen = ms(device.last_seen_at);
  if (seen === null || now.getTime() - seen > COVERAGE_SEEN_WINDOW_MS) return false;
  const fire = ms(job.fire_at);
  const coverage = ms(device.local_coverage_until);
  const inWindow = fire !== null && coverage !== null && fire <= coverage;
  const byRepeatingRule = job.rule_id !== null && (device.local_repeating_rules ?? []).includes(job.rule_id);
  if (!inWindow && !byRepeatingRule) return false;
  const important = IMPORTANCE_RANK[job.importance ?? "default"] >= IMPORTANCE_RANK.high;
  const exact = device.platform === "ios" || device.capabilities?.exactAlarm === true;
  return !important || exact;
}

export function isTokenStale(device: DispatchDevice, now: Date): boolean {
  const updated = ms(device.push_token_updated_at);
  const seen = ms(device.last_seen_at);
  const old = (t: number | null) => t === null || now.getTime() - t > STALE_TOKEN_MS;
  return old(updated) && old(seen);
}

/** Devices the multi-device policy allows; null = all devices. */
export function policyDeviceIds(devices: DispatchDevice[], policy: DevicePolicy): Set<string> | null {
  const mode = policy.multiDevicePolicy ?? "all";
  if (mode === "primary" && policy.primaryDeviceId && devices.some((d) => d.id === policy.primaryDeviceId)) {
    return new Set([policy.primaryDeviceId]);
  }
  if (mode === "last_active") {
    let best: DispatchDevice | null = null;
    for (const d of devices) {
      if ((ms(d.last_seen_at) ?? -1) > (ms(best?.last_seen_at) ?? -1)) best = d;
    }
    if (best) return new Set([best.id]);
  }
  return null;
}

/** Per-device decision for one deliverable job. Revoked devices are ignored entirely. */
export function decideDevices(
  job: ClaimedJob,
  devices: DispatchDevice[],
  policy: DevicePolicy,
  now: Date,
): DeviceDecision[] {
  const live = devices.filter((d) => !d.revoked_at);
  const allowed = policyDeviceIds(live, policy);
  const alreadySent = new Set(job.sent_device_ids ?? []);
  const decisions: DeviceDecision[] = [];

  for (const d of live) {
    if (alreadySent.has(d.id)) {
      decisions.push({ deviceId: d.id, action: "none", reason: "already_sent" });
    } else if (job.target_devices && job.target_devices.length > 0 && !job.target_devices.includes(d.id)) {
      decisions.push({ deviceId: d.id, action: "skip", outcome: "skipped_policy", reason: "target_devices" });
    } else if (allowed && !allowed.has(d.id)) {
      decisions.push({
        deviceId: d.id,
        action: "skip",
        outcome: "skipped_policy",
        reason: policy.multiDevicePolicy === "last_active" ? "last_active_only" : "primary_only",
      });
    } else if (coversLocally(d, job, now)) {
      decisions.push({ deviceId: d.id, action: "skip", outcome: "skipped_local", reason: "covered_locally" });
    } else if (!d.push_enabled) {
      decisions.push({ deviceId: d.id, action: "skip", outcome: "skipped_policy", reason: "push_disabled" });
    } else if (!d.push_token) {
      decisions.push({ deviceId: d.id, action: "skip", outcome: "skipped_stale_token", reason: "no_token" });
    } else if (isTokenStale(d, now)) {
      decisions.push({
        deviceId: d.id,
        action: "skip",
        outcome: "skipped_stale_token",
        reason: "stale_token",
      });
    } else {
      decisions.push({ deviceId: d.id, action: "send" });
    }
  }
  return decisions;
}

/** Exponential backoff with ±20 % jitter; `attempts` = attempts already made. */
export function backoffSeconds(attempts: number, random: () => number = Math.random): number {
  const base = BACKOFF_SECONDS[Math.min(Math.max(attempts, 0), BACKOFF_SECONDS.length - 1)];
  const jitter = 1 + (random() * 0.4 - 0.2);
  return Math.max(1, Math.round(base * jitter));
}

/** Remaining lifetime of a push: until expires_at, else one hour. */
export function ttlSeconds(job: ClaimedJob, now: Date): number {
  const expires = ms(job.expires_at);
  if (expires === null) return 3600;
  return Math.max(0, Math.floor((expires - now.getTime()) / 1000));
}
