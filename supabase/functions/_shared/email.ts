// Digest emails (T7.4.18): a dependency-free transactional email client (Resend-compatible HTTP API,
// base URL configurable), EN/FR/AR templates (RTL for Arabic), signed one-click unsubscribe links and the
// provider-event parser. Only digests are emailed; content arrives already localized from the device.

import { timingSafeEqual } from "./auth.ts";
import { readEnv } from "./env.ts";

export interface EmailMessage {
  to: string;
  subject: string;
  html: string;
  text: string;
  headers?: Record<string, string>;
}

export type EmailResult = { ok: true; id: string } | {
  ok: false;
  retryable: boolean;
  status?: number;
  message?: string;
};

export interface EmailSender {
  send(message: EmailMessage): Promise<EmailResult>;
}

/** Resend-compatible sender (POST {base}/emails, Bearer key). */
export class HttpEmailSender implements EmailSender {
  constructor(
    private readonly apiKey: string,
    private readonly from: string,
    private readonly baseUrl = "https://api.resend.com",
    private readonly fetchFn: typeof fetch = fetch,
  ) {}

  async send(m: EmailMessage): Promise<EmailResult> {
    try {
      const res = await this.fetchFn(`${this.baseUrl.replace(/\/+$/, "")}/emails`, {
        method: "POST",
        headers: { "Authorization": `Bearer ${this.apiKey}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          from: this.from,
          to: [m.to],
          subject: m.subject,
          html: m.html,
          text: m.text,
          headers: m.headers,
        }),
        signal: AbortSignal.timeout(10_000),
      });
      const body = await res.json().catch(() => ({})) as { id?: string; message?: string };
      if (res.ok && body.id) return { ok: true, id: body.id };
      return {
        ok: false,
        retryable: res.status === 429 || res.status >= 500,
        status: res.status,
        message: body.message,
      };
    } catch (err) {
      return { ok: false, retryable: true, message: err instanceof Error ? err.message : String(err) };
    }
  }
}

/** Email sender from EMAIL_API_KEY / EMAIL_FROM (EMAIL_API_URL override), or null when not configured. */
export function createEmailSenderFromEnv(): EmailSender | null {
  const key = readEnv("EMAIL_API_KEY");
  const from = readEnv("EMAIL_FROM");
  if (!key || !from) return null;
  return new HttpEmailSender(key, from, readEnv("EMAIL_API_URL") ?? undefined);
}

// ---------------------------------------------------------------------------------------------------
// Signed unsubscribe links
// ---------------------------------------------------------------------------------------------------

const b64url = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

async function hmac(secret: string, data: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    [
      "sign",
    ],
  );
  return b64url(
    new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`unsubscribe:${data}`))),
  );
}

export async function unsubscribeToken(secret: string, userId: string): Promise<string> {
  return await hmac(secret, userId);
}

export async function verifyUnsubscribeToken(
  secret: string,
  userId: string,
  token: string,
): Promise<boolean> {
  return timingSafeEqual(await hmac(secret, userId), token);
}

export async function unsubscribeUrl(baseUrl: string, secret: string, userId: string): Promise<string> {
  const t = await unsubscribeToken(secret, userId);
  return `${baseUrl.replace(/\/+$/, "")}/functions/v1/email-unsubscribe?u=${
    encodeURIComponent(userId)
  }&t=${t}`;
}

// ---------------------------------------------------------------------------------------------------
// Templates
// ---------------------------------------------------------------------------------------------------

const STRINGS: Record<
  string,
  { footer: string; unsubscribe: string; open: string; unsubscribed: string; invalid: string }
> = {
  en: {
    footer: "You receive this digest because you turned on digest emails in Everslot.",
    unsubscribe: "Unsubscribe",
    open: "Open Everslot",
    unsubscribed:
      "You won't receive digest emails anymore. You can turn them back on in Everslot › Settings › Notifications.",
    invalid: "This unsubscribe link is not valid.",
  },
  fr: {
    footer: "Vous recevez ce récapitulatif car vous avez activé les e-mails de récapitulatif dans Everslot.",
    unsubscribe: "Se désabonner",
    open: "Ouvrir Everslot",
    unsubscribed:
      "Vous ne recevrez plus d’e-mails de récapitulatif. Vous pouvez les réactiver dans Everslot › Réglages › Notifications.",
    invalid: "Ce lien de désabonnement n’est pas valide.",
  },
  ar: {
    footer: "تتلقى هذا الملخص لأنك فعّلت رسائل الملخص في Everslot.",
    unsubscribe: "إلغاء الاشتراك",
    open: "فتح Everslot",
    unsubscribed: "لن تتلقى رسائل الملخص بعد الآن. يمكنك إعادة تفعيلها من Everslot › الإعدادات › الإشعارات.",
    invalid: "رابط إلغاء الاشتراك غير صالح.",
  },
};

export function emailStrings(locale: string | null | undefined) {
  return STRINGS[(locale ?? "en").slice(0, 2)] ?? STRINGS.en;
}

const escapeHtml = (s: string) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(
    /'/g,
    "&#39;",
  );

/** Digest email from an already-localized title/body (multi-line body → paragraphs). */
export function renderDigestEmail(input: {
  to: string;
  locale: string | null;
  title: string;
  body: string;
  unsubscribeUrl: string;
  openUrl?: string;
}): EmailMessage {
  const s = emailStrings(input.locale);
  const lang = (input.locale ?? "en").slice(0, 2);
  const dir = lang === "ar" ? "rtl" : "ltr";
  const lines = input.body.split("\n").map((l) => l.trim()).filter((l) => l.length > 0);
  const html = `<!doctype html><html lang="${lang}" dir="${dir}"><head><meta charset="utf-8">` +
    `<meta name="viewport" content="width=device-width,initial-scale=1"><title>${
      escapeHtml(input.title)
    }</title></head>` +
    `<body style="margin:0;padding:24px;font-family:system-ui,-apple-system,'Segoe UI',Roboto,sans-serif;` +
    `background:#f6f6f9;color:#1b1b1f;text-align:${dir === "rtl" ? "right" : "left"}">` +
    `<div style="max-width:560px;margin:0 auto;background:#fff;border-radius:16px;padding:24px">` +
    `<h1 style="font-size:20px;margin:0 0 16px">${escapeHtml(input.title)}</h1>` +
    lines.map((l) => `<p style="margin:0 0 8px;line-height:1.5">${escapeHtml(l)}</p>`).join("") +
    (input.openUrl
      ? `<p style="margin:24px 0 0"><a href="${
        escapeHtml(input.openUrl)
      }" style="color:#4a56b0">${s.open}</a></p>`
      : "") +
    `</div><p style="max-width:560px;margin:16px auto 0;font-size:12px;color:#6b6b74">${s.footer} ` +
    `<a href="${
      escapeHtml(input.unsubscribeUrl)
    }" style="color:#6b6b74">${s.unsubscribe}</a></p></body></html>`;
  const text = [input.title, "", ...lines, "", `${s.footer}`, `${s.unsubscribe}: ${input.unsubscribeUrl}`]
    .join("\n");
  return {
    to: input.to,
    subject: input.title,
    html,
    text,
    headers: {
      "List-Unsubscribe": `<${input.unsubscribeUrl}>`,
      "List-Unsubscribe-Post": "List-Unsubscribe=One-Click",
    },
  };
}

// ---------------------------------------------------------------------------------------------------
// Provider events (bounces, complaints)
// ---------------------------------------------------------------------------------------------------

/** Addresses to suppress from a provider webhook body (`email.bounced` hard bounces, `email.complained`). */
export function suppressionsFromEvent(
  body: unknown,
): Array<{ email: string; reason: "bounce" | "complaint" }> {
  if (typeof body !== "object" || body === null) return [];
  const e = body as { type?: string; data?: { to?: unknown; bounce?: { type?: string } } };
  const to = Array.isArray(e.data?.to) ? e.data!.to.filter((x): x is string => typeof x === "string") : [];
  if (e.type === "email.complained") return to.map((email) => ({ email, reason: "complaint" as const }));
  if (e.type === "email.bounced") {
    const kind = (e.data?.bounce?.type ?? "hard").toLowerCase();
    if (kind.includes("soft") || kind.includes("transient")) return [];
    return to.map((email) => ({ email, reason: "bounce" as const }));
  }
  return [];
}
