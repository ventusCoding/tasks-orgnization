# Section 9.3 — Post-launch Roadmap

> Milestone: M3 (all P2) · Depends on: v1.0 shipped
> Architecture: revisit §13 ADRs before starting any item marked **ADR** — they change core assumptions.

## Goal

A curated backlog of what comes after v1.0, each item scoped enough to start a design spike. Items are
ordered by expected value for a personal-organizer user; re-rank after reviewing real usage and feedback.
Each **L+** item begins with a spike task that produces its own task file (`tasks_section_9_<n>_<name>.md`).

## Progress

- [ ] T9.3.01 — Tablet, foldable & landscape multi-pane layouts
- [ ] T9.3.02 — Focus / Pomodoro timer with stats
- [ ] T9.3.03 — Smart scheduling: auto-place backlog tasks into free slots
- [ ] T9.3.04 — AI assistant (planning, reviews, coaching)
- [ ] T9.3.05 — Hijri calendar & regional calendars
- [ ] T9.3.06 — Two-way calendar sync (Google / Apple / CalDAV)
- [ ] T9.3.07 — Sharing & collaboration (shared checklists, family)
- [ ] T9.3.08 — Web & desktop apps
- [ ] T9.3.09 — Wear OS & watchOS companions
- [ ] T9.3.10 — Location-based reminders
- [ ] T9.3.11 — Journaling & mood tracking section
- [ ] T9.3.12 — Advanced gamification (XP, levels, seasons)
- [ ] T9.3.13 — Template gallery & routine sharing
- [ ] T9.3.14 — Voice capture
- [ ] T9.3.15 — More languages
- [ ] T9.3.16 — End-to-end encryption option
- [ ] T9.3.17 — Public API, webhooks & automation integrations
- [ ] T9.3.18 — Monetization (if desired)

## Tasks

### T9.3.01 — Tablet, foldable & landscape multi-pane layouts
**Priority:** P2 · **Size:** L · **Depends on:** v1.0
**Description:** Adaptive layouts (window size classes): Planner week table + side panel (task details or
backlog), Lists board + open checklist side by side, Insights dashboards in grids; keyboard shortcuts and
pointer hover states for tablets with keyboards.
**Acceptance criteria:** no phone-only assumptions left (all screens adapt at 600/840/1200 dp breakpoints).

### T9.3.02 — Focus / Pomodoro timer with stats
**Priority:** P2 · **Size:** L · **Depends on:** [3.2] (time tracking), [6.3]
**Description:** Focus sessions (Pomodoro or custom intervals) bound to a task or habit, break reminders,
optional app-blocking guidance, focus stats (daily focus time, sessions, interruptions, best focus hours).

### T9.3.03 — Smart scheduling: auto-place backlog tasks into free slots
**Priority:** P2 · **Size:** L · **Depends on:** [3.7] (free-slot finder, backlog)
**Description:** Given estimates, priorities, deadlines, work hours and existing tasks, propose a
schedule (deterministic constraint solver first; explainable placements; user confirms). Re-plan the day
when things slip ("reschedule the rest of my day").

### T9.3.04 — AI assistant (planning, reviews, coaching)
**Priority:** P2 · **Size:** L · **Depends on:** T9.3.03, [6.7]
**Description:** Optional, opt-in assistant using the Anthropic Claude API (latest models, e.g. Claude
Sonnet 5 for speed / Opus 5.5 for depth) via an Edge Function proxy (keys never in the app): natural-language
task/habit creation, weekly-review narrative from computed stats, habit coaching, checklist breakdown
("split this item into steps"). **ADR** — privacy (explicit consent, data minimization, no training on
user data), cost controls, offline behaviour.

### T9.3.05 — Hijri calendar & regional calendars
**Priority:** P2 · **Size:** L · **Depends on:** [2.1]
**Description:** Display Hijri dates alongside Gregorian (month view, headers), recurrence on Hijri dates
(e.g. every 1 Ramadan; RFC 7529 `RSCALE`-style extension to the rule schema, `"v": 2`), Ramadan-aware
habit templates. **ADR** for the rule-schema extension.

