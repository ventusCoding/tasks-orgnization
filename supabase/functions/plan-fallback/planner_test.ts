// Fallback planner (T7.4.17): parity with the Dart planner fixtures for the server subset (rule
// resolution + relative / not_done_by fire times, Dart-identical dedupe keys), and full planning from
// rows (recurring task, timed habit, untimed habit, unsupported rules skipped).
import { assert, assertEquals } from "../_shared/test_utils.ts";
import {
  type FallbackInput,
  fireAt,
  type Occ,
  planFallback,
  type RuleRow,
  rulesFor,
  sha1Hex,
} from "./planner.ts";

const root = new URL("../../../app/test/features/notifications/fixtures/planner/", import.meta.url);

interface FixtureRule {
  id: string;
  targetType: string;
  targetId?: string;
  section: string;
  isDefault?: boolean;
  spec: RuleRow["spec"] & Record<string, unknown>;
}
interface FixtureTarget {
  type: string;
  id: string;
  section: string;
  notifyMode?: string;
  categoryId?: string;
  itemKind?: string;
  occurrenceKey: string;
  start?: string;
  end?: string;
  slot?: string;
  periodStart?: string;
  periodEnd?: string;
  timeZone?: string;
}
interface FixtureCase {
  name: string;
  now: string;
  zone: string;
  rules: FixtureRule[];
  targets: FixtureTarget[];
  expected: Array<{ rule: string; target: string; occ?: string; fireAtUtc: string; repeatIdx?: number }>;
  [k: string]: unknown;
}

const SERVER_TRIGGERS = new Set(["relative", "not_done_by"]);
const SERVER_ANCHORS = new Set(["start", "end", "period_start", "period_end", "slot", "time", undefined]);

function supported(c: FixtureCase): boolean {
  const extra = Object.keys(c).filter((k) =>
    !["name", "now", "zone", "rules", "targets", "expected"].includes(k)
  );
  if (extra.length > 0) return false; // settings, quiet hours, mutes, device policies… are device-side
  // Nag profiles repeat on the device; the server plans base reminders only.
  return c.rules.every((r) =>
    (r as { profileId?: string }).profileId !== "nag" &&
    SERVER_TRIGGERS.has(String(r.spec.trigger?.type)) &&
    SERVER_ANCHORS.has(r.spec.trigger?.anchor as string | undefined) &&
    Object.keys(r.spec).every((k) => k === "v" || k === "trigger")
  ) && c.targets.every((t) => t.type === "task" || t.type === "habit");
}

const date = (s?: string) => (s ? new Date(s) : undefined);

for (
  const file of [
    "relative_offsets.json",
    "habits_quit_events_digests.json",
    "dst_and_zones.json",
    "policies.json",
  ]
) {
  const doc = JSON.parse(await Deno.readTextFile(new URL(file, root)));
  const cases = (doc.cases ?? doc) as FixtureCase[];
  Deno.test(`fallback planner parity: ${file}`, async () => {
    let checked = 0;
    for (const c of cases.filter(supported)) {
      const now = new Date(c.now);
      const rules: RuleRow[] = c.rules.map((r) => ({
        id: r.id,
        target_type: r.targetType,
        target_id: r.targetId ?? null,
        section: r.section,
        is_default: r.isDefault ?? ["section", "global", "category"].includes(r.targetType),
        spec: r.spec,
      }));
      const got: string[] = [];
      for (const t of c.targets) {
        const occ: Occ = {
          key: t.occurrenceKey,
          start: date(t.start),
          end: date(t.end),
          slot: date(t.slot),
          periodStart: date(t.periodStart),
          periodEnd: date(t.periodEnd),
        };
        for (
          const r of rulesFor(rules, {
            type: t.type as "task" | "habit",
            id: t.id,
            section: t.section,
            notifyMode: t.notifyMode ?? "inherit",
            categoryId: t.categoryId,
          })
        ) {
          const at = fireAt(r.spec.trigger!, occ, t.timeZone ?? c.zone);
          const horizon = now.getTime() + 14 * 86_400_000;
          if (at && at.getTime() + 15 * 60_000 > now.getTime() && at.getTime() <= horizon) {
            got.push(`${r.id}|${t.id}|${at.toISOString().replace(".000Z", "Z")}`);
          }
        }
      }
      const want = c.expected
        .filter((e) => (e.repeatIdx ?? 0) === 0)
        .map((e) => `${e.rule}|${e.target}|${e.fireAtUtc}`);
      assertEquals(got.sort(), want.sort(), c.name);
      checked++;
    }
    console.log(`${file}: ${checked} cases checked`);
  });
}

Deno.test("dedupe keys equal the Dart planner's sha1(rule|target|occ|0|0)", async () => {
  // dedupeKeyFor(ruleId: 'r', targetId: 't', occurrenceKey: 'o') in planned_notification.dart.
  assertEquals(await sha1Hex("r|t|o|0|0"), "40304e1a36b8b8f78c83866ae1fa0ee13a0201a5");
});

