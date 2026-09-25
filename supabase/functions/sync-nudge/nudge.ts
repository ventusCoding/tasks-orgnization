// Silent "please sync" pushes to a user's OTHER devices (arch §6.13 step 7, T7.4.11).

import { mapWithConcurrency } from "../_shared/background.ts";
import { buildSyncMessage, type PushSender } from "../_shared/fcm.ts";

export const FOREGROUND_WINDOW_MS = 2 * 60 * 1000; // Realtime Broadcast already covers foreground devices
export const THROTTLE_MS: Record<string, number> = {
  android: 60 * 1000, // ≥ 60 s between nudges per device
  ios: 20 * 60 * 1000, // Apple: 2–3 background pushes per hour
};
export const DEFAULT_THROTTLE_MS = 60 * 1000;

export interface NudgeDevice {
  id: string;
  platform: string;
  push_token: string | null;
  push_enabled: boolean;
  revoked_at: string | null;
  last_seen_at: string | null;
  last_nudged_at: string | null;
}

export interface NudgeEvent {
  user_id: string;
  head_rev: number;
  origin_device_id: string | null;
}

export type NudgeSkipReason =
  | "revoked"
  | "push_disabled"
  | "no_token"
  | "origin"
  | "foreground"
  | "throttled";

export function selectNudgeTargets(
  devices: NudgeDevice[],
  originDeviceId: string | null,
  now: Date,
): { targets: NudgeDevice[]; skipped: Array<{ id: string; reason: NudgeSkipReason }> } {
  const targets: NudgeDevice[] = [];
  const skipped: Array<{ id: string; reason: NudgeSkipReason }> = [];
  const t = now.getTime();
  for (const d of devices) {
    const seen = d.last_seen_at ? Date.parse(d.last_seen_at) : NaN;
    const nudged = d.last_nudged_at ? Date.parse(d.last_nudged_at) : NaN;
    const throttle = THROTTLE_MS[d.platform] ?? DEFAULT_THROTTLE_MS;
    let reason: NudgeSkipReason | null = null;
    if (d.revoked_at) reason = "revoked";
    else if (!d.push_enabled) reason = "push_disabled";
    else if (!d.push_token) reason = "no_token";
    else if (originDeviceId && d.id === originDeviceId) reason = "origin";
    else if (!Number.isNaN(seen) && t - seen < FOREGROUND_WINDOW_MS) reason = "foreground";
    else if (!Number.isNaN(nudged) && t - nudged < throttle) reason = "throttled";
    if (reason) skipped.push({ id: d.id, reason });
    else targets.push(d);
  }
  return { targets, skipped };
}

export interface NudgeStore {
  devices(userId: string): Promise<NudgeDevice[]>;
  markNudged(deviceIds: string[], at: Date): Promise<void>;
  clearTokens(deviceIds: string[]): Promise<void>;
}

export interface NudgeSummary {
  targets: number;
  sent: number;
  failed: number;
  invalidTokens: number;
  skipped: Record<string, number>;
}

export async function runNudge(
  event: NudgeEvent,
  store: NudgeStore,
  sender: PushSender,
  now: Date = new Date(),
): Promise<NudgeSummary> {
  const devices = await store.devices(event.user_id);
  const { targets, skipped } = selectNudgeTargets(devices, event.origin_device_id, now);
  const summary: NudgeSummary = {
    targets: targets.length,
    sent: 0,
    failed: 0,
    invalidTokens: 0,
    skipped: {},
  };
  for (const s of skipped) summary.skipped[s.reason] = (summary.skipped[s.reason] ?? 0) + 1;
  if (targets.length === 0) return summary;

  // Mark before sending: concurrent webhook calls for the same user then see the throttle.
  await store.markNudged(targets.map((d) => d.id), now);
  const results = await mapWithConcurrency(
    targets,
    20,
    (d) => sender.send(buildSyncMessage(d.push_token!, event.head_rev)),
  );
  const invalid: string[] = [];
  results.forEach((r, i) => {
    if (r.ok) summary.sent++;
    else {
      summary.failed++;
      if (r.tokenInvalid) invalid.push(targets[i].id);
    }
  });
  if (invalid.length > 0) {
    summary.invalidTokens = invalid.length;
    await store.clearTokens(invalid);
  }
  return summary;
}