### T9.3.06 — Two-way calendar sync (Google / Apple / CalDAV)
**Priority:** P2 · **Size:** L · **Depends on:** [8.2] (ICS import/export, device overlay)
**Description:** Sync selected categories with external calendars (Google Calendar API, CalDAV/iCloud),
mapping recurrence/overrides, conflict handling, server-side OAuth token storage. **ADR** (server-side
sync workers, token security).

### T9.3.07 — Sharing & collaboration (shared checklists, family)
**Priority:** P2 · **Size:** L · **Depends on:** [4.x], [1.4]
**Description:** Share a checklist (view/edit) with other users, assign items, comments, activity feed,
realtime presence. **ADR** — requires multi-owner RLS (membership tables), finer-grained conflict
resolution (field-level merge or CRDT for text), per-row permissions in sync, notification fan-out.

### T9.3.08 — Web & desktop apps
**Priority:** P2 · **Size:** L · **Depends on:** T9.3.01
**Description:** Flutter web (Drift WASM + OPFS storage), macOS/Windows builds; desktop notifications;
keyboard-first planner. Validate performance of the time grid on web.

### T9.3.09 — Wear OS & watchOS companions
**Priority:** P2 · **Size:** L · **Depends on:** [5.2], [3.2]
**Description:** Glanceable next task, habit check-ins, quit counter, timer control; complications/tiles.
Native (SwiftUI / Compose for Wear) talking to the phone app or directly to Supabase.

### T9.3.10 — Location-based reminders
**Priority:** P2 · **Size:** M · **Depends on:** [7.1], [7.2]
**Description:** Trigger type `location` (arrive/leave geofence) for tasks and checklist items; permission
primer; battery-conscious geofencing; privacy (locations never leave the device unless opted in).

### T9.3.11 — Journaling & mood tracking section
**Priority:** P2 · **Size:** L · **Depends on:** [6.7]
**Description:** Daily journal with prompts, mood scale, tags; correlations with habits and planner load in
Insights (e.g. mood vs sleep habit vs meetings).

### T9.3.12 — Advanced gamification (XP, levels, seasons)
**Priority:** P2 · **Size:** M · **Depends on:** [5.4]
**Description:** Opt-in XP for completions weighted by difficulty/priority, levels, monthly seasons with
challenges; careful design to avoid perverse incentives (e.g. no XP for creating tasks).

### T9.3.13 — Template gallery & routine sharing
**Priority:** P2 · **Size:** M · **Depends on:** [4.5] (templates), [5.1]
**Description:** Curated templates (morning routine, study plan, 30-day fitness, quit-smoking plan) and
export/import of personal templates as shareable files/links.

### T9.3.14 — Voice capture
**Priority:** P2 · **Size:** M · **Depends on:** [8.1] (NL quick add)
**Description:** Speech-to-text quick add (on-device recognizers), voice notes as attachments with transcripts.

### T9.3.15 — More languages
**Priority:** P2 · **Size:** M · **Depends on:** [9.1] (l10n QA)
**Description:** Add ES, DE, TR, IT (and others by demand) with native review; recurrence text
generator grammar per language.

### T9.3.16 — End-to-end encryption option
**Priority:** P2 · **Size:** L · **Depends on:** [1.4]
**Description:** Client-side encryption of free-text fields and attachments with user-held keys (recovery
key flow). **ADR** — breaks server-side guards that read content (notification guards must only use
ids/status), search stays local-only.

### T9.3.17 — Public API, webhooks & automation integrations
**Priority:** P2 · **Size:** M · **Depends on:** [1.2]
**Description:** Personal access tokens, a small REST surface (create task, log habit), outgoing webhooks
on events; recipes for Shortcuts/Tasker/Zapier.

### T9.3.18 — Monetization (if desired)
**Priority:** P2 · **Size:** M · **Depends on:** v1.0 metrics
**Description:** Decide model (free, one-time unlock, subscription). If paid tiers: entitlement service
(e.g. RevenueCat), server-side entitlement checks in RLS/RPCs for premium features, paywall UX that never
blocks access to existing data, localized pricing. **ADR**.
