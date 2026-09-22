# Everslot — Documentation Index & Roadmap

> **Everslot** — *own every slot of your day.* A Flutter + Supabase personal organizer: a time-table **Planner**,
> infinitely nested **Checklists**, **Habits & Quit** trackers, deep **Stats**, and a fully
> configurable **Notification** system (in-app + local + Firebase push).

This folder is the single source of truth for *what* we build (task files) and *how* we build it
([`architecture.md`](architecture.md)). Code must follow these docs; when reality diverges, update the
docs in the same change (see [Keeping docs alive](#keeping-docs-alive)).

---

## 1. Reading order

1. [`../CLAUDE.md`](../CLAUDE.md) — working rules, commands, conventions (short).
2. [`architecture.md`](architecture.md) — stack, system design, data model, engines, decisions.
3. This file — roadmap, milestones, conventions for task files.
4. Task files, in order (below). Each file is self-contained: goal → scope → progress list → tasks.

---

## 2. Glossary (avoid ambiguity)

| Term | Meaning |
|---|---|
| **Task** (domain) | A Planner item placed in time (table `tasks`). May recur. |
| **Occurrence** | One concrete instance of a (recurring) task/habit, identified by its `occurrence_key` (original local start, e.g. `2026-09-22T08:00`). |
| **Dev task** | A unit of work in these docs, ID `T<section>.<subsection>.<nn>`, e.g. `T3.4.07`. |
| **Checklist / Item** | A Keep-like list (`checklists`) and its infinitely nested entries (`checklist_items`). |
| **Habit** | A build habit (do X) or a quit tracker (stop X). Table `habits`, `kind = build | quit`. |
| **Log** | A habit check-in / relapse / craving record (`habit_logs`). |
| **Rule** | A notification rule (`notification_rules`) or a recurrence rule (JSON value object). Always qualify which. |
| **Slot** | A time-grid row of *N* minutes (1 … 1440) in the Planner. |
| **Section** | Top-level app area: Planner, Checklists, Habits, Stats, Notifications. |
| **Sync rev** | Server-assigned monotonically increasing revision used as the pull cursor. |

---

## 3. Conventions for task files

**File naming:** `tasks_section_<S>_<SS>_<name>.md` — `S` = section, `SS` = subsection (1-based).

**Dev task ID:** `T<S>.<SS>.<NN>` (NN zero-padded), unique and stable forever. Never renumber; if a
task is dropped, strike it through and say why. New tasks get the next free number.

**Task block template:**

```markdown
### T3.4.07 — Pinch-to-zoom changes slot height
**Priority:** P0 · **Size:** M · **Depends on:** T3.3.04, T3.4.02
**Description:** What and why, in 1–4 sentences.
**Implementation notes:** Concrete guidance: files/modules, algorithms, packages, edge cases.
**Acceptance criteria:**
- Observable, testable outcomes (UI behaviour, data written, performance numbers).
**Tests:** unit / widget / golden / integration / pgTAP / deno — what must exist.
```

Each file starts with a **Progress** checklist (`- [ ] T3.4.07 — title`). Tick it (`- [x]`) when the
task meets the Definition of Done.

Optional task lines: **Data model:** names the tables/columns/settings a task relies on (all are reflected in
`architecture.md`; if they ever disagree, the architecture wins and the note gets fixed). Stats tasks carry a
metric table (`| Metric ID | Name | Definition / formula | Data | Chart | Pri |`) instead of a long description.

**Priorities**

| Tag | Meaning | Milestone |
|---|---|---|
| **P0** | Needed for the first usable build (daily personal use) | M1 — MVP |
| **P1** | Needed for the public v1.0 store release | M2 — v1.0 |
| **P2** | Valuable, post-launch | M3 — Post-launch |

Rule: a task may depend only on tasks of **equal or higher** priority (a P0 never waits on a P1).

**Dependencies:** same-file dependencies use exact IDs (`T3.4.02`); cross-file dependencies name the
subsection in brackets (`[3.2]` = `tasks_section_3_2_*.md`), optionally with a hint (`[2.3] (FTS index)`).
Architecture references are written `arch §6.9`.

**Sizes:** `S` ≤ ½ day · `M` ≈ 1 day · `L` 2–3 days. Anything larger must be split.

**Definition of Done (every dev task)**
- Code follows `CLAUDE.md` + `architecture.md`; `dart analyze` / `deno lint` clean; formatted.
- Tests listed in the task exist and pass (`melos run test` or equivalent); no skipped tests.
- User-facing strings are localized (EN/FR/AR ARB keys) and layouts verified in RTL.
- Interactive elements have semantics labels; touch targets ≥ 48 dp; dark mode checked.
- DB changes ship as a new migration + RLS policy + pgTAP test; Drift schema version bumped with a migration test.
- Docs updated if behaviour/design changed; Progress checkbox ticked.

---

## 4. Milestones & build order

```mermaid
flowchart LR
  M0["M0 Foundation<br/>Sections 1–2 (P0)"] --> M1["M1 MVP<br/>P0 of Sections 3–8"]
  M1 --> M2["M2 v1.0<br/>all P1 + Section 9 release"]
  M2 --> M3["M3 Post-launch<br/>P2 + roadmap"]
```

**How to walk the roadmap:** implement **all P0 tasks in file order** (1.1 → 9.3), then all P1 tasks in
file order, then P2. This keeps the app usable end-to-end early (e.g. basic reminders arrive before
advanced stats). Two rules keep it safe:

1. **Dependencies first.** Before starting a task, check its `Depends on`. If a dependency (same priority or
   higher) lives in a *later* file and isn't done, do that dependency first, then come back — e.g. the habit
   detail screen (T5.2.07) pulls the streak and strength engines (T6.1.09, T6.1.10) forward.
2. **Test infrastructure early.** Section 9.1's P0 items are prerequisites, not a finale: T9.1.01 and
   T9.1.02 right after Section 1.3, T9.1.06 after 1.2, T9.1.03 after 1.4, T9.1.04 after 2.1.

| Milestone | Exit criteria |
|---|---|
| **M0 Foundation** | App boots with auth, shell navigation, design system, Drift DB, working two-device sync, recurrence engine passing its fixture suite, attachments upload/download. |
| **M1 MVP** | Week table + day list with configurable slots (1 min–24 h), task CRUD with free recurrence, nested checklists with statuses & attachments, build habits + quit trackers with check-ins, local notifications with per-item rules, core stats per item and per section, Today screen. Used daily by the owner for 2 weeks without data loss. |
| **M2 v1.0** | All planner/checklist/habit views, full stats catalog, FCM push + inbox + digests, widgets, export/backup, account deletion, a11y + RTL audit, crash-free ≥ 99.5 % in beta, store listings approved. |
| **M3 Post-launch** | P2 features (goals/achievements extras, integrations, natural-language quick add, sharing, web/desktop…). |

---

## 5. Task file index

### Section 1 — Foundation
| File | Scope |
|---|---|
| [`tasks_section_1_1_repo_tooling.md`](tasks_section_1_1_repo_tooling.md) | Monorepo (pub workspace + melos), Flutter app scaffold, flavors (dev/prod), env config, lints, formatting, git conventions, CI skeleton. |
| [`tasks_section_1_2_backend_setup.md`](tasks_section_1_2_backend_setup.md) | Supabase local + cloud projects, migration conventions, common columns & triggers, RLS baseline, storage bucket, Edge Functions scaffold, pg_cron/pg_net/Vault, Firebase projects, FCM + APNs, Crashlytics. |
| [`tasks_section_1_3_app_shell.md`](tasks_section_1_3_app_shell.md) | Layered architecture skeleton, bootstrap, core utilities (clock, ids, fractional index), go_router shell & deep-link parser, design system (tokens, components, pickers incl. 1-min time & duration), light/dark theme, i18n EN/FR/AR + RTL, a11y baseline, error handling, logging, feature flags & debug menu. |
| [`tasks_section_1_4_local_db_sync.md`](tasks_section_1_4_local_db_sync.md) | Drift database & migrations, outbox, push/pull RPCs, per-user revision cursor, Realtime nudge, conflict policy (LWW), tombstones & purge, full resync, sync status UI, two-device tests (developed against a seeded test user). |
| [`tasks_section_1_5_auth_profile.md`](tasks_section_1_5_auth_profile.md) | Email/OTP, Google, Apple, guest sign-in; session handling; profile (time zone, week start, 12/24 h, locale); first-run essentials; sign-out; account deletion. |

### Section 2 — Core engines (shared by all sections)
| File | Scope |
|---|---|
| [`tasks_section_2_1_recurrence_engine.md`](tasks_section_2_1_recurrence_engine.md) | `everslot_recurrence` pure-Dart package: JSON rule schema, expansion (minutely → yearly, windows, quotas, after-completion), exceptions/overrides, DST/time zones, RRULE import/export, human-readable text (EN/FR/AR), rule builder UI, shared JSON fixtures. |
| [`tasks_section_2_2_attachments.md`](tasks_section_2_2_attachments.md) | Pick/capture images & files, compression, thumbnails, offline upload queue (resumable), Storage paths & policies, local cache, viewers (image gallery, PDF, open-with). |
| [`tasks_section_2_3_shared_primitives.md`](tasks_section_2_3_shared_primitives.md) | Categories, tags, colors & icons, priorities, activity/event log, undo/redo, time-zone & calendar utilities, saved views, shared filter model, global FTS search index. |

### Section 3 — Planner (user section 1: tables & tasks)
| File | Scope |
|---|---|
| [`tasks_section_3_1_task_model_editor.md`](tasks_section_3_1_task_model_editor.md) | Task entity, create/edit sheet, all fields (time, duration, all-day, time-zone mode, category, color, priority, notes, attachments, linked checklist, tracking mode), backlog tasks, duplicate/delete/restore. |
| [`tasks_section_3_2_recurring_series_execution.md`](tasks_section_3_2_recurring_series_execution.md) | Series vs occurrence, edit scopes (this / this & following / all), occurrence actions (done, skip, reschedule, start/stop), missed detection, overdue & roll-over, time tracking, planned-vs-actual capture. |
| [`tasks_section_3_3_time_grid_engine.md`](tasks_section_3_3_time_grid_engine.md) | Shared time-grid engine: time scale (slot 1 min–24 h, px/min), semantic zoom, overlap layout algorithm, proportional vs bucketed rendering, lazy 2-D viewport, gestures (create/move/resize/snap), view-config model & saved views. |
| [`tasks_section_3_4_week_table_view.md`](tasks_section_3_4_week_table_view.md) | Default week table: 7 day columns × slot rows, infinite week paging, sticky headers & ruler, all-day lane, now line, hidden hours, density, filters. |
| [`tasks_section_3_5_day_list_view.md`](tasks_section_3_5_day_list_view.md) | Day picker + 24 h slot list (1 min–24 h rows), empty-slot collapsing, current-slot focus, quick create, swipe between days. |
| [`tasks_section_3_6_calendar_views.md`](tasks_section_3_6_calendar_views.md) | View switcher, N-day / work-week, week list (24-h slots), multi-week, month (semantic pinch), quarter, year heatmap, agenda/schedule, visual ribbon day timeline, timeline (Gantt), category swimlanes, load heatmap. |
| [`tasks_section_3_7_focus_productivity_views.md`](tasks_section_3_7_focus_productivity_views.md) | Now/Next focus & routine player, backlog drawer timeboxing, free-slot finder, Kanban, Eisenhower matrix, 24 h radial clock, table (spreadsheet), plan-vs-actual, horizons, countdown/count-up, map. |

### Section 4 — Checklists (user section 2: Keep-like nested lists)
| File | Scope |
|---|---|
| [`tasks_section_4_1_checklist_model_board.md`](tasks_section_4_1_checklist_model_board.md) | Checklist & item model, Keep-like board (masonry/list), pin, color, labels, archive, trash, search. |
| [`tasks_section_4_2_nested_tree_editor.md`](tasks_section_4_2_nested_tree_editor.md) | Infinite nesting editor: fractional ordering, indent/outdent, drag to reorder/reparent, collapse, focus/zoom with breadcrumbs, multi-select & bulk actions, keyboard, undo. |
| [`tasks_section_4_3_item_status_workflow.md`](tasks_section_4_3_item_status_workflow.md) | Statuses (todo, ongoing, waiting, blocked, completed, cancelled) with reason notes, status history, preview/run mode, progress roll-ups, parent auto-complete rules. |
| [`tasks_section_4_4_item_attachments.md`](tasks_section_4_4_item_attachments.md) | Images & files on items (and checklists): add, reorder, caption, preview strip, gallery, offline behaviour. |
| [`tasks_section_4_5_checklist_views_advanced.md`](tasks_section_4_5_checklist_views_advanced.md) | Outline / Kanban-by-status / Waiting-for & Blocked lists / mind map / gallery views, templates, recurring (resettable) checklists, due dates, import/export (Markdown, OPML, indented paste). |

### Section 5 — Habits & Quit (user section 3)
| File | Scope |
|---|---|
| [`tasks_section_5_1_habit_model_schedule.md`](tasks_section_5_1_habit_model_schedule.md) | Habit model: goal types (yes/no, count, duration, numeric, limit), schedules via recurrence (incl. N-per-period quotas, multiple times per day), pauses/vacation, archive, editor. |
| [`tasks_section_5_2_habit_checkin_views.md`](tasks_section_5_2_habit_checkin_views.md) | Check-in UX (done / not done / partial / skip / excuse), backfill, notes & mood, Today list, week matrix, habit detail, calendar & year heatmap, reorder/grouping. |
| [`tasks_section_5_3_quit_tracker.md`](tasks_section_5_3_quit_tracker.md) | Quit model, live clean-time counter, relapse & craving logging (intensity, trigger), money & time saved, milestones, reduce/limit mode, daily pledge/check-in. |
| [`tasks_section_5_4_goals_challenges.md`](tasks_section_5_4_goals_challenges.md) | Goals (e.g. 10 000 push-ups this year), challenges (30-day), achievements/badges, streak freezes. |

### Section 6 — Stats (all sections)
| File | Scope |
|---|---|
| [`tasks_section_6_1_stats_engine.md`](tasks_section_6_1_stats_engine.md) | Metric registry, periods & comparisons, expected-occurrence expansion, rollups & caching, isolates, `everslot_metrics` package. |
| [`tasks_section_6_2_chart_components.md`](tasks_section_6_2_chart_components.md) | Chart kit: stat cards, line/bar/stacked, donut, calendar heatmap, 7×24 punch card, streak timeline, CFD, burn-down, histogram, box plot, Gantt; theming, a11y, share-as-image. |
| [`tasks_section_6_3_planner_stats.md`](tasks_section_6_3_planner_stats.md) | Per-task/series and Planner-section metrics (completion, punctuality, planned vs actual, allocation, utilization, fragmentation, heatmaps…). |
| [`tasks_section_6_4_checklist_stats.md`](tasks_section_6_4_checklist_stats.md) | Per-item, per-checklist and section metrics (progress, lead/cycle time, time-in-status, blockers, throughput, CFD, burn-down, forecast…). |
| [`tasks_section_6_5_habit_stats.md`](tasks_section_6_5_habit_stats.md) | Per-habit and section metrics (streaks, habit strength score, completion rates, volume, day/time patterns, trends, records…). |
| [`tasks_section_6_6_quit_stats.md`](tasks_section_6_6_quit_stats.md) | Quit metrics (clean time, relapses, cravings & triggers, money/units/time saved, health milestones with disclaimer…). |
| [`tasks_section_6_7_dashboard_reports.md`](tasks_section_6_7_dashboard_reports.md) | Global dashboard, cross-section insights & correlations, weekly/monthly reports, year in review, goals progress, CSV/JSON export. |

### Section 7 — Notifications (all sections)
| File | Scope |
|---|---|
| [`tasks_section_7_1_notification_rules.md`](tasks_section_7_1_notification_rules.md) | Rule schema (triggers, offsets, repeats/nagging, conditions, channels, content templates, actions, sounds, priority), inheritance (global → section → category → item), rule editor UI. |
| [`tasks_section_7_2_local_notifications.md`](tasks_section_7_2_local_notifications.md) | Permissions & channels, on-device notification planner, rolling-window scheduler within OS limits, rescheduling triggers, notification actions (done/snooze/log), foreground banners. |
| [`tasks_section_7_3_in_app_inbox.md`](tasks_section_7_3_in_app_inbox.md) | Notification center (inbox), read/unread, grouping, actions, badges, deep links, in-app banners, history. |
| [`tasks_section_7_4_push_fcm_server.md`](tasks_section_7_4_push_fcm_server.md) | Device registry & tokens, server planner + dispatcher (pg_cron → Edge Functions), FCM HTTP v1 sender, delivery policy & de-duplication, silent sync pushes, retries & token cleanup. |
| [`tasks_section_7_5_section_notification_catalog.md`](tasks_section_7_5_section_notification_catalog.md) | Per-section trigger catalog (planner, checklists, habits, quit), digests (daily agenda, weekly review), quiet hours, pause-all, per-device routing, notification stats. |

### Section 8 — Cross-cutting features
| File | Scope |
|---|---|
| [`tasks_section_8_1_today_search_quick_add.md`](tasks_section_8_1_today_search_quick_add.md) | Today home screen, global search, universal quick-add, command palette. |
| [`tasks_section_8_2_widgets_integrations.md`](tasks_section_8_2_widgets_integrations.md) | Home-screen widgets (iOS/Android), app shortcuts, share-into-app, device calendar overlay, deep links, health integrations. |
| [`tasks_section_8_3_settings_data_privacy.md`](tasks_section_8_3_settings_data_privacy.md) | Settings screens, backup/export/import, app lock & encryption, data/account deletion, onboarding tour, accessibility pass. |

### Section 9 — Quality, release & beyond
| File | Scope |
|---|---|
| [`tasks_section_9_1_testing_quality.md`](tasks_section_9_1_testing_quality.md) | Test matrix, coverage gates, performance budgets & profiling, accessibility & RTL audits, security review. |
| [`tasks_section_9_2_release_operations.md`](tasks_section_9_2_release_operations.md) | CI/CD pipelines, signing, store listings, privacy labels & policy, beta programs, monitoring, backups, support, versioning. |
| [`tasks_section_9_3_post_launch_roadmap.md`](tasks_section_9_3_post_launch_roadmap.md) | Post-launch backlog: sharing/collaboration, natural-language & AI assistant, web/desktop, wearables, calendar two-way sync, Hijri calendar, more integrations. |

---

## 6. Size of the plan

| Section | Files | P0 (MVP) | P1 (v1.0) | P2 (later) | Total |
|---|---|---|---|---|---|
| 1 — Foundation | 5 | 61 | 25 | 3 | 89 |
| 2 — Core engines | 3 | 35 | 7 | 4 | 46 |
| 3 — Planner | 7 | 72 | 45 | 19 | 136 |
| 4 — Checklists | 5 | 38 | 28 | 8 | 74 |
| 5 — Habits & Quit | 4 | 31 | 20 | 7 | 58 |
| 6 — Stats | 7 | 68 | 58 | 17 | 143 |
| 7 — Notifications | 5 | 41 | 39 | 14 | 94 |
| 8 — Cross-cutting | 3 | 14 | 21 | 15 | 50 |
| 9 — Quality, release & beyond | 3 | 5 | 26 | 21 | 52 |
| **All** | **42** | **365** | **269** | **108** | **742** |

Section 6 alone defines **231 uniquely-identified metrics** (IDs like `PL-X-08`, `CL-L-20`, `HB-H-27`,
`QT-06`, `GL-16`), each with a precise formula, data source, chart and priority.

---

## 7. Keeping docs alive

- A change that alters behaviour, data model or architecture **must** update the relevant task file
  and, for design changes, add an entry to the *Decision log* in `architecture.md`.
- Never delete a dev task; strike it through (`~~T4.2.09 — …~~ dropped: reason`).
- New ideas discovered while building go to the end of the relevant file as new tasks (next free ID)
  or to `tasks_section_9_3_post_launch_roadmap.md` if out of scope.
