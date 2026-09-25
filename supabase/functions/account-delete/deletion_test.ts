import { unauthorized } from "../_shared/errors.ts";
import type { AdminClient } from "../_shared/supabase.ts";
import { assertEquals, assertRejects } from "../_shared/test_utils.ts";
import { type AccountDeletionPorts, deleteAccount } from "./deletion.ts";
import { createHandler } from "./handler.ts";

const USER = "00000000-0000-4000-8000-0000000000b1";

/** In-memory account: storage objects + an auth user that can be deleted once. */
function fakePorts(objectCount: number) {
  let objects = Array.from({ length: objectCount }, (_, i) => `${USER}/att-${i}/file.jpg`);
  let userExists = true;
  const log: string[] = [];
  const ports: AccountDeletionPorts = {
    listObjects: (prefix) => Promise.resolve(objects.filter((o) => o.startsWith(`${prefix}/`))),
    removeObjects: (paths) => {
      log.push(`remove:${paths.length}`);
      objects = objects.filter((o) => !paths.includes(o));
      return Promise.resolve();
    },
    prepare: () => {
      log.push("prepare");
      return Promise.resolve();
    },
    deleteUser: () => {
      log.push("deleteUser");
      const outcome = userExists ? "deleted" : "not_found";
      userExists = false;
      return Promise.resolve(outcome);
    },
  };
  return { ports, log, remaining: () => objects.length };
}

Deno.test("deleteAccount removes objects in batches, then devices/jobs, then the auth user", async () => {
  const { ports, log, remaining } = fakePorts(250);
  const result = await deleteAccount(ports, USER);
  assertEquals(log, ["remove:100", "remove:100", "remove:50", "prepare", "deleteUser"]);
  assertEquals(remaining(), 0);
  assertEquals(result, {
    userId: USER,
    objectsDeleted: 250,
    userDeleted: true,
    alreadyDeleted: false,
    apple: "not_configured",
  });
});

Deno.test("deleteAccount is idempotent", async () => {
  const { ports } = fakePorts(3);
  await deleteAccount(ports, USER);
  const again = await deleteAccount(ports, USER);
  assertEquals(again.objectsDeleted, 0);
  assertEquals(again.alreadyDeleted, true);
  assertEquals(again.userDeleted, false);
});

Deno.test("a failing storage call aborts before the user is deleted (retry-safe)", async () => {
  const { ports, log } = fakePorts(1);
  ports.removeObjects = () => Promise.reject(new Error("storage down"));
  await assertRejects(() => deleteAccount(ports, USER), Error, "storage down");
  assertEquals(log.includes("deleteUser"), false);
});

Deno.test("account-delete handler: user JWT, cron secret, errors", async () => {
  const { ports } = fakePorts(2);
  const handler = createHandler({
    createClient: () => ({}) as AdminClient,
    createPorts: () => ports,
    isCron: (req) => req.headers.get("x-cron-secret") === "s",
    authenticate: (req) =>
      req.headers.get("authorization") === "Bearer good"
        ? Promise.resolve({ id: USER })
        : Promise.reject(unauthorized()),
  });
  const post = (headers: Record<string, string>, body = "{}") =>
    new Request("http://localhost/account-delete", { method: "POST", headers, body });

  assertEquals((await handler(post({}))).status, 401);
  assertEquals(
    (await handler(post({ "x-cron-secret": "s" }, JSON.stringify({ user_id: "nope" })))).status,
    400,
  );

  const res = await handler(post({ authorization: "Bearer good" }));
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { deleted: true, already_deleted: false, objects_deleted: 2 });

  const retry = await handler(post({ "x-cron-secret": "s" }, JSON.stringify({ user_id: USER })));
  assertEquals(await retry.json(), { deleted: true, already_deleted: true, objects_deleted: 0 });

  const noClient = createHandler({
    createClient: () => null,
    createPorts: () => ports,
    isCron: () => false,
    authenticate: () => Promise.resolve({ id: USER }),
  });
  assertEquals((await noClient(post({}))).status, 503);
});
