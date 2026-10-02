// Minimal Firebase Cloud Messaging HTTP v1 client (arch §6.13, T7.4.06).
//
// * Service-account JWT (RS256, signed with `jose`) → OAuth2 access token, cached in module scope until
//   ~5 minutes before expiry (one mint per warm instance and service account).
// * One HTTP v1 request per token; typed results with error mapping (UNREGISTERED, INVALID_ARGUMENT,
//   SENDER_ID_MISMATCH, QUOTA_EXCEEDED + Retry-After, UNAVAILABLE/INTERNAL/5xx, THIRD_PARTY_AUTH_ERROR).
// * Message builders: alert pushes (android.notification.tag = apns-collapse-id = dedupe key, TTL /
//   apns-expiration) and data-only sync nudges; 4 KB payload budget.
//
// Configuration: FCM_SERVICE_ACCOUNT = the Firebase service-account JSON, raw or base64-encoded.
// Without it `createFcmSenderFromEnv()` returns null and callers skip pushes gracefully.

import { importPKCS8, SignJWT } from "./deps.ts";
import { readEnv } from "./env.ts";
import type { Importance } from "./types.ts";

export const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
export const DEFAULT_TOKEN_URI = "https://oauth2.googleapis.com/token";
export const TOKEN_REFRESH_MARGIN_MS = 5 * 60 * 1000;
export const MAX_PAYLOAD_BYTES = 4000; // FCM/APNs limit is 4096 bytes: keep a margin
export const MIN_QUOTA_RETRY_SECONDS = 60;

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

/** Parses FCM_SERVICE_ACCOUNT (raw JSON or base64 JSON). Returns null when absent or invalid. */
export function parseServiceAccount(raw: string | undefined | null): ServiceAccount | null {
  if (!raw || raw.trim() === "") return null;
  let text = raw.trim();
  if (!text.startsWith("{")) {
    try {
      const bin = atob(text.replace(/\s+/g, ""));
      text = new TextDecoder().decode(Uint8Array.from(bin, (c) => c.charCodeAt(0)));
    } catch {
      return null;
    }
  }
  try {
    const obj = JSON.parse(text) as Record<string, unknown>;
    if (
      typeof obj.project_id === "string" && typeof obj.client_email === "string" &&
      typeof obj.private_key === "string"
    ) {
      return {
        project_id: obj.project_id,
        client_email: obj.client_email,
        private_key: obj.private_key,
        token_uri: typeof obj.token_uri === "string" ? obj.token_uri : undefined,
      };
    }
  } catch {
    // fall through
  }
  return null;
}

// ---------------------------------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------------------------------

export interface FcmMessage {
  token: string;
  data?: Record<string, string>;
  notification?: { title?: string; body?: string };
  android?: {
    priority?: "NORMAL" | "HIGH";
    ttl?: string;
    collapse_key?: string;
    notification?: Record<string, unknown>;
  };
  apns?: { headers?: Record<string, string>; payload?: Record<string, unknown> };
}

export interface AlertPushInput {
  token: string;
  dedupeKey: string;
  title: string;
  body?: string;
  /** Custom data (stringified): type, target, occ, deepLink, actions, channel, group… */
  data?: Record<string, unknown>;
  channelId?: string;
  category?: string;
  threadId?: string;
  sound?: string;
  importance?: Importance | null;
  interruptionLevel?: string;
  relevanceScore?: number;
  /** Remaining lifetime; 0 means "deliver now or never". */
  ttlSeconds: number;
  /** Absolute expiry (epoch seconds) for apns-expiration. */
  expiresAtEpochSeconds?: number;
}

/** apns-collapse-id must be ≤ 64 bytes; dedupe keys are 40-char SHA-1 hex, longer keys are shortened. */
export function collapseId(dedupeKey: string): string {
  if (new TextEncoder().encode(dedupeKey).length <= 64) return dedupeKey;
  let h1 = 0x811c9dc5;
  let h2 = 0x01000193;
  for (let i = 0; i < dedupeKey.length; i++) {
    const c = dedupeKey.charCodeAt(i);
    h1 = Math.imul(h1 ^ c, 16777619) >>> 0;
    h2 = Math.imul(h2 ^ c, 2246822507) >>> 0;
  }
  const hash = h1.toString(16).padStart(8, "0") + h2.toString(16).padStart(8, "0");
  let prefix = dedupeKey.slice(0, 64 - hash.length - 1);
  while (new TextEncoder().encode(prefix).length > 64 - hash.length - 1) prefix = prefix.slice(0, -1);
  return `${prefix}~${hash}`;
}

const ANDROID_PRIORITY: Record<Importance, string> = {
  min: "PRIORITY_MIN",
  low: "PRIORITY_LOW",
  default: "PRIORITY_DEFAULT",
  high: "PRIORITY_HIGH",
  urgent: "PRIORITY_MAX",
};

