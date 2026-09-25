import {
  buildAlertMessage,
  buildSyncMessage,
  collapseId,
  FCM_SCOPE,
  FcmClient,
  mapFcmResponse,
  MAX_PAYLOAD_BYTES,
  messageSize,
  parseRetryAfter,
  parseServiceAccount,
  resetFcmTokenCache,
} from "./fcm.ts";
import {
  assert,
  assertEquals,
  assertFalse,
  fcmError,
  jsonResponse,
  makeServiceAccount,
  mockFetch,
} from "./test_utils.ts";

const TOKEN_URL = "https://oauth2.googleapis.com/token";

function decodeJwtPayload(jwt: string): Record<string, unknown> {
  const part = jwt.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
  return JSON.parse(atob(part + "=".repeat((4 - part.length % 4) % 4)));
}

function fcmFetch(fcmResponses: Array<() => Response>) {
  let fcmCalls = 0;
  let mints = 0;
  const mock = mockFetch((url) => {
    if (url === TOKEN_URL) {
      mints++;
      return jsonResponse({ access_token: `oauth-${mints}`, expires_in: 3600, token_type: "Bearer" });
    }
    const next = fcmResponses[Math.min(fcmCalls, fcmResponses.length - 1)];
    fcmCalls++;
    return next();
  });
  return { ...mock, mints: () => mints, fcmCalls: () => fcmCalls };
}

const sampleMessage = buildSyncMessage("device-token", 42);

Deno.test("parseServiceAccount accepts raw JSON and base64, rejects garbage", async () => {
  const sa = await makeServiceAccount();
  const raw = JSON.stringify(sa);
  assertEquals(parseServiceAccount(raw)?.client_email, sa.client_email);
  const b64 = btoa(String.fromCharCode(...new TextEncoder().encode(raw)));
  assertEquals(parseServiceAccount(b64)?.project_id, "everslot-test");
  assertEquals(parseServiceAccount(undefined), null);
  assertEquals(parseServiceAccount(""), null);
  assertEquals(parseServiceAccount("not base64 !!"), null);
  assertEquals(parseServiceAccount(JSON.stringify({ project_id: "x" })), null);
});

Deno.test("OAuth token is minted once (service-account JWT) and cached across sends", async () => {
  resetFcmTokenCache();
  const sa = await makeServiceAccount();
  const f = fcmFetch([() => jsonResponse({ name: "projects/everslot-test/messages/1" })]);
  const client = new FcmClient({
    serviceAccount: sa,
    fetch: f.fetch,
    now: () => Date.parse("2026-09-22T10:00:00Z"),
  });

  const r1 = await client.send(sampleMessage);
  const r2 = await client.send(sampleMessage);
  assert(r1.ok && r2.ok);
  assertEquals(f.mints(), 1);

  const tokenCall = f.calls.find((c) => c.url === TOKEN_URL)!;
  const form = new URLSearchParams(String(tokenCall.init?.body));
  assertEquals(form.get("grant_type"), "urn:ietf:params:oauth:grant-type:jwt-bearer");
  const claims = decodeJwtPayload(form.get("assertion")!);
  assertEquals(claims.iss, sa.client_email);
  assertEquals(claims.aud, TOKEN_URL);
  assertEquals(claims.scope, FCM_SCOPE);
  assertEquals((claims.exp as number) - (claims.iat as number), 3600);

  const send = f.calls.find((c) => c.url.includes("fcm.googleapis.com"))!;
  assertEquals(send.url, "https://fcm.googleapis.com/v1/projects/everslot-test/messages:send");
  assertEquals((send.init?.headers as Record<string, string>)["Authorization"], "Bearer oauth-1");
  assertEquals(JSON.parse(String(send.init?.body)).message.token, "device-token");
});

Deno.test("OAuth token is refreshed ~5 minutes before expiry", async () => {
  resetFcmTokenCache();
  const sa = await makeServiceAccount();
  let now = Date.parse("2026-09-22T10:00:00Z");
  const f = fcmFetch([() => jsonResponse({ name: "m" })]);
  const client = new FcmClient({ serviceAccount: sa, fetch: f.fetch, now: () => now });
  await client.send(sampleMessage);
  now += 54 * 60 * 1000; // 54 min: still > 5 min left
  await client.send(sampleMessage);
  assertEquals(f.mints(), 1);
  now += 2 * 60 * 1000; // 56 min: inside the refresh margin
  await client.send(sampleMessage);
  assertEquals(f.mints(), 2);
});

