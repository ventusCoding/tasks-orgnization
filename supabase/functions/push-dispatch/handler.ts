// HTTP entry of push-dispatch: invoked by pg_cron (via pg_net) every 30 s with `x-cron-secret`.
// Answers 202 immediately; the work runs in EdgeRuntime.waitUntil (pg_net times out after seconds).

import { hasValidCronSecret } from "../_shared/auth.ts";
import { runInBackground } from "../_shared/background.ts";
import { handleCors } from "../_shared/cors.ts";
import { assertMethod, errorResponse, json, notConfigured, unauthorized } from "../_shared/errors.ts";
import { createFcmSenderFromEnv, type PushSender } from "../_shared/fcm.ts";
import { log } from "../_shared/log.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import { type DispatchStore, runDispatch } from "./dispatcher.ts";
import { createSupabaseDispatchStore } from "./store.ts";

export interface PushDispatchDeps {
  isAuthorized: (req: Request) => boolean;
  createStore: () => DispatchStore | null;
  createSender: () => PushSender | null;
  background: typeof runInBackground;
}

export const defaultDeps: PushDispatchDeps = {
  isAuthorized: (req) => hasValidCronSecret(req),
  createStore: () => {
    const client = createAdminClient();
    return client ? createSupabaseDispatchStore(client) : null;
  },
  createSender: () => createFcmSenderFromEnv(),
  background: runInBackground,
};

export function createHandler(deps: PushDispatchDeps = defaultDeps) {
  return async (req: Request): Promise<Response> => {
    try {
      const cors = handleCors(req);
      if (cors) return cors;
      assertMethod(req, ["POST"]);
      if (!deps.isAuthorized(req)) throw unauthorized("Invalid cron secret");
      await req.body?.cancel();

      const store = deps.createStore();
      if (!store) throw notConfigured("SUPABASE_URL / SUPABASE_SECRET_KEY");
      const sender = deps.createSender();
      if (!sender) log("warn", "push_dispatch.push_not_configured", {});

      const mode = deps.background(
        () => runDispatch({ store, sender, log }),
        (err) =>
          log("error", "push_dispatch.failed", { error: err instanceof Error ? err.message : String(err) }),
      );
      return json({ accepted: true, push_configured: sender !== null, mode }, 202);
    } catch (err) {
      return errorResponse(err, "push_dispatch");
    }
  };
}