const input = (over: Partial<FallbackInput> = {}): FallbackInput => ({
  user_id: "u",
  head_rev: 10,
  zone: "Europe/Paris",
  locale: "fr",
  rules: [
    {
      id: "r-before",
      target_type: "section",
      target_id: null,
      section: "planner",
      is_default: true,
      spec: { trigger: { type: "relative", anchor: "start", offsetMinutes: -10 } },
    },
    {
      id: "r-slot",
      target_type: "section",
      target_id: null,
      section: "habits",
      is_default: true,
      spec: { trigger: { type: "relative", anchor: "slot", offsetMinutes: 0 } },
    },
  ],
  tasks: [{
    id: "gym",
    title: "Gym",
    start_local: "2026-09-01T08:00:00",
    duration_minutes: 60,
    time_zone: "Europe/Paris",
    is_all_day: false,
    recurrence: { v: 1, type: "fixed", freq: "weekly", interval: 1, byWeekday: [{ day: "TU" }] },
    notify_mode: "inherit",
  }],
  habits: [
    {
      id: "water",
      name: "Eau",
      goal_type: "check",
      target_value: null,
      target_op: "gte",
      schedule: { v: 1, type: "fixed", freq: "daily", interval: 1 },
      start_date: "2026-09-01",
      end_date: null,
      time_zone: null,
      notify_mode: "inherit",
    },
    {
      id: "read",
      name: "Lire",
      goal_type: "check",
      target_value: null,
      target_op: "gte",
      schedule: { v: 1, type: "fixed", freq: "daily", interval: 1, times: ["21:30"] },
      start_date: "2026-09-01",
      end_date: null,
      time_zone: null,
      notify_mode: "inherit",
    },
    {
      id: "gym3",
      name: "Sport",
      goal_type: "check",
      target_value: null,
      target_op: "gte",
      schedule: { v: 1, type: "quota", freq: "weekly", interval: 1 },
      start_date: "2026-09-01",
      end_date: null,
      time_zone: null,
      notify_mode: "inherit",
    },
  ],
  ...over,
});

Deno.test("planFallback: weekly task, untimed and timed habits, unsupported quota skipped", async () => {
  const now = new Date("2026-09-21T10:00:00Z"); // Monday
  const jobs = await planFallback(input(), now);
  const gym = jobs.filter((j) => j.target_key === "task:gym");
  // Tuesdays 22 and 29 Sep, 10 min before 08:00 Paris (06:00Z); 6 Oct is beyond the 14-day horizon.
  assertEquals(gym.map((j) => j.fire_at), ["2026-09-22T05:50:00.000Z", "2026-09-29T05:50:00.000Z"]);
  assertEquals(gym[0].occurrence_key, "2026-09-22T08:00");
  assertEquals(gym[0].payload.body, "Commence dans 10 min");
  assertEquals(gym[0].guard, {
    kind: "task_occurrence_open",
    taskId: "gym",
    occurrenceKey: "2026-09-22T08:00",
  });
  assertEquals(gym[0].dedupe_key, await sha1Hex("r-before|gym|2026-09-22T08:00|0|0"));
  // Untimed habit: date-only default 09:00 Paris; today's 09:00 already passed.
  const water = jobs.filter((j) => j.target_key === "habit:water");
  assertEquals(water[0].fire_at, "2026-09-22T07:00:00.000Z");
  assertEquals(water[0].occurrence_key, "2026-09-22");
  assertEquals(water[0].payload.body, "C’est l’heure de Eau");
  // Timed habit: its slot (21:30 Paris) today is still ahead.
  const read = jobs.filter((j) => j.target_key === "habit:read");
  assertEquals(read[0].fire_at, "2026-09-21T19:30:00.000Z");
  assertEquals(read[0].occurrence_key, "2026-09-21T21:30");
  // Quota schedules are left to the device.
  assert(!jobs.some((j) => j.target_key === "habit:gym3"));
  assert(jobs.every((j) => Date.parse(j.fire_at) <= now.getTime() + 14 * 86_400_000));
});

Deno.test("planFallback honours notify_mode off, disabled sections and a long pause", async () => {
  const now = new Date("2026-09-21T10:00:00Z");
  const off = await planFallback(
    input({ tasks: [{ ...input().tasks[0], notify_mode: "off" }], habits: [] }),
    now,
  );
  assertEquals(off.length, 0);
  const sectionOff = await planFallback(
    input({ settings: { perSection: { habits: { enabled: false } } } }),
    now,
  );
  assert(sectionOff.every((j) => j.target_key.startsWith("task:")));
  const paused = await planFallback(input({ settings: { pausedUntil: "2026-12-31T00:00:00Z" } }), now);
  assertEquals(paused.length, 0);
});
