// plan-fallback orchestration (T7.4.17): candidates → load → plan → replace, bounded per run.

import type { Logger } from "../_shared/log.ts";
import { type FallbackInput, type FallbackJob, planFallback } from "./planner.ts";

export interface FallbackStore {
  candidates(limit: number): Promise<string[]>;
  load(userId: string): Promise<FallbackInput>;
  replace(
    userId: string,
    sourceRev: number,
    jobs: FallbackJob[],
  ): Promise<{ replaced: number; inserted: number }>;
  heartbeat(name: string, details: Record<string, unknown>): Promise<void>;
}

export interface FallbackSummary {
  users: number;
  planned: number;
  inserted: number;
  failed: number;
}

export async function runFallback(
  store: FallbackStore,
  options: { now?: () => Date; limit?: number; log?: Logger } = {},
): Promise<FallbackSummary> {
  const now = options.now ?? (() => new Date());
  const summary: FallbackSummary = { users: 0, planned: 0, inserted: 0, failed: 0 };
  for (const userId of await store.candidates(options.limit ?? 200)) {
    summary.users++;
    try {
      const input = await store.load(userId);
      const jobs = await planFallback(input, now());
      summary.planned += jobs.length;
      const r = await store.replace(userId, input.head_rev, jobs);
      summary.inserted += r.inserted;
    } catch (err) {
      summary.failed++;
      options.log?.("warn", "plan_fallback.user_failed", {
        error: err instanceof Error ? err.message : String(err),
      });
    }
  }
  await store.heartbeat("plan_fallback", { ...summary }).catch(() => {});
  options.log?.("info", "plan_fallback.done", { ...summary });
  return summary;
}
