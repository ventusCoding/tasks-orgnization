# Schema evolution & API versioning (T9.2.08)

- **Expand → migrate → contract.** New columns are nullable or defaulted. Never rename/drop in the same
  release that stops using a column. Remove only after `min_supported_build` excludes old clients.
- **Old clients keep syncing:** `sync_push` ignores unknown columns (allow-list per schema version) and
  `sync_pull` returns full rows; the client skips unknown tables/columns.
- **Breaking RPC changes** ship as new functions (`sync_push_v2`) — the old one stays until old builds age out.
- **JSON value objects** (`"v"` field) are upgraded in memory by decoders; writers always emit the latest.
- **Drift:** bump `schemaVersion`, add a step migration, export the schema (`drift_dev schema dump`) and add
  a migration test.
- CI job idea: run the previous release's sync tests against the new schema before tagging.
