// Fixed recurrence rules on the server (T7.4.17): Everslot rule JSON (packages/everslot_recurrence)
// → RFC 5545 RRULE text (same mapping as the Dart RRuleCodec) → rrule-temporal expansion in FLOATING
// wall-clock time → our own zone layer (gaps shift forward, overlaps take the earlier instant — the
// Dart engine's rule). Rules the server can't express (quota, after-completion, windows, completion
// counts, clamp overflow, uneven `times`) return null: devices keep planning those.

import { RRuleTemporal } from "./deps.ts";

declare const Temporal: {
  PlainDateTime: {
    from(v: string): {
      toZonedDateTime(zone: string, o: { disambiguation: string }): { epochMilliseconds: number };
    };
  };
};

export interface WeekdaySpec {
  day: string;
  n?: number;
}

export interface FixedRule {
  v?: number;
  type: string;
  freq: string;
  interval?: number;
  count?: number;
  countMode?: string;
  until?: string;
  byWeekday?: WeekdaySpec[];
  byMonthDay?: number[];
  byMonth?: number[];
  byYearDay?: number[];
  byWeekNo?: number[];
  bySetPos?: number[];
  byHour?: number[];
  byMinute?: number[];
  wkst?: string;
  times?: string[];
  window?: unknown;
  monthDayOverflow?: string;
  exdates?: string[];
  rdates?: string[];
}

export interface Anchor {
  /** Wall-clock start `YYYY-MM-DDTHH:mm` (or a date for all-day series). */
  start: string;
  /** IANA zone; null = floating. */
  zone: string | null;
  allDay?: boolean;
}

/** Wall-clock fields of a Temporal value (what the expansion reads). */
export interface WallClock {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
}

export interface Occurrence {
  /** Occurrence key = wall-clock start `YYYY-MM-DDTHH:mm` (date for all-day). */
  key: string;
  /** Instant (null for floating rules: resolved in the viewer's zone by the caller). */
  utc: Date | null;
}

const pad = (n: number, w = 2) => String(n).padStart(w, "0");
const compact = (local: string) => local.replace(/[-:]/g, "") + (local.length === 16 ? "00" : "");

function minutes(t: string): number {
  const [h, m] = t.split(":").map(Number);
  return h * 60 + m;
}

function crossProduct(times: string[]): [number[], number[]] | null {
  const mins = new Set(times.map(minutes));
  const hours = [...new Set([...mins].map((t) => Math.floor(t / 60)))].sort((a, b) => a - b);
  const ms = [...new Set([...mins].map((t) => t % 60))].sort((a, b) => a - b);
  return hours.length * ms.length === mins.size ? [hours, ms] : null;
}

