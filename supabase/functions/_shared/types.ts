// Shared types of the notification pipeline (mirror of private.notification_jobs / app.devices rows as
// returned by the app.dispatch_* RPCs — see supabase/README.md).

export type Importance = "min" | "low" | "default" | "high" | "urgent";

export type JobStatus = "pending" | "claimed" | "sent" | "skipped" | "failed" | "cancelled" | "expired";

export type DeliveryOutcome =
  | "sent"
  | "skipped_local"
  | "skipped_policy"
  | "skipped_stale_token"
  | "expired"
  | "failed"
  | "token_invalid";

/** Rendered content uploaded by the device planner (already localized / redacted). */
export interface JobPayload {
  /** reminder | nag | digest | milestone | streak | system (inbox category + push `type`). */
  type?: string;
  category?: string;
  title?: string;
  body?: string;
  section?: string;
  sourceType?: string;
  sourceId?: string;
  deepLink?: string;
  actions?: string[];
  channel?: string;
  group?: string;
  sound?: string;
  interruptionLevel?: string;
  relevance?: number;
  /** delivery.system — false = inbox only (no push). */
  system?: boolean;
  /** delivery.inbox — false = no inbox row. */
  inbox?: boolean;
  /** Minutes after fire_at from which a delivery is flagged `late`. */
  latenessMinutes?: number;
  /** Write a `late` inbox row when the job expired undelivered. */
  inboxWhenExpired?: boolean;
  data?: Record<string, unknown>;
  [key: string]: unknown;
}

export interface ClaimedJob {
  id: string;
  user_id: string;
  dedupe_key: string;
  target_key: string;
  fire_at: string;
  expires_at: string | null;
  payload: JobPayload;
  guard: unknown;
  source_rev: number;
  rule_id: string | null;
  occurrence_key: string | null;
  target_devices: string[] | null;
  planned_by_device: string | null;
  importance: Importance | null;
  status: JobStatus;
  attempts: number;
  sent_device_ids?: string[];
}

export interface DispatchDevice {
  id: string;
  platform: string;
  push_token: string | null;
  push_token_updated_at: string | null;
  push_enabled: boolean;
  local_notifications_enabled: boolean;
  local_coverage_until: string | null;
  schedule_rev: number | null;
  capabilities: Record<string, unknown> | null;
  local_repeating_rules: string[] | null;
  last_seen_at: string | null;
  revoked_at: string | null;
}

export interface DevicePolicy {
  multiDevicePolicy?: "all" | "primary" | "last_active" | string;
  primaryDeviceId?: string;
  latenessMinutes?: number;
}

export interface UserDevices {
  policy: DevicePolicy;
  devices: DispatchDevice[];
}

export interface GuardResult {
  job_id: string;
  ok: boolean;
  reason: string | null;
}

export interface DeliveryRecord {
  device_id: string;
  outcome: DeliveryOutcome;
  fcm_message_id?: string | null;
  error_code?: string | null;
}

export interface JobResult {
  job_id: string;
  status: "sent" | "skipped" | "expired" | "failed" | "retry";
  reason?: string | null;
  retry_after_seconds?: number;
  pushed?: boolean;
  deliveries: DeliveryRecord[];
  invalid_device_ids: string[];
}
