import { assertEquals } from "../_shared/test_utils.ts";
import { createHandler } from "./handler.ts";

Deno.test("email-events: shared secret required; bounces and complaints suppressed", async () => {
  const suppressed: string[] = [];
  const handler = createHandler({
    secret: () => "hook",
    suppress: (email, reason) => (suppressed.push(`${email}:${reason}`), Promise.resolve()),
  });
  const body = JSON.stringify({
    type: "email.bounced",
    data: { to: ["a@x.io"], bounce: { type: "Permanent" } },
  });
  const denied = await handler(new Request("http://x/email-events", { method: "POST", body }));
  assertEquals(denied.status, 401);
  await denied.body?.cancel();
  const ok = await handler(
    new Request("http://x/email-events", {
      method: "POST",
      headers: { "x-email-webhook-secret": "hook" },
      body,
    }),
  );
  assertEquals(ok.status, 200);
  assertEquals((await ok.json()).suppressed, 1);
  assertEquals(suppressed, ["a@x.io:bounce"]);
});
