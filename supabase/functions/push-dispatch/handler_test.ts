import type { PushSender } from "../_shared/fcm.ts";
import { assertEquals } from "../_shared/test_utils.ts";
import type { DispatchStore } from "./dispatcher.ts";
import { createHandler, type PushDispatchDeps } from "./handler.ts";

const emptyStore: DispatchStore = {
  claim: () => Promise.resolve([]),
  guards: () => Promise.resolve([]),
  upsertInbox: () => Promise.resolve(),
  devices: () => Promise.resolve({}),
  complete: () => Promise.resolve(),
  heartbeat: () => Promise.resolve(),
};

function deps(overrides: Partial<PushDispatchDeps> = {}) {
  const started: string[] = [];
  const d: PushDispatchDeps = {
    isAuthorized: (req) => req.headers.get("x-cron-secret") === "s3cret",
    createStore: () => emptyStore,
    createSender: () => null,
    background: (task) => {
      started.push("task");
      void task();
      return "wait_until";
    },
    ...overrides,
  };
  return { d, started };
}

const post = (headers: Record<string, string> = {}) =>
  new Request("http://localhost/push-dispatch", { method: "POST", headers, body: "{}" });

Deno.test("push-dispatch rejects calls without the cron secret", async () => {
  const { d, started } = deps();
  const res = await createHandler(d)(post());
  assertEquals(res.status, 401);
  assertEquals((await res.json()).error.code, "unauthorized");
  assertEquals(started.length, 0);
});

Deno.test("push-dispatch answers 202 immediately and works in the background", async () => {
  const { d, started } = deps();
  const res = await createHandler(d)(post({ "x-cron-secret": "s3cret" }));
  assertEquals(res.status, 202);
  assertEquals(await res.json(), { accepted: true, push_configured: false, mode: "wait_until" });
  assertEquals(started, ["task"]);
});

Deno.test("push-dispatch reports push_configured when FCM is set up", async () => {
  const sender: PushSender = { send: () => Promise.resolve({ ok: true, kind: "ok", messageId: "m" }) };
  const { d } = deps({ createSender: () => sender });
  const res = await createHandler(d)(post({ "x-cron-secret": "s3cret" }));
  assertEquals((await res.json()).push_configured, true);
});

Deno.test("push-dispatch without Supabase credentials → 503 not_configured", async () => {
  const { d } = deps({ createStore: () => null });
  const res = await createHandler(d)(post({ "x-cron-secret": "s3cret" }));
  assertEquals(res.status, 503);
  assertEquals((await res.json()).error.code, "not_configured");
});

Deno.test("push-dispatch: CORS preflight and method check", async () => {
  const { d } = deps();
  const handler = createHandler(d);
  assertEquals(
    (await handler(new Request("http://localhost/push-dispatch", { method: "OPTIONS" }))).status,
    200,
  );
  assertEquals((await handler(new Request("http://localhost/push-dispatch"))).status, 405);
});
