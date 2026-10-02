// email-unsubscribe (T7.4.18): one-click unsubscribe from digest emails. GET shows a confirmation page,
// POST (RFC 8058 List-Unsubscribe-Post) answers 200; both verify the signed link and turn
// `notifications.emailDigests.enabled` off.

import { emailStrings, verifyUnsubscribeToken } from "../_shared/email.ts";
import { readEnv } from "../_shared/env.ts";
import { log } from "../_shared/log.ts";
import { type AdminClient, callRpc, createAdminClient } from "../_shared/supabase.ts";

export interface UnsubscribeDeps {
  secret: () => string | undefined;
  unsubscribe: (userId: string) => Promise<boolean>;
}

export const defaultDeps: UnsubscribeDeps = {
  secret: () => readEnv("EMAIL_LINK_SECRET"),
  unsubscribe: (userId) => {
    const client: AdminClient | null = createAdminClient();
    if (!client) throw new Error("not configured");
    return callRpc<boolean>(client, "email_unsubscribe", { p_user: userId });
  },
};

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function page(locale: string, text: string, status: number): Response {
  const lang = locale.slice(0, 2);
  const dir = lang === "ar" ? "rtl" : "ltr";
  const html = `<!doctype html><html lang="${lang}" dir="${dir}"><head><meta charset="utf-8">` +
    `<meta name="viewport" content="width=device-width,initial-scale=1"><title>Everslot</title></head>` +
    `<body style="font-family:system-ui,sans-serif;max-width:480px;margin:48px auto;padding:0 16px">` +
    `<p>${text}</p></body></html>`;
  return new Response(html, { status, headers: { "Content-Type": "text/html; charset=utf-8" } });
}

export function createHandler(deps: UnsubscribeDeps = defaultDeps) {
  return async (req: Request): Promise<Response> => {
    const url = new URL(req.url);
    const locale = (req.headers.get("accept-language") ?? "en").split(",")[0].trim() || "en";
    const s = emailStrings(locale);
    if (req.method !== "GET" && req.method !== "POST") return new Response(null, { status: 405 });
    await req.body?.cancel();
    const userId = url.searchParams.get("u") ?? "";
    const token = url.searchParams.get("t") ?? "";
    const secret = deps.secret();
    if (!secret || !UUID.test(userId) || !(await verifyUnsubscribeToken(secret, userId, token))) {
      return page(locale, s.invalid, 400);
    }
    try {
      await deps.unsubscribe(userId);
    } catch (err) {
      log("error", "email_unsubscribe.failed", { error: err instanceof Error ? err.message : String(err) });
      return page(locale, s.invalid, 500);
    }
    log("info", "email_unsubscribe.done", {});
    return req.method === "POST" ? new Response(null, { status: 200 }) : page(locale, s.unsubscribed, 200);
  };
}
