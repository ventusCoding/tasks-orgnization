import { bearerToken, hasValidCronSecret, requireUser, timingSafeEqual } from "./auth.ts";
import { mapWithConcurrency, runInBackground } from "./background.ts";
import { handleCors } from "./cors.ts";
import { errorResponse, HttpError } from "./errors.ts";
import { redact } from "./log.ts";
import type { AdminClient } from "./supabase.ts";
import { assert, assertEquals, assertRejects } from "./test_utils.ts";

Deno.test("timingSafeEqual", () => {
  assert(timingSafeEqual("abc", "abc"));
  assert(!timingSafeEqual("abc", "abd"));
  assert(!timingSafeEqual("abc", "abcd"));
  assert(timingSafeEqual("", ""));
});

Deno.test("cron secret check fails closed when CRON_SECRET is unset", () => {
  const req = (h?: string) => new Request("http://x", { headers: h ? { "x-cron-secret": h } : {} });
  assert(!hasValidCronSecret(req("s"), undefined));
  assert(!hasValidCronSecret(req(), "s"));
  assert(!hasValidCronSecret(req("wrong"), "s"));
  assert(hasValidCronSecret(req("s"), "s"));
});

Deno.test("bearerToken + requireUser", async () => {
  assertEquals(
    bearerToken(new Request("http://x", { headers: { authorization: "Bearer abc.def" } })),
    "abc.def",
  );
  assertEquals(bearerToken(new Request("http://x")), null);
  const auth = {
    auth: {
      getUser: (token: string) =>
        Promise.resolve(
          token === "good"
            ? { data: { user: { id: "u1", is_anonymous: true } }, error: null }
            : { data: { user: null }, error: { message: "invalid" } },
        ),
    },
  } as unknown as AdminClient;
  const user = await requireUser(
    new Request("http://x", { headers: { authorization: "Bearer good" } }),
    auth,
  );
  assertEquals(user, { id: "u1", isAnonymous: true });
  await assertRejects(
    () => requireUser(new Request("http://x", { headers: { authorization: "Bearer bad" } }), auth),
    HttpError,
  );
  await assertRejects(() => requireUser(new Request("http://x"), auth), HttpError);
});

Deno.test("errorResponse: typed errors keep their code, unknown errors do not leak", async () => {
  const typed = errorResponse(new HttpError(418, "teapot", "short and stout"));
  assertEquals(typed.status, 418);
  assertEquals(await typed.json(), { error: { code: "teapot", message: "short and stout" } });
  const originalError = console.error;
  console.error = () => {};
  try {
    const hidden = errorResponse(new Error("password=hunter2"));
    assertEquals(hidden.status, 500);
    assertEquals(await hidden.json(), { error: { code: "internal_error", message: "Unexpected error" } });
  } finally {
    console.error = originalError;
  }
});

Deno.test("logs redact sensitive keys", () => {
  assertEquals(redact({ push_token: "t", count: 3, nested: { authorization: "Bearer x", ok: true } }), {
    push_token: "[redacted]",
    count: 3,
    nested: { authorization: "[redacted]", ok: true },
  });
});

Deno.test("CORS preflight", () => {
  assertEquals(handleCors(new Request("http://x", { method: "OPTIONS" }))?.status, 200);
  assertEquals(handleCors(new Request("http://x")), null);
});

Deno.test("mapWithConcurrency keeps order and bounds parallelism", async () => {
  let inFlight = 0;
  let peak = 0;
  const out = await mapWithConcurrency([1, 2, 3, 4, 5, 6, 7], 3, async (n) => {
    inFlight++;
    peak = Math.max(peak, inFlight);
    await new Promise((r) => setTimeout(r, 5 * (8 - n)));
    inFlight--;
    return n * 10;
  });
  assertEquals(out, [10, 20, 30, 40, 50, 60, 70]);
  assertEquals(peak, 3);
});

Deno.test("runInBackground uses EdgeRuntime.waitUntil when present", async () => {
  const g = globalThis as { EdgeRuntime?: { waitUntil: (p: Promise<unknown>) => void } };
  const waited: Promise<unknown>[] = [];
  g.EdgeRuntime = { waitUntil: (p) => waited.push(p) };
  try {
    let ran = false;
    assertEquals(runInBackground(() => Promise.resolve().then(() => (ran = true)), () => {}), "wait_until");
    await Promise.all(waited);
    assert(ran);
  } finally {
    delete g.EdgeRuntime;
  }
  const errors: unknown[] = [];
  assertEquals(runInBackground(() => Promise.reject(new Error("x")), (e) => errors.push(e)), "detached");
  await new Promise((r) => setTimeout(r, 0));
  assertEquals(errors.length, 1);
});
