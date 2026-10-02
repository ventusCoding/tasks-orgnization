// HTTP entry of sync-nudge: called by the `app.sync_heads` trigger (pg_net, `x-cron-secret`) with
// {"type":"sync_head","user_id","head_rev","origin_device_id"}.

import { hasValidCronSecret } from "../_shared/auth.ts";
import { handleCors } from "../_shared/cors.ts";
import {
  assertMethod,
  badRequest,
  errorResponse,
  json,
  notConfigured,
  unauthorized,
} from "../_shared/errors.ts";
import { createFcmSenderFromEnv, type PushSender } from "../_shared/fcm.ts";
import { createSupabaseTokenStore } from "../_shared/fcm_token_store.ts";
import { log } from "../_shared/log.ts";
import { type AdminClient, createAdminClient } from "../_shared/supabase.ts";
import { type NudgeDevice, type NudgeEvent, type NudgeStore, runNudge } from "./nudge.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function createSupabaseNudgeStore(client: AdminClient): NudgeStore {
  return {
    async devices(userId) {
      const { data, error } = await client
        .from("devices")
        .select("id, platform, push_token, push_enabled, revoked_at, last_seen_at, last_nudged_at")
        .eq("user_id", userId)
        .is("revoked_at", null);
      if (error) throw new Error(`devices query failed: ${error.message}`);
      return (data ?? []) as NudgeDevice[];
    },
    async markNudged(ids, at) {
      const { error } = await client.from("devices").update({ last_nudged_at: at.toISOString() }).in(
        "id",
        ids,
      );
      if (error) throw new Error(`devices update failed: ${error.message}`);
    },
    async clearTokens(ids) {
      const { error } = await client.from("devices").update({ push_token: null, push_token_updated_at: null })
        .in("id", ids);
      if (error) throw new Error(`devices update failed: ${error.message}`);
    },
  };
}

export function parseNudgeEvent(body: unknown): NudgeEvent {
  const b = (body ?? {}) as Record<string, unknown>;
  const userId = typeof b.user_id === "string" ? b.user_id : "";
  if (!UUID.test(userId)) throw badRequest("user_id must be a uuid");
  const origin = typeof b.origin_device_id === "string" && UUID.test(b.origin_device_id)
    ? b.origin_device_id
    : null;
  const head = typeof b.head_rev === "number" ? b.head_rev : Number(b.head_rev ?? 0);
  return { user_id: userId, head_rev: Number.isFinite(head) ? head : 0, origin_device_id: origin };
}

export interface SyncNudgeDeps {
  isAuthorized: (req: Request) => boolean;
  createStore: () => NudgeStore | null;
  createSender: () => PushSender | null;
  now: () => Date;
}

export const defaultDeps: SyncNudgeDeps = {
  isAuthorized: (req) => hasValidCronSecret(req),
  createStore: () => {
    const client = createAdminClient();
    return client ? createSupabaseNudgeStore(client) : null;
  },
  createSender: () => {
    const client = createAdminClient();
    return createFcmSenderFromEnv(client ? createSupabaseTokenStore(client) : null);
  },
  now: () => new Date(),
};

export function createHandler(deps: SyncNudgeDeps = defaultDeps) {
  return async (req: Request): Promise<Response> => {
    try {
      const cors = handleCors(req);
      if (cors) return cors;
      assertMethod(req, ["POST"]);
      if (!deps.isAuthorized(req)) throw unauthorized("Invalid cron secret");
      let body: unknown;
      try {
        body = await req.json();
      } catch {
        throw badRequest("Body must be JSON");
      }
      const event = parseNudgeEvent(body);

      const sender = deps.createSender();
      if (!sender) return json({ skipped: "push_not_configured" }, 200);
      const store = deps.createStore();
      if (!store) throw notConfigured("SUPABASE_URL / SUPABASE_SECRET_KEY");

      const summary = await runNudge(event, store, sender, deps.now());
      log("info", "sync_nudge.done", { ...summary });
      return json(summary, 200);
    } catch (err) {
      return errorResponse(err, "sync_nudge");
    }
  };
}