Deno.test("an UNAUTHENTICATED answer re-mints the OAuth token and retries once", async () => {
  resetFcmTokenCache();
  const sa = await makeServiceAccount();
  const f = fcmFetch([
    () => fcmError(401, "UNAUTHENTICATED", "Request had invalid authentication credentials."),
    () => jsonResponse({ name: "projects/everslot-test/messages/2" }),
  ]);
  const client = new FcmClient({ serviceAccount: sa, fetch: f.fetch });
  const r = await client.send(sampleMessage);
  assert(r.ok);
  assertEquals(f.mints(), 2);
  assertEquals(f.fcmCalls(), 2);
});

Deno.test("error mapping covers every FCM error code", () => {
  const now = Date.parse("2026-09-22T10:00:00Z");
  const map = (
    status: number,
    code: string,
    msg = "x",
    errorCode?: string,
    retryAfter: string | null = null,
  ) => {
    const body = {
      error: {
        code: status,
        status: code,
        message: msg,
        details: errorCode
          ? [{ "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError", errorCode }]
          : [],
      },
    };
    return mapFcmResponse(status, body, retryAfter, now);
  };

  const unregistered = map(404, "NOT_FOUND", "Requested entity was not found.", "UNREGISTERED");
  assert(
    !unregistered.ok && unregistered.kind === "unregistered" && unregistered.tokenInvalid &&
      !unregistered.retryable,
  );

  const badToken = map(
    400,
    "INVALID_ARGUMENT",
    "The registration token is not a valid FCM registration token",
    "INVALID_ARGUMENT",
  );
  assert(!badToken.ok && badToken.kind === "invalid_argument" && badToken.tokenInvalid);
  const badPayload = map(400, "INVALID_ARGUMENT", "Invalid JSON payload received.", "INVALID_ARGUMENT");
  assert(!badPayload.ok && !badPayload.tokenInvalid && !badPayload.retryable);

  const mismatch = map(403, "PERMISSION_DENIED", "SenderId mismatch", "SENDER_ID_MISMATCH");
  assert(!mismatch.ok && mismatch.kind === "sender_id_mismatch" && mismatch.tokenInvalid);

  const quota = map(429, "RESOURCE_EXHAUSTED", "quota", "QUOTA_EXCEEDED", "120");
  assert(!quota.ok && quota.kind === "quota_exceeded" && quota.retryable && quota.retryAfterSeconds === 120);
  const quotaShort = map(429, "RESOURCE_EXHAUSTED", "quota", "QUOTA_EXCEEDED", "5");
  assert(
    !quotaShort.ok && quotaShort.retryAfterSeconds === 60,
    "Retry-After is at least 60 s for quota errors",
  );

  const unavailable = map(503, "UNAVAILABLE", "try later", "UNAVAILABLE", "30");
  assert(
    !unavailable.ok && unavailable.kind === "unavailable" && unavailable.retryable &&
      unavailable.retryAfterSeconds === 30,
  );
  const internal = map(500, "INTERNAL", "boom", "INTERNAL");
  assert(!internal.ok && internal.kind === "internal" && internal.retryable && !internal.tokenInvalid);
  const apns = map(
    401,
    "UNAUTHENTICATED",
    "Auth error from APNS or Web Push Service",
    "THIRD_PARTY_AUTH_ERROR",
  );
  assert(!apns.ok && apns.kind === "third_party_auth_error" && apns.retryable && !apns.tokenInvalid);
  const gateway = mapFcmResponse(502, null, null, now);
  assert(!gateway.ok && gateway.kind === "unavailable" && gateway.retryable);

  const ok = mapFcmResponse(200, { name: "projects/p/messages/9" }, null, now);
  assert(ok.ok && ok.messageId === "projects/p/messages/9");
});

