// Structured JSON logs without PII: counts, ids and codes only. Sensitive keys are redacted.

export type LogLevel = "debug" | "info" | "warn" | "error";

const SENSITIVE_KEY =
  /token|secret|authorization|password|private_key|apikey|email|title|body|content|payload|assertion/i;

export function redact(value: unknown, depth = 0): unknown {
  if (depth > 4 || value === null || typeof value !== "object") return value;
  if (Array.isArray(value)) return value.map((v) => redact(v, depth + 1));
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
    // Counts and flags stay readable (e.g. invalidTokens: 2); strings/objects under sensitive keys do not.
    const harmless = typeof v === "number" || typeof v === "boolean" || v === null;
    out[k] = SENSITIVE_KEY.test(k) && !harmless ? "[redacted]" : redact(v, depth + 1);
  }
  return out;
}

export function log(level: LogLevel, event: string, fields: Record<string, unknown> = {}): void {
  const line = JSON.stringify({
    ts: new Date().toISOString(),
    level,
    event,
    ...(redact(fields) as Record<string, unknown>),
  });
  if (level === "error") console.error(line);
  else if (level === "warn") console.warn(line);
  else console.log(line);
}

export type Logger = (level: LogLevel, event: string, fields?: Record<string, unknown>) => void;