/** RRULE text (floating DTSTART) for [rule], or null when the server can't express it. */
export function toRRule(rule: FixedRule, anchor: Anchor): string | null {
  if (rule.type !== "fixed") return null;
  if (rule.window || rule.countMode === "completions" || rule.monthDayOverflow === "clamp") return null;
  let byHour = rule.byHour ?? [];
  let byMinute = rule.byMinute ?? [];
  if (rule.times && rule.times.length > 0) {
    const cross = crossProduct(rule.times);
    if (!cross) return null;
    [byHour, byMinute] = cross;
  }
  const start = anchor.allDay ? `${anchor.start.slice(0, 10)}T00:00` : anchor.start;
  const parts = [
    `FREQ=${rule.freq.toUpperCase()}`,
    (rule.interval ?? 1) !== 1 ? `INTERVAL=${rule.interval}` : null,
    rule.count != null ? `COUNT=${rule.count}` : null,
    rule.until ? `UNTIL=${compact(rule.until.length === 10 ? `${rule.until}T23:59` : rule.until)}` : null,
    rule.byMonth?.length ? `BYMONTH=${rule.byMonth.join(",")}` : null,
    rule.byWeekNo?.length ? `BYWEEKNO=${rule.byWeekNo.join(",")}` : null,
    rule.byYearDay?.length ? `BYYEARDAY=${rule.byYearDay.join(",")}` : null,
    rule.byMonthDay?.length ? `BYMONTHDAY=${rule.byMonthDay.join(",")}` : null,
    rule.byWeekday?.length
      ? `BYDAY=${rule.byWeekday.map((w) => `${w.n ?? ""}${w.day}`).join(",")}`
      // RFC 5545: a yearly BYWEEKNO without BYDAY means every day of those weeks (rrule-temporal
      // would only keep the DTSTART weekday).
      : rule.byWeekNo?.length && rule.freq === "yearly"
      ? "BYDAY=MO,TU,WE,TH,FR,SA,SU"
      : null,
    byHour.length ? `BYHOUR=${byHour.join(",")}` : null,
    byMinute.length ? `BYMINUTE=${byMinute.join(",")}` : null,
    rule.bySetPos?.length ? `BYSETPOS=${rule.bySetPos.join(",")}` : null,
    rule.wkst && rule.wkst !== "MO" ? `WKST=${rule.wkst}` : null,
  ].filter((p) => p !== null);
  const timed = (k: string) => k.length > 10;
  const exdates = (rule.exdates ?? []).filter(timed);
  // Date-only exdates on a timed series can't be written without changing COUNT semantics.
  if (!anchor.allDay && (rule.exdates ?? []).some((k) => !timed(k)) && rule.count != null) return null;
  const rdates = (rule.rdates ?? []).map((k) => (timed(k) ? k : `${k}T${start.slice(11, 16)}`));
  return [
    `DTSTART:${compact(start)}`,
    `RRULE:${parts.join(";")}`,
    exdates.length ? `EXDATE:${exdates.map(compact).join(",")}` : null,
    rdates.length ? `RDATE:${rdates.map(compact).join(",")}` : null,
  ].filter((l) => l !== null).join("\n");
}

/** Instant of a wall-clock time in [zone]: gaps move forward, overlaps take the earlier offset. */
export function zonedInstant(local: string, zone: string): Date {
  const pdt = Temporal.PlainDateTime.from(local.length === 16 ? `${local}:00` : local);
  return new Date(pdt.toZonedDateTime(zone, { disambiguation: "compatible" }).epochMilliseconds);
}

function keyOf(
  d: { year: number; month: number; day: number; hour: number; minute: number },
  allDay: boolean,
) {
  const date = `${pad(d.year, 4)}-${pad(d.month)}-${pad(d.day)}`;
  return allDay ? date : `${date}T${pad(d.hour)}:${pad(d.minute)}`;
}

/**
 * Occurrences overlapping the wall-clock range [fromLocal, toLocal) — starts in range, or started up to
 * [durationMinutes] before it and still running — keys `YYYY-MM-DDTHH:mm`, or null when the rule is not
 * server-expressible. Expansion is capped at [limit] occurrences.
 */
export function expand(
  rule: FixedRule,
  anchor: Anchor,
  fromLocal: string,
  toLocal: string,
  limit = 2000,
  durationMinutes = 0,
): Occurrence[] | null {
  const text = toRRule(rule, anchor);
  if (text === null) return null;
  const rr = new RRuleTemporal({ rruleString: text, maxIterations: 100_000 });
  const allDay = anchor.allDay === true;
  const dateOnlyEx = new Set((rule.exdates ?? []).filter((k) => k.length === 10));
  const out: Occurrence[] = [];
  const toFloat = (local: string) => new Date(`${local.length === 10 ? `${local}T00:00` : local}:00Z`);
  // Floating values are interpreted as UTC by the library: between() in that frame = wall clock.
  const from = new Date(toFloat(fromLocal).getTime() - Math.max(0, durationMinutes - 1) * 60_000);
  const hits = rr.between(from, new Date(toFloat(toLocal).getTime() - 1), true) as unknown as WallClock[];
  for (const z of hits) {
    const key = keyOf(z, allDay);
    if (dateOnlyEx.has(key.slice(0, 10))) continue;
    out.push({ key, utc: anchor.zone && !allDay ? zonedInstant(key, anchor.zone) : null });
    if (out.length >= limit) break;
  }
  return out;
}
