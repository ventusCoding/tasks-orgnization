// HTTP entry of account-delete.
//   * user call:  POST with the user's access token (Authorization: Bearer …) → deletes that user.
//   * cron retry: POST with `x-cron-secret` and {"user_id"} (app.request_account_deletion / daily job).

import { hasValidCronSecret, requireUser } from "../_shared/auth.ts";
import { handleCors } from "../_shared/cors.ts";
import { assertMethod, badRequest, errorResponse, json, notConfigured } from "../_shared/errors.ts";
import { log } from "../_shared/log.ts";
import { type AdminClient, callRpc, createAdminClient } from "../_shared/supabase.ts";
import { type AccountDeletionPorts, deleteAccount } from "./deletion.ts";

const BUCKET = "attachments";
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function createSupabasePorts(client: AdminClient): AccountDeletionPorts {
  const bucket = () => client.storage.from(BUCKET);
  return {
    async listObjects(prefix) {
      const out: string[] = [];
      const walk = async (folder: string, depth: number): Promise<void> => {
        for (let offset = 0;; offset += 1000) {
          const { data, error } = await bucket().list(folder, { limit: 1000, offset });
          if (error) throw new Error(`storage list failed: ${error.message}`);
          for (const entry of data ?? []) {
            const path = `${folder}/${entry.name}`;
            // Folders have no id; objects do.
            if (entry.id === null && depth < 8) await walk(path, depth + 1);
            else out.push(path);
          }
          if ((data ?? []).length < 1000) break;
        }
      };
      await walk(prefix, 0);
      return out;
    },
    async removeObjects(paths) {
      const { error } = await bucket().remove(paths);
      if (error) throw new Error(`storage remove failed: ${error.message}`);
    },
    async prepare(userId) {
      await callRpc<unknown>(client, "account_delete_prepare", { p_user_id: userId });
    },
    async deleteUser(userId) {
      const { error } = await client.auth.admin.deleteUser(userId);
      if (!error) return "deleted";
      if ((error as { status?: number }).status === 404) return "not_found";
      throw new Error(`auth delete failed: ${error.message}`);
    },
    // Sign in with Apple token revocation needs the Apple client secret (placeholder: APPLE_CLIENT_SECRET).
    revokeAppleTokens: () => Promise.resolve("not_configured" as const),
  };
}

export interface AccountDeleteDeps {
  createClient: () => AdminClient | null;
  createPorts: (client: AdminClient) => AccountDeletionPorts;
  isCron: (req: Request) => boolean;
  authenticate: (req: Request, client: AdminClient) => Promise<{ id: string }>;
}

export const defaultDeps: AccountDeleteDeps = {
  createClient: createAdminClient,
  createPorts: createSupabasePorts,
  isCron: (req) => hasValidCronSecret(req),
  authenticate: (req, client) => requireUser(req, client),
};

export function createHandler(deps: AccountDeleteDeps = defaultDeps) {
  return async (req: Request): Promise<Response> => {
    try {
      const cors = handleCors(req);
      if (cors) return cors;
      assertMethod(req, ["POST"]);
      const client = deps.createClient();
      if (!client) throw notConfigured("SUPABASE_URL / SUPABASE_SECRET_KEY");

      let userId: string;
      if (deps.isCron(req)) {
        const body = await req.json().catch(() => ({})) as Record<string, unknown>;
        if (typeof body.user_id !== "string" || !UUID.test(body.user_id)) {
          throw badRequest("user_id must be a uuid");
        }
        userId = body.user_id;
      } else {
        userId = (await deps.authenticate(req, client)).id;
        await req.body?.cancel();
      }

      const result = await deleteAccount(deps.createPorts(client), userId);
      log("info", "account_delete.done", {
        objects: result.objectsDeleted,
        userDeleted: result.userDeleted,
        alreadyDeleted: result.alreadyDeleted,
      });
      return json({
        deleted: true,
        already_deleted: result.alreadyDeleted,
        objects_deleted: result.objectsDeleted,
      });
    } catch (err) {
      return errorResponse(err, "account_delete");
    }
  };
}
