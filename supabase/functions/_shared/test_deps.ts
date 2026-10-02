// Test-only dependencies (never imported by deployed functions). Pinned like deps.ts.
// `postgres` connects the opt-in E2E suite (push-dispatch/e2e_test.ts) to the local stack to set up
// scenarios and inspect the server-only `private` tables.

export { default as postgres } from "npm:postgres@3.4.7";
