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
  /** Authenticator assurance level of this token ("aal1" | "aal2"), null when absent. */
  aal: string | null;
  /** The user enrolled a verified MFA factor (T1.5.17): sensitive actions then need aal2. */
  hasVerifiedFactor: boolean;
}

/** Reads one claim of an already verified JWT (no signature check here). Null when unreadable. */
export function jwtClaim(token: string, name: string): unknown {
  const part = token.split(".")[1];
  if (!part) return null;
  try {
    const base64 = part.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(part.length / 4) * 4, "=");
    const payload = JSON.parse(atob(base64)) as Record<string, unknown>;
    return payload[name] ?? null;
  } catch {
    return null;
  }
}

/** Verifies the user's access token with Supabase Auth (works with symmetric and asymmetric JWTs). */
export async function requireUser(req: Request, admin: Pick<AdminClient, "auth">): Promise<AuthUser> {
  const token = bearerToken(req);
  if (!token) throw unauthorized("Missing bearer token");
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data?.user) throw unauthorized("Invalid or expired token");
  const factors = (data.user as { factors?: { status?: string }[] }).factors ?? [];
  const aal = jwtClaim(token, "aal");
  return {
    id: data.user.id,
    isAnonymous: Boolean(data.user.is_anonymous),
    aal: typeof aal === "string" ? aal : null,
    hasVerifiedFactor: factors.some((f) => f.status === "verified"),
  };
}