function stringifyData(data: Record<string, unknown> | undefined): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(data ?? {})) {
    if (v === undefined || v === null) continue;
    out[k] = typeof v === "string" ? v : JSON.stringify(v);
  }
  return out;
}

export function messageSize(message: FcmMessage): number {
  const { token: _token, ...rest } = message;
  return new TextEncoder().encode(JSON.stringify(rest)).length;
}

export function buildAlertMessage(input: AlertPushInput): FcmMessage {
  const ttl = Math.max(0, Math.floor(input.ttlSeconds));
  const cid = collapseId(input.dedupeKey);
  const data = stringifyData({ dk: input.dedupeKey, ...input.data });

  const build = (body: string | undefined): FcmMessage => {
    const androidNotification: Record<string, unknown> = {
      title: input.title,
      tag: input.dedupeKey,
      ...(body ? { body } : {}),
      ...(input.channelId ? { channel_id: input.channelId } : {}),
      ...(input.sound && input.sound !== "none" ? { sound: input.sound } : {}),
      ...(input.importance ? { notification_priority: ANDROID_PRIORITY[input.importance] } : {}),
    };
    const aps: Record<string, unknown> = {
      alert: { title: input.title, ...(body ? { body } : {}) },
      ...(input.sound !== "none"
        ? { sound: input.sound && input.sound !== "default" ? input.sound : "default" }
        : {}),
      ...(input.category ? { category: input.category } : {}),
      ...(input.threadId ? { "thread-id": input.threadId } : {}),
      ...(input.interruptionLevel ? { "interruption-level": input.interruptionLevel } : {}),
      ...(typeof input.relevanceScore === "number" ? { "relevance-score": input.relevanceScore } : {}),
    };
    const headers: Record<string, string> = {
      "apns-push-type": "alert",
      "apns-priority": "10",
      "apns-collapse-id": cid,
    };
    if (input.expiresAtEpochSeconds !== undefined) {
      headers["apns-expiration"] = String(Math.max(0, Math.floor(input.expiresAtEpochSeconds)));
    }
    return {
      token: input.token,
      data,
      android: { priority: "HIGH", ttl: `${ttl}s`, notification: androidNotification },
      apns: { headers, payload: { aps } },
    };
  };

  // Payload budget: shorten the body (never the title / routing data) until the message fits.
  let message = build(input.body);
  let chars = [...(input.body ?? "")];
  while (messageSize(message) > MAX_PAYLOAD_BYTES && chars.length > 0) {
    // The body appears twice (android + apns); a code point takes 1–4 bytes (JSON escapes up to 12).
    const excess = messageSize(message) - MAX_PAYLOAD_BYTES;
    chars = chars.slice(0, Math.max(0, chars.length - Math.max(1, Math.ceil(excess / 8))));
    message = build(chars.length > 0 ? `${chars.join("")}…` : undefined);
  }
  return message;
}

/** Data-only "please sync" message (Android normal priority, iOS background push). */
export function buildSyncMessage(token: string, head: number | string): FcmMessage {
  return {
    token,
    data: { type: "sync", head: String(head) },
    android: { priority: "NORMAL", ttl: "3600s" },
    apns: {
      headers: { "apns-push-type": "background", "apns-priority": "5" },
      payload: { aps: { "content-available": 1 } },
    },
  };
}

// ---------------------------------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------------------------------

export type FcmErrorKind =
  | "unregistered"
  | "invalid_argument"
  | "sender_id_mismatch"
  | "quota_exceeded"
  | "unavailable"
  | "internal"
  | "third_party_auth_error"
  | "unauthenticated"
  | "network_error";

export type FcmSendResult =
  | { ok: true; kind: "ok"; messageId: string }
  | {
    ok: false;
    kind: FcmErrorKind;
    /** The device token must be dropped (never retried). */
    tokenInvalid: boolean;
    retryable: boolean;
    retryAfterSeconds?: number;
    status?: number;
    message?: string;
  };

export function parseRetryAfter(value: string | null, nowMs: number): number | undefined {
  if (!value) return undefined;
  const secs = Number(value);
  if (Number.isFinite(secs)) return Math.max(0, Math.ceil(secs));
  const at = Date.parse(value);
  if (Number.isNaN(at)) return undefined;
  return Math.max(0, Math.ceil((at - nowMs) / 1000));
}

interface FcmErrorBody {
  error?: {
    code?: number;
    status?: string;
    message?: string;
    details?: Array<{ "@type"?: string; errorCode?: string }>;
  };
}

