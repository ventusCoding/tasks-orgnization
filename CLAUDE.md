# CLAUDE.md — Everslot

**Everslot** (*own every slot of your day*) is a Flutter + Supabase personal organizer for iOS & Android:
**Plan** (week table 7 days × time slots of 1 min–24 h, day list, and more views; tasks with fully free
recurrence), **Lists** (Keep-like checklists with infinitely nested items, statuses
todo/ongoing/waiting/blocked/completed with reason notes, image/file attachments), **Habits** (build
habits + quit trackers), **Insights** (super-detailed stats per item and per section) and fully
configurable **notifications** (in-app inbox + local + Firebase push).

## Source of truth — read before coding

| Doc | Use it for |
|---|---|
| `docs/README.md` | Roadmap, milestones, task-file conventions, file index, glossary |
| `docs/architecture.md` | Stack, layers, data model (SQL), sync, engines, notification pipeline, ADRs |
| `docs/tasks_section_<S>_<SS>_<name>.md` | Dev tasks `T<S>.<SS>.<NN>` with acceptance criteria & tests |
| `docs/dev_patterns.md` | How code is written here (providers, SyncWriter, l10n parts, tests) |
| `docs/guide.md` | Install, configure (Supabase/Firebase placeholders) and run |

Before implementing a task: read the task, its dependencies, and the `arch §` sections it cites.
If code and docs disagree, stop and reconcile — update the docs in the same change (ADR entry for
design changes). Never renumber task IDs.

## Workflow per dev task

1. Pick the next unchecked task in roadmap order (all **P0** in file order → all **P1** → **P2**) unless
   the user names one. Section 9.1 P0 test-infrastructure tasks are done right after the 1.x/2.x tasks they cover.
2. Confirm its dependencies are done (same-file IDs, cross-file `[S.SS]` subsections). If one lives in a
   later file and isn't done, implement that dependency first (see `docs/README.md` §4).
3. Implement the smallest complete slice: domain → data → application → presentation, with the tests
   the task lists.
4. Run format, analyze, tests (below) — all green, no skipped tests.
5. Tick the task in the file's **Progress** list; add a one-line `**Notes:**` under the task for
   decisions or deviations.
6. Report: what changed, how it was verified, what's next.

## Toolchain facts (verified 2026-09-22 — see `arch §3`)

- **Flutter 3.47.5 / Dart 3.13.4** pinned with FVM (`.fvmrc`) — always run `fvm flutter` / `fvm dart`.
  The machine had 3.38.9: upgrade first (T1.1.02). Many packages require Dart ≥ 3.13.
- Widgets come from the **`material_ui` / `cupertino_ui` packages** (built-in copies are frozen/deprecated):
  `import 'package:material_ui/material_ui.dart';` in new code.
- iOS: min 15, **UIScene lifecycle** (mandatory with Xcode 27), Swift Package Manager. Android: minSdk 24,
  target 36 / compile 37, Java 17.
- Supabase: Postgres 17, **publishable key** (`sb_publishable_…`) in the app, **secret key** only in Edge
  Functions; Edge runtime is **Deno 2.1-compatible** (local Deno is newer) — pinned `npm:`/`jsr:` imports,
  no committed Deno lockfile v5, verify with `supabase functions serve`.
- SQLite comes from `sqlite3` build hooks — never add `sqlite3_flutter_libs`. `riverpod_lint` is an
  analyzer plugin (`plugins:`), not `custom_lint`. Patrol tests live in `app/patrol_test/`.

## Commands (once scaffolded — see tasks 1.1/1.2)

```bash
fvm flutter pub get                 # workspace root (pub workspaces)
melos run gen                       # build_runner (Drift only)
melos run l10n                      # merge ARB parts + gen-l10n
melos run analyze                   # dart analyze --fatal-infos across packages
melos run test                      # dart/flutter tests for all packages
melos run format                    # dart format .
cd app && fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
supabase start                      # local stack (Docker)
supabase db reset                   # re-apply migrations + seed locally
supabase migration new <name>       # new SQL migration in supabase/migrations
supabase test db                    # pgTAP tests in supabase/tests/database
supabase functions serve            # run Edge Functions locally
deno test -A supabase/functions     # Edge Function tests (+ deno fmt --check, deno lint)
```

