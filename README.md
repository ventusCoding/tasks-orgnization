# Everslot — own every slot of your day

Everslot is a personal organizer for iOS and Android, built with Flutter and Supabase. It works offline
first and syncs when a cloud backend is configured.

- **Plan**: a week table with 7 day columns and time slots from 1 minute to 24 hours (default 30 min), a
  day list with the same granularity, and many more views (month, agenda, timeline, kanban…). Tasks can
  repeat on any schedule.
- **Lists**: Keep-like checklists with infinitely nested items. Items carry text, images and files, and
  a status: to do, ongoing, waiting, blocked or completed. Waiting and blocked items keep a reason note.
- **Habits**: build habits (e.g. 15 push-ups a day on any schedule) and quit trackers (e.g. days
  without smoking, money saved, health milestones).
- **Insights**: detailed statistics for every item and every section.
- **Notifications**: configurable reminders per task, list, item and habit, delivered in-app, as local
  notifications and as Firebase push.

English, French and Arabic are supported, including right-to-left layout.

## Quick start

You need [FVM](https://fvm.app) (`brew install fvm`). Xcode is needed for iOS, and Android Studio for
Android.

```bash
tool/bootstrap.sh          # Flutter 3.47.5 via FVM, dependencies, localizations, env/dev.json
cd app
fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
```

Without Supabase credentials the app runs in **local-only mode**: every feature works on the device,
while sign-in and cloud sync stay disabled. [`docs/guide.md`](docs/guide.md) explains how to install
the tools, run the local backend (`supabase start`) and configure Supabase and Firebase step by step.

## Repository layout

| Path | What |
|---|---|
| `app/` | Flutter app (`dev` and `prod` flavors) |
| `packages/everslot_recurrence/` | Pure-Dart recurrence engine (rules, expansion, RRULE, descriptions) |
| `packages/everslot_metrics/` | Pure-Dart statistics engine (streaks, strength, trends, quit math…) |
| `supabase/` | Database migrations, RLS, RPCs, Edge Functions, pgTAP and Deno tests |
| `fixtures/` | Shared JSON fixtures (recurrence, stats) |
| `tool/` | Developer scripts (bootstrap, l10n merge, import checks, branding, backend reset) |
| `docs/` | Architecture, task files, developer patterns, ops and QA docs, the setup guide |

## Documentation

- [`CLAUDE.md`](CLAUDE.md): working rules and commands.
- [`docs/README.md`](docs/README.md): roadmap, milestones and task-file index.
- [`docs/architecture.md`](docs/architecture.md): stack, data model, sync, engines and decisions.
- [`docs/dev_patterns.md`](docs/dev_patterns.md): how feature code is written here.
- [`docs/guide.md`](docs/guide.md): install, configure and run.
- [`CONTRIBUTING.md`](CONTRIBUTING.md): workflow and definition of done.
