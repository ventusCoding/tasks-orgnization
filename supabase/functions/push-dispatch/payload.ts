// Job → FCM message (T7.4.09). Same dedupe key everywhere: android.notification.tag, apns-collapse-id
// and the inbox id (uuid_v5(dedupe_key)), so a push replaces rather than duplicates.

import { buildAlertMessage, type FcmMessage } from "../_shared/fcm.ts";
import type { ClaimedJob, DispatchDevice } from "../_shared/types.ts";
import { ttlSeconds } from "./decisions.ts";

const INTERRUPTION_BY_IMPORTANCE: Record<string, string> = {
  min: "passive",
  low: "passive",
  default: "active",
  high: "time-sensitive",
  urgent: "time-sensitive",
};

export function buildJobMessage(job: ClaimedJob, device: DispatchDevice, now: Date): FcmMessage {
  const p = job.payload ?? {};
  const type = typeof p.type === "string" ? p.type : typeof p.category === "string" ? p.category : "reminder";
  const expires = job.expires_at ? Math.floor(Date.parse(job.expires_at) / 1000) : undefined;
  return buildAlertMessage({
    token: device.push_token ?? "",
    dedupeKey: job.dedupe_key,
    title: typeof p.title === "string" ? p.title : "Everslot",
    body: typeof p.body === "string" ? p.body : undefined,
    data: {
      type,
      target: job.target_key,
      occ: job.occurrence_key ?? undefined,
      deepLink: p.deepLink,
      actions: Array.isArray(p.actions) ? p.actions.join(",") : undefined,
      channel: p.channel,
      group: p.group,
      fireAt: job.fire_at,
    },
    channelId: typeof p.channel === "string" ? p.channel : undefined,
    // iOS notification category registered by the app (carries the action buttons).
    category: typeof p.iosCategory === "string" ? p.iosCategory : undefined,
    threadId: typeof p.group === "string" ? p.group : undefined,
    sound: typeof p.sound === "string" ? p.sound : undefined,
    importance: job.importance,
    interruptionLevel: typeof p.interruptionLevel === "string"
      ? p.interruptionLevel
      : INTERRUPTION_BY_IMPORTANCE[job.importance ?? "default"],
    relevanceScore: typeof p.relevance === "number" ? p.relevance : undefined,
    ttlSeconds: ttlSeconds(job, now),
    expiresAtEpochSeconds: expires !== undefined && Number.isFinite(expires) ? expires : undefined,
  });
}

/** Same-minute jobs for one device at or above this size are merged into one push (T7.4.07 step 7). */
export const BURST_MIN_JOBS = 3;

/**
 * One merged push for a burst of same-minute jobs on one device: the first title, the other titles as
 * big text, `type: digest` opening the inbox (each job keeps its own inbox row). Keeps devices far from
 * FCM's per-device limits and the user from a wall of alerts.
 */
export function buildBurstMessage(jobs: ClaimedJob[], device: DispatchDevice, now: Date): FcmMessage {
  const title = (j: ClaimedJob) => typeof j.payload?.title === "string" ? j.payload.title : "Everslot";
  const first = jobs[0];
  const minute = first.fire_at.slice(0, 16);
  const importance = jobs.some((j) => j.importance === "urgent")
    ? "urgent"
    : jobs.some((j) => j.importance === "high")
    ? "high"
    : first.importance;
  return buildAlertMessage({
    token: device.push_token ?? "",
    dedupeKey: `burst|${device.id}|${minute}`,
    title: title(first),
    body: jobs.slice(1).map(title).join("\n"),
    data: {
      type: "digest",
      count: jobs.length,
      dks: jobs.map((j) => j.dedupe_key).join(","),
      deepLink: "/inbox",
      fireAt: first.fire_at,
    },
    channelId: typeof first.payload?.channel === "string" ? first.payload.channel : undefined,
    threadId: "burst",
    importance,
    interruptionLevel: INTERRUPTION_BY_IMPORTANCE[importance ?? "default"],
    ttlSeconds: Math.min(...jobs.map((j) => ttlSeconds(j, now))),
  });
}
