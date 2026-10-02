import { assertEquals } from "../_shared/test_utils.ts";
import { createHandler } from "./handler.ts";
import type { FallbackInput } from "./planner.ts";
import { type FallbackStore, runFallback } from "./run.ts";

const userInput = (id: string): FallbackInput => ({
  user_id: id,
  head_rev: 42,
  zone: "UTC",
  locale: "en",
  rules: [{
    id: "r",
    target_type: "section",
    target_id: null,
    section: "planner",
    is_default: true,
    spec: { trigger: { type: "relative", anchor: "start", offsetMinutes: 0 } },
  }],
  tasks: [{
    id: `t-${id}`,
    title: "Standup",
    start_local: "2026-09-01T09:00:00",
    duration_minutes: 15,
    time_zone: "UTC",
    is_all_day: false,
    recurrence: { v: 1, type: "fixed", freq: "daily", interval: 1 },
    notify_mode: "inherit",
  }],
  habits: [],
});

function store(failFor = "") {
  const replaced: Array<{ user: string; rev: number; count: number }> = [];
  const beats: string[] = [];
  const s: FallbackStore = {
    candidates: () => Promise.resolve(["a", "b"]),
    load: (u) => (u === failFor ? Promise.reject(new Error("boom")) : Promise.resolve(userInput(u))),
    replace: (user, rev, jobs) => {
      replaced.push({ user, rev, count: jobs.length });
      return Promise.resolve({ replaced: 0, inserted: jobs.length });
    },
    heartbeat: (name) => {
      beats.push(name);
      return Promise.resolve();
    },
  };
  return { s, replaced, beats };
}

Deno.test("runFallback plans every candidate from its sync head and isolates failures", async () => {
  const { s, replaced, beats } = store("b");
  const summary = await runFallback(s, { now: () => new Date("2026-09-21T10:00:00Z") });
  assertEquals(summary.users, 2);
  assertEquals(summary.failed, 1);
  // 14 days of 09:00 stand-ups starting tomorrow (today's already passed).
  assertEquals(replaced, [{ user: "a", rev: 42, count: 14 }]);
  assertEquals(summary.inserted, 14);
  assertEquals(beats, ["plan_fallback"]);
});

Deno.test("plan-fallback handler: cron secret, 202 and background run", async () => {
  const started: string[] = [];
  const handler = createHandler({
    isAuthorized: (req) => req.headers.get("x-cron-secret") === "s",
    createStore: () => store().s,
    background: (task) => {
      started.push("run");
      void task();
      return "wait_until";
    },
  });
  const denied = await handler(new Request("http://x/plan-fallback", { method: "POST", body: "{}" }));
  assertEquals(denied.status, 401);
  await denied.body?.cancel();
  const ok = await handler(
    new Request("http://x/plan-fallback", { method: "POST", headers: { "x-cron-secret": "s" }, body: "{}" }),
  );
  assertEquals(ok.status, 202);
  assertEquals((await ok.json()).accepted, true);
  assertEquals(started, ["run"]);
});
