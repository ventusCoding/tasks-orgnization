// Typed error responses: every failure is `{"error": {"code": "...", "message": "..."}}`.

import { corsHeaders } from "./cors.ts";
import { log } from "./log.ts";

export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "HttpError";
  }
}

export const badRequest = (message: string, details?: Record<string, unknown>) =>
  new HttpError(400, "bad_request", message, details);
export const unauthorized = (message = "Missing or invalid credentials") =>
  new HttpError(401, "unauthorized", message);
export const forbidden = (code: string, message: string) => new HttpError(403, code, message);
export const methodNotAllowed = (allowed: string[]) =>
  new HttpError(405, "method_not_allowed", `Use ${allowed.join(", ")}`);
export const notConfigured = (what: string) =>
  new HttpError(503, "not_configured", `${what} is not configured on this project`);

export function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json", ...headers },
  });
}

/** Converts any thrown value into a response without leaking internals. */
export function errorResponse(err: unknown, fn = "edge"): Response {
  if (err instanceof HttpError) {
    return json(
      { error: { code: err.code, message: err.message, ...(err.details ? { details: err.details } : {}) } },
      err.status,
    );
  }
  log("error", `${fn}.unhandled`, { error: err instanceof Error ? err.message : String(err) });
  return json({ error: { code: "internal_error", message: "Unexpected error" } }, 500);
}

export function assertMethod(req: Request, allowed: string[]): void {
  if (!allowed.includes(req.method)) throw methodNotAllowed(allowed);
}
