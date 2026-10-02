// DispatchStore backed by the service-role-only `app.dispatch_*` RPCs (the `private` schema is not
// exposed through the API).

import { type AdminClient, callRpc } from "../_shared/supabase.ts";
import type { ClaimedJob, GuardResult, JobResult, UserDevices } from "../_shared/types.ts";
import type { DispatchStore, EmailTarget } from "./dispatcher.ts";

export function createSupabaseDispatchStore(client: AdminClient): DispatchStore {
  return {
    claim: (limit, leaseSeconds) =>
      callRpc<ClaimedJob[]>(client, "dispatch_claim", { p_limit: limit, p_lease_seconds: leaseSeconds }),
    guards: (jobs) => callRpc<GuardResult[]>(client, "dispatch_guards", { p_jobs: jobs }),
    upsertInbox: async (items) => {
      await callRpc<unknown>(client, "dispatch_upsert_inbox", { p_items: items });
    },
    devices: (userIds) =>
      callRpc<Record<string, UserDevices>>(client, "dispatch_devices", { p_user_ids: userIds }),
    complete: async (results: JobResult[]) => {
      await callRpc<unknown>(client, "dispatch_complete", { p_results: results });
    },
    emailTargets: (userIds) =>
      callRpc<Record<string, EmailTarget>>(client, "dispatch_email_targets", { p_user_ids: userIds }),
    heartbeat: async (name, details) => {
      await callRpc<unknown>(client, "ops_heartbeat", { p_name: name, p_details: details });
    },
  };
}
