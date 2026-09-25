// Test-only helpers (never imported by function entry points).

export {
  assert,
  assertEquals,
  assertExists,
  assertFalse,
  assertMatch,
  assertRejects,
  assertStringIncludes,
} from "jsr:@std/assert@1.0.19";

import type { ServiceAccount } from "./fcm.ts";
import type { ClaimedJob, DispatchDevice } from "./types.ts";

/** A throwaway RSA service account (generated per run — no key material in the repo). */
export async function makeServiceAccount(): Promise<ServiceAccount> {
  const { privateKey } = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", privateKey));
  let bin = "";
  for (const b of pkcs8) bin += String.fromCharCode(b);
  const body = btoa(bin).match(/.{1,64}/g)!.join("\n");
  return {
    project_id: "everslot-test",
    client_email: "fcm-sender@everslot-test.iam.gserviceaccount.com",
    private_key: `-----BEGIN PRIVATE KEY-----\n${body}\n-----END PRIVATE KEY-----\n`,
  };
}

export interface RecordedCall {
  url: string;
  init?: RequestInit;
}

/** fetch mock: `handler` returns the Response for each call; calls are recorded. */
export function mockFetch(
  handler: (url: string, init: RequestInit | undefined, n: number) => Response | Promise<Response>,
) {
  const calls: RecordedCall[] = [];
  const fn = ((input: string | URL | Request, init?: RequestInit) => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
    calls.push({ url, init });
    return Promise.resolve(handler(url, init, calls.length));
  }) as typeof fetch;
  return { fetch: fn, calls };
}

export function jsonResponse(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...headers },
  });
}

export function fcmError(status: number, code: string, message = "error", errorCode?: string): Response {
  return jsonResponse({
    error: {
      code: status,
      status: code,
      message,
      details: errorCode
        ? [{ "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError", errorCode }]
        : [],
    },
  }, status);
}

export const NOW = new Date("2026-09-22T10:00:00Z");

export function makeJob(overrides: Partial<ClaimedJob> = {}): ClaimedJob {
  return {
    id: "00000000-0000-4000-8000-0000000000a1",
    user_id: "00000000-0000-4000-8000-0000000000b1",
    dedupe_key: "3f786850e387550fdab836ed7e6dc881de23001b",
    target_key: "task:00000000-0000-4000-8000-0000000000c1",
    fire_at: "2026-09-22T10:00:00Z",
    expires_at: "2026-09-22T11:00:00Z",
    payload: {
      title: "Gym",
      body: "Starts in 10 min",
      type: "reminder",
      section: "planner",
      channel: "planner_default",
    },
    guard: { kind: "always" },
    source_rev: 100,
    rule_id: "00000000-0000-4000-8000-0000000000e1",
    occurrence_key: "2026-09-22T10:10",
    target_devices: null,
    planned_by_device: null,
    importance: "default",
    status: "claimed",
    attempts: 0,
    sent_device_ids: [],
    ...overrides,
  };
}

export function makeDevice(overrides: Partial<DispatchDevice> = {}): DispatchDevice {
  return {
    id: "00000000-0000-4000-8000-0000000000d1",
    platform: "android",
    push_token: "token-d1",
    push_token_updated_at: "2026-09-20T10:00:00Z",
    push_enabled: true,
    local_notifications_enabled: true,
    local_coverage_until: null,
    schedule_rev: null,
    capabilities: { exactAlarm: true },
    local_repeating_rules: null,
    last_seen_at: "2026-09-22T09:00:00Z",
    revoked_at: null,
    ...overrides,
  };
}
