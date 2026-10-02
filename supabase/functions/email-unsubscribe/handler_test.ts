import { unsubscribeToken } from "../_shared/email.ts";
import { assert, assertEquals } from "../_shared/test_utils.ts";
import { createHandler } from "./handler.ts";

const USER = "11111111-1111-4111-8111-111111111111";

Deno.test("email-unsubscribe: valid signed link turns digest emails off (GET page and one-click POST)", async () => {
  const done: string[] = [];
  const handler = createHandler({
    secret: () => "sec",
    unsubscribe: (u) => (done.push(u), Promise.resolve(true)),
  });
  const t = await unsubscribeToken("sec", USER);
  const get = await handler(
    new Request(`http://x/email-unsubscribe?u=${USER}&t=${t}`, { headers: { "accept-language": "fr-FR" } }),
  );
  assertEquals(get.status, 200);
  assert((await get.text()).includes("Vous ne recevrez plus"));
  const post = await handler(
    new Request(`http://x/email-unsubscribe?u=${USER}&t=${t}`, {
      method: "POST",
      body: "List-Unsubscribe=One-Click",
    }),
  );
  assertEquals(post.status, 200);
  assertEquals(done, [USER, USER]);
});

Deno.test("email-unsubscribe rejects forged or malformed links", async () => {
  const done: string[] = [];
  const handler = createHandler({
    secret: () => "sec",
    unsubscribe: (u) => (done.push(u), Promise.resolve(true)),
  });
  const forged = await handler(new Request(`http://x/email-unsubscribe?u=${USER}&t=forged`));
  assertEquals(forged.status, 400);
  await forged.body?.cancel();
  const bad = await handler(new Request(`http://x/email-unsubscribe?u=not-a-uuid&t=x`));
  assertEquals(bad.status, 400);
  await bad.body?.cancel();
  assertEquals(done.length, 0);
});
