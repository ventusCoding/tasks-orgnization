// Third-party dependencies, pinned in ONE place.
//
// The hosted Edge runtime is Deno 2.1-compatible while local Deno is newer: only fully pinned
// `npm:` / `jsr:` specifiers are used, no import map, and no lockfile is committed (deno.json
// sets "lock": false). Bump versions here and in docs/architecture.md §3 together.

export { createClient } from "npm:@supabase/supabase-js@2.116.0";
export type { SupabaseClient } from "npm:@supabase/supabase-js@2.116.0";
export { importPKCS8, SignJWT } from "npm:jose@6.2.12";
// Server-side planning fallback (T7.4.17): RFC 5545 expansion on Temporal (polyfilled: the hosted
// runtime ships no Temporal global).
import "npm:temporal-polyfill@1.0.5/global";
export { RRuleTemporal } from "npm:rrule-temporal@2.2.7";
