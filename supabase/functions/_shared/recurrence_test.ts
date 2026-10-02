// Parity of the server recurrence layer with the shared Dart fixtures (T7.4.17): every fixed-rule case
// the server can express must produce exactly the Dart engine's keys (and instants, when given).
import { RRuleTemporal } from "./deps.ts";
import { expand, type FixedRule, type WallClock } from "./recurrence.ts";
import { assertEquals } from "./test_utils.ts";

const root = new URL("../../../fixtures/recurrence/", import.meta.url);

interface Case {
  name: string;
  rule: FixedRule;
  anchor: { start: string; zone: string | null; allDay?: boolean };
  evalZone: string | null;
  range: { from: string; to: string };
  expectedKeys: string[];
  expectedUtc?: string[];
  limit?: number;
  durationMinutes?: number;
}

const files = [
  "calendar_rules.json",
  "rfc5545_examples.json",
  "dst_zones.json",
  "bounds_sets.json",
  "subdaily_windows.json",
];

for (const file of files) {
  const cases = JSON.parse(await Deno.readTextFile(new URL(file, root))) as Case[];
  Deno.test(`recurrence parity: ${file}`, () => {
    let checked = 0;
    let skipped = 0;
    for (const c of cases) {
      if (c.evalZone) {
        skipped++;
        continue;
      }
      const got = expand(c.rule, c.anchor, c.range.from, c.range.to, c.limit ?? 5000, c.durationMinutes ?? 0);
      if (got === null) {
        skipped++;
        continue;
      }
      assertEquals(got.map((o) => o.key), c.expectedKeys, c.name);
      if (c.expectedUtc) {
        assertEquals(got.map((o) => o.utc!.toISOString().replace(":00.000Z", "Z")), c.expectedUtc, c.name);
      }
      checked++;
    }
    console.log(`${file}: ${checked} checked, ${skipped} not server-expressible / viewer-zone`);
  });
}

Deno.test("expansions equal the Dart codec's RFC 5545 texts (rrule_pairs.json)", async () => {
  const doc = JSON.parse(await Deno.readTextFile(new URL("rrule/rrule_pairs.json", root)));
  const pairs = (doc.cases ?? doc) as Array<
    { name: string; text: string; rule: FixedRule; anchor: Case["anchor"] }
  >;
  let checked = 0;
  for (const p of pairs) {
    // RFC 5545 forces a non-matching DTSTART into the set; rrule-temporal (like Everslot) does not,
    // so the import-convention pairs can't be compared through the library.
    if (p.anchor.allDay || p.name.startsWith("non-matching") || !p.text?.startsWith("DTSTART")) continue;
    const from = p.anchor.start;
    const year = Number(from.slice(0, 4));
    const to = `${year + 2}${from.slice(4)}`;
    const ours = expand(p.rule, p.anchor, from, to, 40);
    if (ours === null) continue;
    const theirs = (new RRuleTemporal({ rruleString: p.text }).all((_: unknown, i: number) =>
      i < 40
    ) as unknown as WallClock[])
      .map((z) =>
        `${z.year}-${String(z.month).padStart(2, "0")}-${String(z.day).padStart(2, "0")}T${
          String(z.hour).padStart(2, "0")
        }:${String(z.minute).padStart(2, "0")}`
      )
      .filter((k) =>
        k >= from && k < to
      );
    assertEquals(ours.map((o) => o.key), theirs, p.name);
    checked++;
  }
  console.log(`rrule pairs: ${checked} checked`);
});
