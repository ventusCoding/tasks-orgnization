import {
  HttpEmailSender,
  renderDigestEmail,
  suppressionsFromEvent,
  unsubscribeToken,
  unsubscribeUrl,
  verifyUnsubscribeToken,
} from "./email.ts";
import { assert, assertEquals, assertFalse, jsonResponse, mockFetch } from "./test_utils.ts";

Deno.test("digest email templates: EN/FR/AR, RTL for Arabic, escaped content, one-click unsubscribe headers", () => {
  const ar = renderDigestEmail({
    to: "a@x.io",
    locale: "ar",
    title: "جدول اليوم",
    body: "اجتماع ‎09:00\n<script>x</script>",
    unsubscribeUrl: "https://p.supabase.co/functions/v1/email-unsubscribe?u=1&t=2",
  });
  assert(ar.html.includes('dir="rtl"') && ar.html.includes('lang="ar"'));
  assert(ar.html.includes("إلغاء الاشتراك"));
  assert(ar.html.includes("&lt;script&gt;") && !ar.html.includes("<script>"));
  assertEquals(ar.subject, "جدول اليوم");
  assertEquals(ar.headers?.["List-Unsubscribe-Post"], "List-Unsubscribe=One-Click");
  const fr = renderDigestEmail({ to: "a@x.io", locale: "fr-FR", title: "T", body: "B", unsubscribeUrl: "u" });
  assert(fr.html.includes("Se désabonner") && fr.html.includes('dir="ltr"'));
  assert(fr.text.includes("Se désabonner: u"));
});

Deno.test("unsubscribe links are signed per user and verified in constant time", async () => {
  const t = await unsubscribeToken("secret", "11111111-1111-4111-8111-111111111111");
  assert(await verifyUnsubscribeToken("secret", "11111111-1111-4111-8111-111111111111", t));
  assertFalse(await verifyUnsubscribeToken("secret", "22222222-2222-4222-8222-222222222222", t));
  assertFalse(await verifyUnsubscribeToken("other", "11111111-1111-4111-8111-111111111111", t));
  const url = await unsubscribeUrl(
    "https://p.supabase.co/",
    "secret",
    "11111111-1111-4111-8111-111111111111",
  );
  assert(
    url.startsWith(
      "https://p.supabase.co/functions/v1/email-unsubscribe?u=11111111-1111-4111-8111-111111111111&t=",
    ),
  );
});

Deno.test("HTTP email sender: success, retryable and permanent failures", async () => {
  const ok = mockFetch(() => jsonResponse({ id: "em_1" }));
  const r1 = await new HttpEmailSender("k", "Everslot <d@x.io>", "https://mail.test", ok.fetch).send({
    to: "a@x.io",
    subject: "s",
    html: "h",
    text: "t",
  });
  assertEquals(r1, { ok: true, id: "em_1" });
  const body = JSON.parse(String(ok.calls[0].init?.body));
  assertEquals(body.to, ["a@x.io"]);
  assertEquals((ok.calls[0].init?.headers as Record<string, string>).Authorization, "Bearer k");
  const busy = mockFetch(() => jsonResponse({ message: "rate" }, 429));
  const r2 = await new HttpEmailSender("k", "f", "https://mail.test", busy.fetch).send({
    to: "a",
    subject: "",
    html: "",
    text: "",
  });
  assertEquals(r2.ok, false);
  assert(!r2.ok && r2.retryable);
  const bad = mockFetch(() => jsonResponse({ message: "invalid" }, 422));
  const r3 = await new HttpEmailSender("k", "f", "https://mail.test", bad.fetch).send({
    to: "a",
    subject: "",
    html: "",
    text: "",
  });
  assert(!r3.ok && !r3.retryable);
});

Deno.test("provider events: hard bounces and complaints suppress, soft bounces don't", () => {
  assertEquals(
    suppressionsFromEvent({ type: "email.bounced", data: { to: ["a@x.io"], bounce: { type: "Permanent" } } }),
    [
      { email: "a@x.io", reason: "bounce" },
    ],
  );
  assertEquals(
    suppressionsFromEvent({ type: "email.bounced", data: { to: ["a@x.io"], bounce: { type: "Transient" } } }),
    [],
  );
  assertEquals(suppressionsFromEvent({ type: "email.complained", data: { to: ["b@x.io"] } }), [
    { email: "b@x.io", reason: "complaint" },
  ]);
  assertEquals(suppressionsFromEvent({ type: "email.delivered", data: { to: ["c@x.io"] } }), []);
  assertEquals(suppressionsFromEvent(null), []);
});
