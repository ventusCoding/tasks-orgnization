// Background work: `EdgeRuntime.waitUntil` on the hosted/local Edge runtime, detached promise elsewhere
// (plain Deno, tests). Callers answer immediately (pg_net times out after a few seconds).

type EdgeRuntimeLike = { waitUntil?: (promise: Promise<unknown>) => void };

export function runInBackground(
  task: () => Promise<unknown>,
  onError: (err: unknown) => void,
): "wait_until" | "detached" {
  const promise = (async () => {
    try {
      await task();
    } catch (err) {
      onError(err);
    }
  })();
  const runtime = (globalThis as { EdgeRuntime?: EdgeRuntimeLike }).EdgeRuntime;
  if (runtime?.waitUntil) {
    runtime.waitUntil(promise);
    return "wait_until";
  }
  return "detached";
}

/** Runs `fn` over `items` with at most `limit` promises in flight; results keep the input order. */
export async function mapWithConcurrency<T, R>(
  items: readonly T[],
  limit: number,
  fn: (item: T, index: number) => Promise<R>,
): Promise<R[]> {
  const results = new Array<R>(items.length);
  let next = 0;
  const workers = Array.from({ length: Math.max(1, Math.min(limit, items.length)) }, async () => {
    while (next < items.length) {
      const i = next++;
      results[i] = await fn(items[i], i);
    }
  });
  await Promise.all(workers);
  return results;
}
