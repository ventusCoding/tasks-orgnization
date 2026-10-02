// Server-side planning fallback (T7.4.17): a deliberately small port of the Dart planner for users whose
// devices stopped uploading plans. Scope: tasks and build habits with server-expressible fixed
// recurrences; section/global defaults and own rules (`notify_mode`), `relative` and `not_done_by`
// triggers; base reminders only (no nag repeats, quiet hours or caps — devices apply those when they
// come back). Dedupe keys are byte-identical to the Dart planner (sha1(rule|target|occ|0|0)), so a
// returning device's upload replaces these jobs instead of duplicating them.

import { expand, type FixedRule, zonedInstant } from "../_shared/recurrence.ts";

export interface RuleRow {
  id: string;
  target_type: string;
  target_id: string | null;
  section: string;
  is_default: boolean;
  spec: { trigger?: Record<string, unknown>; conditions?: Record<string, unknown> };
}

export interface TaskRow {
  id: string;
  title: string;
  start_local: string;
  duration_minutes: number | null;
  time_zone: string | null;
  is_all_day: boolean;
  recurrence: FixedRule | null;
  notify_mode: string;
  category_id?: string | null;
}

export interface HabitRow {
  id: string;
  name: string;
  goal_type: string;
  target_value: number | null;
  target_op: string;
  schedule: FixedRule | null;
  start_date: string;
  end_date: string | null;
  time_zone: string | null;
  notify_mode: string;
}

export interface FallbackInput {
  user_id: string;
  head_rev: number;
  zone: string;
  locale: string | null;
  rules: RuleRow[];
  tasks: TaskRow[];
  habits: HabitRow[];
  settings?: {
    pausedUntil?: string;
    latenessMinutes?: number;
    dateOnlyDefaultTime?: string;
    perSection?: Record<string, { enabled?: boolean }>;
  };
}

export interface FallbackJob {
  dedupe_key: string;
  target_key: string;
  fire_at: string;
  expires_at: string;
  occurrence_key: string;
  rule_id: string;
  guard: Record<string, unknown>;
  payload: Record<string, unknown>;
}

export const HORIZON_DAYS = 14;
const DEFAULT_LATENESS = 15;

const TEXTS: Record<string, Record<string, (n: number, name: string) => string>> = {
  en: {
    before: (n) => `Starts in ${n} min`,
    now: () => "Starting now",
    after: (n) => `Started ${n} min ago`,
    end: () => "Ends now",
    notDone: (_, name) => `You haven't logged ${name} today`,
    habit: (_, name) => `Time for ${name}`,
  },
  fr: {
    before: (n) => `Commence dans ${n} min`,
    now: () => "Ça commence",
    after: (n) => `Commencé il y a ${n} min`,
    end: () => "Se termine maintenant",
    notDone: (_, name) => `Vous n’avez pas encore noté ${name} aujourd’hui`,
    habit: (_, name) => `C’est l’heure de ${name}`,
  },
  ar: {
    before: (n) => `يبدأ بعد ${n} دقيقة`,
    now: () => "يبدأ الآن",
    after: (n) => `بدأ منذ ${n} دقيقة`,
    end: () => "ينتهي الآن",
    notDone: (_, name) => `لم تسجّل ${name} اليوم`,
    habit: (_, name) => `حان وقت ${name}`,
  },
};

export async function sha1Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-1", new TextEncoder().encode(text));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** `relative:<anchor>` / trigger type — defaults of a more specific level claim their kind. */
function kindKey(trigger: Record<string, unknown> | undefined): string {
  const type = String(trigger?.type ?? "relative");
  return type === "relative" ? `relative:${trigger?.anchor ?? "start"}` : type;
}

/** Section defaults, then global defaults (one rule per trigger kind), plus own rules by notify_mode. */
export function rulesFor(
  rules: RuleRow[],
  target: {
    type: "task" | "habit";
    id: string;
    section: string;
    notifyMode: string;
    categoryId?: string | null;
  },
): RuleRow[] {
  if (target.notifyMode === "off") return [];
  const usesDefaults = target.notifyMode !== "custom";
  const usesOwn = target.notifyMode === "custom" || target.notifyMode === "inherit_plus";
  const out: RuleRow[] = [];
  if (usesDefaults) {
    const claimed = new Set<string>();
    const levels = [
      rules.filter((r) =>
        r.target_type === "category" && r.is_default && r.target_id === target.categoryId &&
        r.section === target.section
      ),
      rules.filter((r) => r.target_type === "section" && r.is_default && r.section === target.section),
      rules.filter((r) => r.target_type === "global" && r.is_default),
    ];
    for (const level of levels) {
      const kinds = new Set<string>();
      for (const r of level) {
        const k = kindKey(r.spec.trigger);
        if (claimed.has(k)) continue;
        kinds.add(k);
        out.push(r);
      }
      kinds.forEach((k) => claimed.add(k));
    }
  }
  if (usesOwn) out.push(...rules.filter((r) => r.target_type === target.type && r.target_id === target.id));
  return out;
}

