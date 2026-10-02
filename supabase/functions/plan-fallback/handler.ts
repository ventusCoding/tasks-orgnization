// HTTP entry of plan-fallback: invoked daily by pg_cron (via pg_net) with `x-cron-secret`. Answers 202
// at once; the planning runs in EdgeRuntime.waitUntil.

import { hasValidCronSecret } from "../_shared/auth.ts";
import { runInBackground } from "../_shared/background.ts";
import { handleCors } from "../_shared/cors.ts";
import { assertMethod, errorResponse, json, notConfigured, unauthorized } from "../_shared/errors.ts";
import { log } from "../_shared/log.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import { type FallbackStore, runFallback } from "./run.ts";
import { createSupabaseFallbackStore } from "./store.ts";

export interface PlanFallbackDeps {
  isAuthorized: (req: Request) => boolean;
  createStore: () => FallbackStore | null;
  background: typeof runInBackground;
}

export const defaultDeps: PlanFallbackDeps = {
  isAuthorized: (req) => hasValidCronSecret(req),
  createStore: () => {
    const client = createAdminClient();
    return client ? createSupabaseFallbackStore(client) : null;
  },
  background: runInBackground,
};

export function createHandler(deps: PlanFallbackDeps = defaultDeps) {
  return async (req: Request): Promise<Response> => {
    try {
      const cors = handleCors(req);
      if (cors) return cors;
      assertMethod(req, ["POST"]);
      if (!deps.isAuthorized(req)) throw unauthorized("Invalid cron secret");
      await req.body?.cancel();
      const store = deps.createStore();
      if (!store) throw notConfigured("SUPABASE_URL / SUPABASE_SECRET_KEY");
      const mode = deps.background(
        () => runFallback(store, { log }),
        (err) =>
          log("error", "plan_fallback.failed", { error: err instanceof Error ? err.message : String(err) }),
      );
      return json({ accepted: true, mode }, 202);
    } catch (err) {
      return errorResponse(err, "plan_fallback");
    }
  };
}