/** Maps an HTTP v1 response (status + JSON body + Retry-After) to a typed result. */
export function mapFcmResponse(
  status: number,
  body: unknown,
  retryAfterHeader: string | null,
  nowMs: number,
): FcmSendResult {
  if (status >= 200 && status < 300) {
    const name = (body as { name?: string } | null)?.name ?? "";
    return { ok: true, kind: "ok", messageId: name };
  }
  const err = (body as FcmErrorBody | null)?.error ?? {};
  const fcmCode = err.details?.find((d) => (d["@type"] ?? "").endsWith("FcmError"))?.errorCode;
  const code = fcmCode ?? err.status ?? "";
  const message = err.message ?? "";
  const retryAfter = parseRetryAfter(retryAfterHeader, nowMs);
  const fail = (
    kind: FcmErrorKind,
    tokenInvalid: boolean,
    retryable: boolean,
    retryAfterSeconds?: number,
  ) => ({
    ok: false as const,
    kind,
    tokenInvalid,
    retryable,
    status,
    message,
    ...(retryAfterSeconds !== undefined ? { retryAfterSeconds } : {}),
  });

  switch (code) {
    case "UNREGISTERED":
    case "NOT_FOUND":
      return fail("unregistered", true, false);
    case "SENDER_ID_MISMATCH":
      return fail("sender_id_mismatch", true, false);
    case "INVALID_ARGUMENT":
      // Invalid token format is reported as INVALID_ARGUMENT too.
      return fail("invalid_argument", /registration token/i.test(message), false);
    case "QUOTA_EXCEEDED":
    case "RESOURCE_EXHAUSTED":
      return fail("quota_exceeded", false, true, Math.max(MIN_QUOTA_RETRY_SECONDS, retryAfter ?? 0));
    case "THIRD_PARTY_AUTH_ERROR":
      return fail("third_party_auth_error", false, true, retryAfter);
    case "UNAVAILABLE":
      return fail("unavailable", false, true, retryAfter);
    case "INTERNAL":
      return fail("internal", false, true, retryAfter);
    case "UNAUTHENTICATED":
      return fail("unauthenticated", false, true, retryAfter);
  }
  if (status === 401) return fail("unauthenticated", false, true, retryAfter);
  if (status === 404) return fail("unregistered", true, false);
  if (status === 429) {
    return fail("quota_exceeded", false, true, Math.max(MIN_QUOTA_RETRY_SECONDS, retryAfter ?? 0));
  }
  if (status >= 500) return fail("unavailable", false, true, retryAfter);
  return fail("invalid_argument", false, false);
}

// ---------------------------------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------------------------------

export interface CachedToken {
  token: string;
  expiresAtMs: number;
}

// Module scope: survives across requests of a warm instance.
const tokenCache = new Map<string, CachedToken>();
const tokenInflight = new Map<string, Promise<CachedToken>>();

export function resetFcmTokenCache(): void {
  tokenCache.clear();
  tokenInflight.clear();
}

export interface PushSender {
  send(message: FcmMessage): Promise<FcmSendResult>;
}

/**
 * Shared token cache across instances (T7.4.06): `private.fcm_token_cache` through service-role RPCs,
 * so a cold instance reuses a token another instance minted instead of signing a new JWT.
 */
export interface FcmTokenStore {
  get(key: string): Promise<CachedToken | null>;
  put(key: string, token: CachedToken): Promise<void>;
}

export interface FcmClientOptions {
  serviceAccount: ServiceAccount;
  fetch?: typeof fetch;
  now?: () => number;
  timeoutMs?: number;
  tokenStore?: FcmTokenStore | null;
  /** FCM endpoint (tests / local E2E point it at a mock); defaults to https://fcm.googleapis.com. */
  baseUrl?: string;
}

export class FcmAuthError extends Error {
  constructor(message: string, readonly status?: number) {
    super(message);
    this.name = "FcmAuthError";
  }
}

export class FcmClient implements PushSender {
  readonly projectId: string;
  private readonly sa: ServiceAccount;
  private readonly fetchFn: typeof fetch;
  private readonly now: () => number;
  private readonly timeoutMs: number;
  private readonly tokenStore: FcmTokenStore | null;
  private readonly baseUrl: string;

  constructor(options: FcmClientOptions) {
    this.sa = options.serviceAccount;
    this.projectId = options.serviceAccount.project_id;
    this.fetchFn = options.fetch ?? fetch;
    this.now = options.now ?? Date.now;
    this.timeoutMs = Math.max(10_000, options.timeoutMs ?? 10_000);
    this.tokenStore = options.tokenStore ?? null;
    this.baseUrl = (options.baseUrl ?? "https://fcm.googleapis.com").replace(/\/+$/, "");
  }

  private get cacheKey(): string {
    return `${this.sa.client_email}|${this.sa.token_uri ?? DEFAULT_TOKEN_URI}`;
  }