export interface Occ {
  key: string;
  slot?: Date;
  start?: Date;
  end?: Date;
  periodStart?: Date;
  periodEnd?: Date;
}

const iso = (d: Date) => d.toISOString();
const addMin = (d: Date, m: number) => new Date(d.getTime() + m * 60_000);
const localParts = (d: Date, zone: string) => {
  const f = new Intl.DateTimeFormat("en-CA", {
    timeZone: zone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(d);
  const v = (t: string) => f.find((p) => p.type === t)!.value;
  return { date: `${v("year")}-${v("month")}-${v("day")}`, time: `${v("hour")}:${v("minute")}` };
};
const plusDays = (date: string, n: number) => {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
};

/**
 * Fire instant of [trigger] for an occurrence, or null when the trigger isn't server-planned.
 * [dateOnlyTime]: time used for untimed slots (`dateOnlyDefaultTime`, default 09:00).
 */
export function fireAt(
  trigger: Record<string, unknown>,
  o: Occ,
  zone: string,
  dateOnlyTime = "09:00",
): Date | null {
  const type = String(trigger.type ?? "relative");
  const offset = typeof trigger.offsetMinutes === "number" ? trigger.offsetMinutes : 0;
  const atTime = typeof trigger.atTime === "string" ? trigger.atTime : null;
  if (type === "relative") {
    const anchor = String(trigger.anchor ?? "start");
    const slotBase = o.slot ??
      (o.periodStart
        ? zonedInstant(`${localParts(o.periodStart, zone).date}T${dateOnlyTime}`, zone)
        : undefined);
    const base = anchor === "slot"
      ? slotBase
      : anchor === "start"
      ? o.start ?? o.periodStart
      : anchor === "end"
      ? o.end ?? o.periodEnd
      : anchor === "period_start"
      ? o.periodStart ?? o.start
      : anchor === "period_end"
      ? o.periodEnd ?? o.end
      : undefined;
    if (!base) return null;
    if (typeof trigger.dayOffset === "number" && atTime) {
      const endLike = anchor === "end" || anchor === "period_end";
      const day = localParts(endLike ? addMin(base, -1) : base, zone).date;
      return zonedInstant(`${plusDays(day, trigger.dayOffset)}T${atTime}`, zone);
    }
    return addMin(base, offset);
  }
  if (type === "not_done_by") {
    const anchor = String(trigger.anchor ?? "period_end");
    let base: Date | undefined;
    if (anchor === "end") base = o.end;
    else if (anchor === "time") {
      const day = o.periodStart ?? o.start;
      base = day && atTime ? zonedInstant(`${localParts(day, zone).date}T${atTime}`, zone) : undefined;
    } else base = o.periodEnd ?? o.end;
    return base ? addMin(base, offset) : null;
  }
  return null;
}

function text(locale: string | null, kind: string, n: number, name: string): string {
  const lang = (locale ?? "en").slice(0, 2);
  return (TEXTS[lang] ?? TEXTS.en)[kind](n, name);
}

function bodyFor(
  trigger: Record<string, unknown>,
  isHabit: boolean,
  name: string,
  locale: string | null,
): string {
  if (trigger.type === "not_done_by") return text(locale, "notDone", 0, name);
  if (isHabit) return text(locale, "habit", 0, name);
  const offset = typeof trigger.offsetMinutes === "number" ? trigger.offsetMinutes : 0;
  if (trigger.anchor === "end") return text(locale, "end", 0, name);
  if (offset < 0) return text(locale, "before", -offset, name);
  if (offset > 0) return text(locale, "after", offset, name);
  return text(locale, "now", 0, name);
}

/** Jobs for one user between [now] and now + 14 days. */
export async function planFallback(input: FallbackInput, now: Date): Promise<FallbackJob[]> {
  const settings = input.settings ?? {};
  if (settings.pausedUntil && Date.parse(settings.pausedUntil) > now.getTime() + HORIZON_DAYS * 86_400_000) {
    return [];
  }
  const lateness = settings.latenessMinutes ?? DEFAULT_LATENESS;
  const horizonEnd = new Date(now.getTime() + HORIZON_DAYS * 86_400_000);
  const sectionOn = (s: string) => settings.perSection?.[s]?.enabled !== false;
  const jobs: FallbackJob[] = [];

  const emit = async (
    rule: RuleRow,
    target: {
      type: "task" | "habit";
      id: string;
      name: string;
      section: string;
      guard: (occ: string) => Record<string, unknown>;
    },
    occs: Occ[],
    zone: string,
  ) => {
    const trigger = rule.spec.trigger ?? { type: "relative", anchor: "start" };
    for (const o of occs) {
      const at = fireAt(trigger, o, zone, settings.dateOnlyDefaultTime ?? "09:00");
      if (!at || at <= now || at > horizonEnd) continue;
      if (settings.pausedUntil && at.getTime() < Date.parse(settings.pausedUntil)) continue;
      jobs.push({
        dedupe_key: await sha1Hex(`${rule.id}|${target.id}|${o.key}|0|0`),
        target_key: `${target.type}:${target.id}`,
        fire_at: iso(at),
        expires_at: iso(addMin(at, lateness < 1 ? 1 : lateness)),
        occurrence_key: o.key,
        rule_id: rule.id,
        guard: target.guard(o.key),
        payload: {
          type: "reminder",
          title: target.name,
          body: bodyFor(trigger, target.type === "habit", target.name, input.locale),
          section: target.section,
          channel: `dl.${target.section}.standard.v1`,
          deepLink: target.type === "task"
            ? `/task/${target.id}?occ=${encodeURIComponent(o.key)}`
            : `/habits/${target.id}`,
          latenessMinutes: lateness,
          inbox: true,
          system: true,
        },
      });
    }
  };

  if (sectionOn("planner")) {
    for (const t of input.tasks) {
      const rules = rulesFor(input.rules, {
        type: "task",
        id: t.id,
        section: "planner",
        notifyMode: t.notify_mode,
        categoryId: t.category_id,
      });
      if (rules.length === 0 || t.is_all_day) continue;
      const zone = t.time_zone ?? input.zone;
      const start = t.start_local.slice(0, 16);
      const from = localParts(addMin(now, -24 * 60), zone);
      const to = localParts(addMin(horizonEnd, 24 * 60), zone);
      const keys = t.recurrence
        ? expand(t.recurrence, { start, zone }, `${from.date}T${from.time}`, `${to.date}T${to.time}`, 500)
        : [{ key: start, utc: zonedInstant(start, zone) }];
      if (keys === null) continue; // not server-expressible: the device plans it when it returns
      const occs: Occ[] = keys.map((k) => {
        const s = k.utc ?? zonedInstant(k.key, zone);
        return { key: k.key, start: s, end: addMin(s, t.duration_minutes ?? 0) };
      });
      for (const rule of rules) {
        await emit(
          rule,
          {
            type: "task",
            id: t.id,
            name: t.title,
            section: "planner",
            guard: (occ) => ({ kind: "task_occurrence_open", taskId: t.id, occurrenceKey: occ }),
          },
          occs,
          zone,
        );
      }
    }
  }

  if (sectionOn("habits")) {
    for (const h of input.habits) {
      const rules = rulesFor(input.rules, {
        type: "habit",
        id: h.id,
        section: "habits",
        notifyMode: h.notify_mode,
      });
      if (rules.length === 0 || !h.schedule) continue;
      const zone = h.time_zone ?? input.zone;
      const today = localParts(now, zone).date;
      const timed = (h.schedule.times ?? []).length > 0;
      const found = expand(
        h.schedule,
        { start: timed ? `${h.start_date}T${h.schedule.times![0]}` : h.start_date, zone, allDay: !timed },
        timed ? `${plusDays(today, -1)}T00:00` : plusDays(today, -1),
        timed ? `${plusDays(today, HORIZON_DAYS + 1)}T00:00` : plusDays(today, HORIZON_DAYS + 1),
        200,
      );
      if (found === null) continue; // quota / custom schedules stay with the device
      const occs: Occ[] = found
        .filter((d) => !h.end_date || d.key.slice(0, 10) <= h.end_date)
        .map((d) => {
          const day = d.key.slice(0, 10);
          return {
            key: d.key,
            slot: timed ? d.utc ?? zonedInstant(d.key, zone) : undefined,
            periodStart: zonedInstant(`${day}T00:00`, zone),
            periodEnd: zonedInstant(`${plusDays(day, 1)}T00:00`, zone),
          };
        });
      for (const rule of rules) {
        await emit(
          rule,
          {
            type: "habit",
            id: h.id,
            name: h.name,
            section: "habits",
            guard: (occ) => ({
              kind: "habit_period_open",
              habitId: h.id,
              occurrenceKey: occ,
              goalType: h.goal_type,
              target: h.target_value,
              op: h.target_op,
            }),
          },
          occs,
          zone,
        );
      }
    }
  }
  return jobs.sort((a, b) => a.fire_at.localeCompare(b.fire_at));
}
