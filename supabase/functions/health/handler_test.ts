import type { AdminClient } from "../_shared/supabase.ts";
import { assertEquals } from "../_shared/test_utils.ts";
import { createHandler, type HealthDeps } from "./handler.ts";

const env = (values: Record<string, string>) => (name: string) => values[name];

Deno.test("health reports configuration without secrets", async () => {
  const deps: HealthDeps = {
    env: env({ SUPABASE_URL: "http://kong:8000", CRON_SECRET: "s" }),
    hasServiceKey: () => true,
    isAuthorized: () => false,
    createClient: () => null,
  };
  const res = await createHandler(deps)(new Request("http://localhost/health"));
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.status, "ok");
  assertEquals(body.checks, {
    supabase_configured: true,
    fcm_configured: false,
    cron_secret_configured: true,
  });
});

Deno.test("health runs a database check only for the cron caller", async () => {
  const client = {
    rpc: () => Promise.resolve({ data: { dispatcher_lag_seconds: 0 }, error: null }),
  } as unknown as AdminClient;
  const deps: HealthDeps = {
    env: env({}),
    hasServiceKey: () => false,
    isAuthorized: () => true,
    createClient: () => client,
  };
  const body = await (await createHandler(deps)(new Request("http://localhost/health"))).json();
  assertEquals(body.checks.db, "ok");
  assertEquals(body.checks.ops, { dispatcher_lag_seconds: 0 });

  const noDb =
    await (await createHandler({ ...deps, createClient: () => null })(new Request("http://localhost/health")))
      .json();
  assertEquals(noDb.checks.db, "not_configured");
});
