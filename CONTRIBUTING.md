# Contributing to Everslot

1. Read `CLAUDE.md`, `docs/README.md`, `docs/architecture.md` and `docs/dev_patterns.md`.
2. Pick the next unchecked task (P0 → P1 → P2, file order). Branch: `feat/T3.4.07-short-name`.
3. Implement with tests; run `fvm dart analyze app packages tool` and `melos run test`.
4. Tick the task in its `docs/tasks_section_*.md` Progress list (add `**Notes:**` for deviations).
5. Conventional commit (`feat(planner): …`) with `Refs: T…` in the body; open a PR using the template.

Setup: `tool/bootstrap.sh` · Backend: `tool/reset_local_backend.sh` · Codegen/l10n: `tool/gen.sh`.
