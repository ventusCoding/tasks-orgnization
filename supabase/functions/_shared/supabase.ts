// Admin Supabase client (secret key, bypasses RLS). Only for server code — never ship this key.

import { createClient, type SupabaseClient } from "./deps.ts";
import { readEnv, serviceKey } from "./env.ts";

// deno-lint-ignore no-explicit-any
export type AdminClient = SupabaseClient<any, any, any>;

/** Returns null when SUPABASE_URL or the secret key is missing (callers degrade gracefully). */
export function createAdminClient(): AdminClient | null {
  const url = readEnv("SUPABASE_URL");
  const key = serviceKey();
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    db: { schema: "app" },
    global: { headers: { "x-client-info": "everslot-edge" } },
  }) as AdminClient;
}

/** Calls an `app.*` RPC and throws on error. */
export async function callRpc<T>(
  client: AdminClient,
  fn: string,
  args: Record<string, unknown> = {},
): Promise<T> {
  const { data, error } = await client.rpc(fn, args);
  if (error) throw new Error(`rpc ${fn} failed: ${error.message}`);
  return data as T;
}
