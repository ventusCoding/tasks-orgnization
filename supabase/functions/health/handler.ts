// health — liveness + configuration report. Public (no data); a DB round-trip only with `x-cron-secret`.

import { hasValidCronSecret } from "../_shared/auth.ts";
import { handleCors } from "../_shared/cors.ts";
import { errorResponse, json } from "../_shared/errors.ts";
import { readEnv, serviceKey } from "../_shared/env.ts";
import { parseServiceAccount } from "../_shared/fcm.ts";
import { type AdminClient, createAdminClient } from "../_shared/supabase.ts";

export const VERSION = "1.0.0";

export interface HealthDeps {
  env: (name: string) => string | undefined;
  hasServiceKey: () => boolean;
  isAuthorized: (req: Request) => boolean;
  createClient: () => AdminClient | null;
}

export const defaultDeps: HealthDeps = {
  env: readEnv,
  hasServiceKey: () => serviceKey() !== undefined,
  isAuthorized: (req) => hasValidCronSecret(req),
  createClient: createAdminClient,
};

export function createHandler(deps: HealthDeps = defaultDeps) {
  return async (req: Request): Promise<Response> => {
    try {
      const cors = handleCors(req);
      if (cors) return cors;
      const checks: Record<string, unknown> = {
        supabase_configured: Boolean(deps.env("SUPABASE_URL")) && deps.hasServiceKey(),
        fcm_configured: parseServiceAccount(deps.env("FCM_SERVICE_ACCOUNT")) !== null,
        cron_secret_configured: Boolean(deps.env("CRON_SECRET")),
      };
      if (deps.isAuthorized(req)) {
        const client = deps.createClient();
        if (!client) checks.db = "not_configured";
        else {
          const { data, error } = await client.rpc("ops_health");
          checks.db = error ? "error" : "ok";
          if (!error) checks.ops = data;
        }
      }
      return json({
        status: "ok",
        service: "everslot-edge",
        version: VERSION,
        time: new Date().toISOString(),
        checks,
      });
    } catch (err) {
      return errorResponse(err, "health");
    }
  };
}
