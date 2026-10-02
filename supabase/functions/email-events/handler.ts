// email-events (T7.4.18): provider webhook (shared secret `x-email-webhook-secret`); hard bounces and
// complaints suppress the address so it never receives another digest.

import { timingSafeEqual } from "../_shared/auth.ts";
import { suppressionsFromEvent } from "../_shared/email.ts";
import { readEnv } from "../_shared/env.ts";
import { errorResponse, json, unauthorized } from "../_shared/errors.ts";
import { log } from "../_shared/log.ts";
import { callRpc, createAdminClient } from "../_shared/supabase.ts";

export interface EmailEventsDeps {
  secret: () => string | undefined;
  suppress: (email: string, reason: string) => Promise<void>;
}

export const defaultDeps: EmailEventsDeps = {
  secret: () => readEnv("EMAIL_WEBHOOK_SECRET"),
  suppress: async (email, reason) => {
    const client = createAdminClient();
    if (!client) throw new Error("not configured");
    await callRpc<unknown>(client, "email_suppress", { p_email: email, p_reason: reason });
  },
};

export function createHandler(deps: EmailEventsDeps = defaultDeps) {
  return async (req: Request): Promise<Response> => {
    try {
      if (req.method !== "POST") return new Response(null, { status: 405 });
      const secret = deps.secret();
      const given = req.headers.get("x-email-webhook-secret");
      if (!secret || given === null || !timingSafeEqual(given, secret)) {
        throw unauthorized("Invalid webhook secret");
      }
      const body = await req.json().catch(() => null);
      const items = suppressionsFromEvent(body);
      for (const s of items) await deps.suppress(s.email, s.reason);
      log("info", "email_events.done", { suppressed: items.length });
      return json({ suppressed: items.length });
    } catch (err) {
      return errorResponse(err, "email_events");
    }
  };
}
