// Caller authentication: user JWTs (verified by Supabase Auth) or the cron/webhook shared secret.

import { unauthorized } from "./errors.ts";
import { readEnv } from "./env.ts";
import type { AdminClient } from "./supabase.ts";

/** Constant-time string comparison (length is not secret). */
export function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  let diff = x.length ^ y.length;
  const n = Math.max(x.length, y.length);
  for (let i = 0; i < n; i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

/** True when the request carries `x-cron-secret` equal to CRON_SECRET. False if the secret is unset. */
export function hasValidCronSecret(
  req: Request,
  secret: string | undefined = readEnv("CRON_SECRET"),
): boolean {
  if (!secret) return false;
  const given = req.headers.get("x-cron-secret");
  return given !== null && timingSafeEqual(given, secret);
}

export function bearerToken(req: Request): string | null {
  const header = req.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  return match ? match[1].trim() : null;
}

export interface AuthUser {
  id: string;
  isAnonymous: boolean;
}

/** Verifies the user's access token with Supabase Auth (works with symmetric and asymmetric JWTs). */
export async function requireUser(req: Request, admin: Pick<AdminClient, "auth">): Promise<AuthUser> {
  const token = bearerToken(req);
  if (!token) throw unauthorized("Missing bearer token");
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data?.user) throw unauthorized("Invalid or expired token");
  return { id: data.user.id, isAnonymous: Boolean(data.user.is_anonymous) };
}
