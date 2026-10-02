// FallbackStore backed by the service-role `app.fallback_*` RPCs.

import { type AdminClient, callRpc } from "../_shared/supabase.ts";
import type { FallbackInput, FallbackJob } from "./planner.ts";
import type { FallbackStore } from "./run.ts";

export function createSupabaseFallbackStore(client: AdminClient): FallbackStore {
  return {
    candidates: async (limit) =>
      (await callRpc<Array<{ user_id: string }>>(client, "fallback_candidates", { p_limit: limit })).map((
        r,
      ) => r.user_id),
    load: (userId) => callRpc<FallbackInput>(client, "fallback_load", { p_user: userId }),
    replace: (userId, sourceRev, jobs: FallbackJob[]) =>
      callRpc<{ replaced: number; inserted: number }>(client, "fallback_replace_jobs", {
        p_user: userId,
        p_source_rev: sourceRev,
        p_jobs: jobs,
      }),
    heartbeat: async (name, details) => {
      await callRpc<unknown>(client, "ops_heartbeat", { p_name: name, p_details: details });
    },
  };
}