  /** OAuth access token, minted at most once per validity window (minus the refresh margin). */
  async accessToken(): Promise<string> {
    const key = this.cacheKey;
    const cached = tokenCache.get(key);
    if (cached && cached.expiresAtMs - TOKEN_REFRESH_MARGIN_MS > this.now()) return cached.token;
    let inflight = tokenInflight.get(key);
    if (!inflight) {
      inflight = this.storedOrMint(key).finally(() => tokenInflight.delete(key));
      tokenInflight.set(key, inflight);
    }
    const fresh = await inflight;
    tokenCache.set(key, fresh);
    return fresh.token;
  }

  invalidateToken(): void {
    tokenCache.delete(this.cacheKey);
    this.skipStoreOnce = true;
  }

  /** Set after a rejected token: the next mint must not reuse the (same) stored token. */
  private skipStoreOnce = false;

  private async storedOrMint(key: string): Promise<CachedToken> {
    if (this.tokenStore && !this.skipStoreOnce) {
      try {
        const stored = await this.tokenStore.get(key);
        if (stored && stored.expiresAtMs - TOKEN_REFRESH_MARGIN_MS > this.now()) return stored;
      } catch {
        // The shared cache is an optimization: fall back to minting.
      }
    }
    this.skipStoreOnce = false;
    const fresh = await this.mint();
    if (this.tokenStore) await this.tokenStore.put(key, fresh).catch(() => {});
    return fresh;
  }

  private async mint(): Promise<CachedToken> {
    const tokenUri = this.sa.token_uri ?? DEFAULT_TOKEN_URI;
    const iat = Math.floor(this.now() / 1000);
    const key = await importPKCS8(this.sa.private_key, "RS256");
    const assertion = await new SignJWT({ scope: FCM_SCOPE })
      .setProtectedHeader({ alg: "RS256", typ: "JWT" })
      .setIssuer(this.sa.client_email)
      .setSubject(this.sa.client_email)
      .setAudience(tokenUri)
      .setIssuedAt(iat)
      .setExpirationTime(iat + 3600)
      .sign(key);
    const res = await this.fetchFn(tokenUri, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
      signal: AbortSignal.timeout(this.timeoutMs),
    });
    if (!res.ok) {
      await res.body?.cancel();
      throw new FcmAuthError(`OAuth token request failed with HTTP ${res.status}`, res.status);
    }
    const json = await res.json() as { access_token?: string; expires_in?: number };
    if (!json.access_token) throw new FcmAuthError("OAuth token response without access_token");
    const expiresIn = typeof json.expires_in === "number" ? json.expires_in : 3600;
    return { token: json.access_token, expiresAtMs: this.now() + expiresIn * 1000 };
  }

  async send(message: FcmMessage): Promise<FcmSendResult> {
    const url = `${this.baseUrl}/v1/projects/${encodeURIComponent(this.projectId)}/messages:send`;
    for (let attempt = 0; attempt < 2; attempt++) {
      let token: string;
      try {
        token = await this.accessToken();
      } catch (err) {
        return {
          ok: false,
          kind: "unauthenticated",
          tokenInvalid: false,
          retryable: true,
          message: err instanceof Error ? err.message : String(err),
        };
      }
      let res: Response;
      try {
        res = await this.fetchFn(url, {
          method: "POST",
          headers: { "Authorization": `Bearer ${token}`, "Content-Type": "application/json" },
          body: JSON.stringify({ message }),
          signal: AbortSignal.timeout(this.timeoutMs),
        });
      } catch (err) {
        return {
          ok: false,
          kind: "network_error",
          tokenInvalid: false,
          retryable: true,
          message: err instanceof Error ? err.message : String(err),
        };
      }
      let body: unknown = null;
      try {
        body = await res.json();
      } catch {
        body = null;
      }
      const result = mapFcmResponse(res.status, body, res.headers.get("retry-after"), this.now());
      // Our OAuth token was rejected (revoked / clock skew): mint a new one once and retry.
      if (!result.ok && result.kind === "unauthenticated" && attempt === 0) {
        this.invalidateToken();
        continue;
      }
      return result;
    }
    return { ok: false, kind: "unauthenticated", tokenInvalid: false, retryable: true };
  }
}

/** FCM sender from FCM_SERVICE_ACCOUNT (endpoint override FCM_BASE_URL), or null when push is not configured. */
export function createFcmSenderFromEnv(tokenStore: FcmTokenStore | null = null): FcmClient | null {
  const sa = parseServiceAccount(readEnv("FCM_SERVICE_ACCOUNT"));
  const baseUrl = readEnv("FCM_BASE_URL") ?? undefined;
  return sa ? new FcmClient({ serviceAccount: sa, tokenStore, baseUrl }) : null;
}
