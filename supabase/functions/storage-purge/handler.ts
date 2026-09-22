// storage-purge — drains private.storage_deletions (objects no attachment row references any more,
// arch §6.7 / T2.2.11) through the Storage API. Invoked by the daily job with `x-cron-secret`.

import { hasValidCronSecret } from "../_shared/auth.ts";
import { handleCors } from "../_shared/cors.ts";
import { assertMethod, errorResponse, json, notConfigured, unauthorized } from "../_shared/errors.ts";
import { log } from "../_shared/log.ts";
import { type AdminClient, callRpc, createAdminClient } from "../_shared/supabase.ts";

export interface StorageDeletion {
  id: number;
  bucket: string;
  path: string;
}

export interface StoragePurgePorts {
  claim(limit: number): Promise<StorageDeletion[]>;
  remove(bucket: string, paths: string[]): Promise<void>;
  done(ids: number[], errors: Record<string, string>): Promise<void>;
}

export async function purgeStorage(
  ports: StoragePurgePorts,
  maxRounds = 10,
): Promise<{ removed: number; failed: number }> {
  let removed = 0;
  let failed = 0;
  for (let round = 0; round < maxRounds; round++) {
    const batch = await ports.claim(100);
    if (batch.length === 0) break;
    const errors: Record<string, string> = {};
    const byBucket = new Map<string, StorageDeletion[]>();
    for (const item of batch) byBucket.set(item.bucket, [...(byBucket.get(item.bucket) ?? []), item]);
    for (const [bucket, items] of byBucket) {
      try {
        await ports.remove(bucket, items.map((i) => i.path));
        removed += items.length;
      } catch (err) {
        failed += items.length;
        for (const i of items) errors[String(i.id)] = err instanceof Error ? err.message : String(err);
      }
    }
    await ports.done(batch.map((i) => i.id), errors);
    if (batch.length < 100) break;
  }
  return { removed, failed };
}

export function createSupabasePorts(client: AdminClient): StoragePurgePorts {
  return {
    claim: (limit) => callRpc<StorageDeletion[]>(client, "storage_purge_claim", { p_limit: limit }),
    async remove(bucket, paths) {
      const { error } = await client.storage.from(bucket).remove(paths);
      if (error) throw new Error(error.message);
    },
    async done(ids, errors) {
      await callRpc<number>(client, "storage_purge_done", { p_ids: ids, p_errors: errors });
    },
  };
}

export function createHandler(
  deps = {
    isAuthorized: (req: Request) => hasValidCronSecret(req),
    createClient: createAdminClient,
  },
) {
  return async (req: Request): Promise<Response> => {
    try {
      const cors = handleCors(req);
      if (cors) return cors;
      assertMethod(req, ["POST"]);
      if (!deps.isAuthorized(req)) throw unauthorized("Invalid cron secret");
      await req.body?.cancel();
      const client = deps.createClient();
      if (!client) throw notConfigured("SUPABASE_URL / SUPABASE_SECRET_KEY");
      const summary = await purgeStorage(createSupabasePorts(client));
      log("info", "storage_purge.done", summary);
      return json(summary);
    } catch (err) {
      return errorResponse(err, "storage_purge");
    }
  };
}
