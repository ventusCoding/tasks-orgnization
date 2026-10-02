// FcmTokenStore backed by `private.fcm_token_cache` through the service-role RPCs (T7.4.06).

import type { CachedToken, FcmTokenStore } from "./fcm.ts";
import { type AdminClient, callRpc } from "./supabase.ts";

export function createSupabaseTokenStore(client: AdminClient): FcmTokenStore {
  return {
    async get(key: string): Promise<CachedToken | null> {
      const rows = await callRpc<Array<{ access_token: string; expires_at: string }>>(
        client,
        "fcm_token_cache_get",
        { p_key: key },
      );
      const row = rows?.[0];
      if (!row) return null;
      const expiresAtMs = Date.parse(row.expires_at);
      return Number.isNaN(expiresAtMs) ? null : { token: row.access_token, expiresAtMs };
    },
    async put(key: string, token: CachedToken): Promise<void> {
      await callRpc<unknown>(client, "fcm_token_cache_put", {
        p_key: key,
        p_access_token: token.token,
        p_expires_at: new Date(token.expiresAtMs).toISOString(),
      });
    },
  };
}
