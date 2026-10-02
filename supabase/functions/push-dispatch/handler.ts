// HTTP entry of push-dispatch: invoked by pg_cron (via pg_net) every 30 s with `x-cron-secret`.
// Answers 202 immediately; the work runs in EdgeRuntime.waitUntil (pg_net times out after seconds).

import { hasValidCronSecret } from "../_shared/auth.ts";
import { runInBackground } from "../_shared/background.ts";
import { handleCors } from "../_shared/cors.ts";
import { assertMethod, errorResponse, json, notConfigured, unauthorized } from "../_shared/errors.ts";
import { createEmailSenderFromEnv } from "../_shared/email.ts";
import { readEnv } from "../_shared/env.ts";
import { createFcmSenderFromEnv, type PushSender } from "../_shared/fcm.ts";
import { createSupabaseTokenStore } from "../_shared/fcm_token_store.ts";
import { log } from "../_shared/log.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import { type DispatchStore, type EmailOptions, runDispatch } from "./dispatcher.ts";
import { createSupabaseDispatchStore } from "./store.ts";

export interface PushDispatchDeps {
  isAuthorized: (req: Request) => boolean;
  createStore: () => DispatchStore | null;
  createSender: () => PushSender | null;
  background: typeof runInBackground;
  /** Digest emails (T7.4.18): null when EMAIL_* secrets are not set. */
  createEmail?: () => EmailOptions | null;
}

/** EMAIL_API_KEY + EMAIL_FROM + EMAIL_LINK_SECRET + the public project URL, else null. */
export function emailOptionsFromEnv(): EmailOptions | null {
  const sender = createEmailSenderFromEnv();
  const linkSecret = readEnv("EMAIL_LINK_SECRET");
  const baseUrl = readEnv("PUBLIC_SUPABASE_URL") ?? readEnv("SUPABASE_URL");
  return sender && linkSecret && baseUrl ? { sender, linkSecret, baseUrl } : null;
}

export const defaultDeps: PushDispatchDeps = {
  isAuthorized: (req) => hasValidCronSecret(req),
  createStore: () => {
    const client = createAdminClient();
    return client ? createSupabaseDispatchStore(client) : null;
  },
  createSender: () => {
    const client = createAdminClient();
    return createFcmSenderFromEnv(client ? createSupabaseTokenStore(client) : null);
  },
  background: runInBackground,
  createEmail: emailOptionsFromEnv,
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
        () => runDispatch({ store, sender, log, email: deps.createEmail?.() ?? null }),
        (err) =>
          log("error", "push_dispatch.failed", { error: err instanceof Error ? err.message : String(err) }),
      );
      return json({ accepted: true, push_configured: sender !== null, mode }, 202);
    } catch (err) {
      return errorResponse(err, "push_dispatch");
    }
  };
}