## Architecture rules (non-negotiable)

- **Layers:** `presentation → application → domain ← data`. `domain` is pure Dart (no Flutter, Drift,
  Supabase). Widgets never call repositories; features talk to each other via `application` APIs.
- **Local-first:** UI reads only from Drift streams. Every write goes through `SyncWriter` = one Drift
  transaction: row + outbox **patch** (HLC per field, `op_id` group) + `activity_events` when relevant.
  Never await the network inside a user interaction.
- **Sync correctness:** pull cursor = per-user revision from `app.sync_heads` — **never** `updated_at` or a
  global sequence. Conflicts = per-field last-writer-wins by HLC. Multi-row operations share one `op_id`
  and are pushed atomically. Automatic (time-triggered) writes use the scheduled instant as their clock.
- **Riverpod 3, manual providers** (no codegen except Drift — ADR-016; see `docs/dev_patterns.md`).
  Inject `Clock` — never call `DateTime.now()` in domain/application code.
- **Models:** hand-written immutable classes (`==`, `hashCode`, `copyWith`, `fromJson`/`toJson`). JSON value
  objects carry `"v"` and upgrade old versions.
- **Time:** instants in UTC; wall-clock values (`*_local`, `occurrence_key`) always paired with an IANA
  `time_zone` or explicitly floating. Use the recurrence engine for anything repeating.
- **IDs:** UUIDv7 client-side; UUIDv5 (`EVERSLOT_NS`) for convergent rows (occurrences, habit day-state,
  inbox, settings, entity tags). Ordering via fractional index strings.
- **Deletes are soft** (`deleted_at`) with cascades in the same transaction.
- **Database:** every table in schema `app` (server-only tables in `private`), created via migration +
  `app.enable_sync(...)` (triggers, `(user_id, rev)` index, RLS, `field_clock`) + pgTAP isolation test.
  Sort keys are `text COLLATE "C"`. Drift schema change → bump `schemaVersion`, step migration, schema dump,
  migration test, table-registry entry.
- **Secrets:** never in the repo or the app. Only the Supabase publishable key ships in the app.
  Secret keys, FCM service account, cron secret, Apple sign-in key live in Edge Function secrets / Vault /
  CI secrets.
- **Packages:** don't add a dependency without adding it (with reason) to `arch §3`.

## UI rules

- No hard-coded user-facing strings — ARB keys in `app/lib/l10n` (EN source, FR, AR). ICU plurals.
- RTL-safe: `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`; check Arabic layout.
- Semantics labels on interactive elements; touch targets ≥ 48 dp; text scale 2.0 must not clip;
  honour reduce-motion; test dark mode.
- Use design-system tokens/components (`app/lib/design_system`) — no ad-hoc colors, paddings, fonts.
- Heavy work (recurrence expansion over long ranges, stats) off the UI thread (isolates / Drift isolate).

## Testing rules

- Pure packages (`packages/everslot_recurrence`, `packages/everslot_metrics`) ≥ 95 % coverage,
  fixture-driven (`fixtures/`), multiple time zones incl. DST transitions.
- Every repository/DAO: in-memory Drift tests. Every notifier/service: unit tests with fake clock.
- Sync changes must pass the two-client convergence suite (`@Tags(['sync'])`).
- Key screens/charts: goldens (light/dark, LTR/RTL, text scale 2.0).

## Git

- Conventional commits (`feat(planner): …`, `fix(sync): …`), reference task IDs in the body
  (`Refs: T3.4.07`). Small focused commits; never commit `env/*.json` (except `env/example.json`),
  keystores, service-account files or generated secrets.