Deno.test("network errors are retryable", async () => {
  resetFcmTokenCache();
  const sa = await makeServiceAccount();
  const mock = mockFetch((url) => {
    if (url === TOKEN_URL) return jsonResponse({ access_token: "t", expires_in: 3600 });
    throw new TypeError("connection reset");
  });
  const r = await new FcmClient({ serviceAccount: sa, fetch: mock.fetch }).send(sampleMessage);
  assert(!r.ok && r.kind === "network_error" && r.retryable);
});

Deno.test("parseRetryAfter handles seconds and HTTP dates", () => {
  const now = Date.parse("2026-09-22T10:00:00Z");
  assertEquals(parseRetryAfter("90", now), 90);
  assertEquals(parseRetryAfter("Tue, 22 Sep 2026 10:02:00 GMT", now), 120);
  assertEquals(parseRetryAfter(null, now), undefined);
  assertEquals(parseRetryAfter("soon", now), undefined);
});

Deno.test("alert message: tag and apns-collapse-id = dedupe key, TTL and apns-expiration", () => {
  const msg = buildAlertMessage({
    token: "tok",
    dedupeKey: "3f786850e387550fdab836ed7e6dc881de23001b",
    title: "Gym",
    body: "Starts in 10 min",
    data: { type: "reminder", target: "task:1", actions: "done,snooze" },
    channelId: "planner_default",
    importance: "high",
    interruptionLevel: "time-sensitive",
    ttlSeconds: 600,
    expiresAtEpochSeconds: 1790071800,
  });
  assertEquals(msg.android?.notification?.tag, "3f786850e387550fdab836ed7e6dc881de23001b");
  assertEquals(msg.android?.notification?.channel_id, "planner_default");
  assertEquals(msg.android?.notification?.notification_priority, "PRIORITY_HIGH");
  assertEquals(msg.android?.ttl, "600s");
  assertEquals(msg.android?.priority, "HIGH");
  assertEquals(msg.apns?.headers?.["apns-collapse-id"], "3f786850e387550fdab836ed7e6dc881de23001b");
  assertEquals(msg.apns?.headers?.["apns-expiration"], "1790071800");
  assertEquals(msg.apns?.headers?.["apns-push-type"], "alert");
  assertEquals((msg.apns?.payload?.aps as Record<string, unknown>)["interruption-level"], "time-sensitive");
  assertEquals(msg.data?.dk, "3f786850e387550fdab836ed7e6dc881de23001b");
  assertEquals(msg.data?.type, "reminder");
});

Deno.test("payload budget: worst-case Arabic body is truncated under 4 KB", () => {
  const body = "تذكير طويل جدا ".repeat(400);
  const msg = buildAlertMessage({
    token: "t",
    dedupeKey: "k".repeat(40),
    title: "مراجعة أسبوعية",
    body,
    ttlSeconds: 60,
  });
  assert(messageSize(msg) <= MAX_PAYLOAD_BYTES, `size ${messageSize(msg)}`);
  const truncated = String(msg.android?.notification?.body);
  assert(truncated.endsWith("…"));
  assert(truncated.length > 100, "keeps as much of the body as fits");
  assertEquals(
    msg.apns?.payload?.aps && (msg.apns.payload.aps as { alert: { body: string } }).alert.body,
    truncated,
  );
});

Deno.test("collapse ids never exceed 64 bytes", () => {
  assertEquals(collapseId("short"), "short");
  const long = collapseId("x".repeat(100));
  assert(new TextEncoder().encode(long).length <= 64);
  assertFalse(long === collapseId("x".repeat(99) + "y"));
});

Deno.test("sync message is data-only (Android normal priority, iOS background)", () => {
  const msg = buildSyncMessage("tok", 7);
  assertEquals(msg.data, { type: "sync", head: "7" });
  assertEquals(msg.notification, undefined);
  assertEquals(msg.android?.priority, "NORMAL");
  assertEquals(msg.apns?.headers?.["apns-push-type"], "background");
  assertEquals(msg.apns?.headers?.["apns-priority"], "5");
  assertEquals((msg.apns?.payload?.aps as Record<string, unknown>)["content-available"], 1);
});
