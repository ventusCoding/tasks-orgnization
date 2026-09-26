# Supabase production hardening (T9.2.05)

Checklist for the production project `everslot-prod`. **Owner:** project lead. **When:** before the first
external beta; re-verify at every release (`docs/ops/release_checklist.md`) and once a quarter.
Local settings live in `supabase/config.toml`; the cloud project must match them (T1.5.01).

Dashboard paths are those of 2026-09; the dashboard is reorganised from time to time, so search for the
setting name if a path moved. Never paste secret values into this file, tickets or chat. `<YOUR_PROJECT_REF>`
is the project reference (not secret). Fill the sign-off table at the end.

## 1. Project, plan and region

- [ ] **Pro plan** — Organization › Billing › Subscription plan. Free projects pause after 7 days without
      activity and have no daily backups.
- [ ] **Spend cap** — Organization › Billing › Cost control: keep it on until a few months of usage are
      known; switch it off only with the alerts of `docs/ops/cost_quotas.md` in place.
- [ ] **Region** close to the users, chosen at creation — it cannot be changed without moving to a new
      project. E.g. `eu-west-3` (Paris) or `eu-central-1` (Frankfurt) for EU and Maghreb users. Write it into
      the privacy policy placeholder `[SUPABASE REGION]` (`site/*/privacy.html`).
- [ ] **Compute** — Project Settings › Compute and Disk: Micro at launch; upgrade when Reports › Database
      shows CPU or memory above 70 % for days. Point-in-time recovery needs Small or larger.
- [ ] **Project ref** recorded in `supabase/README.md` (§ Placeholders & secrets) and in the CI secret
      `SUPABASE_PROJECT_REF`; `supabase link --project-ref <YOUR_PROJECT_REF>` works locally.
- [ ] **Team** — Organization › Team: two owners at most, every member with MFA (Account › Security);
      enforce MFA for the organization where the plan offers it.

## 2. API keys, JWT signing, Data API

- [ ] Project Settings › **API Keys**: a publishable key `sb_publishable_…` for the app (CI secrets
      `SUPABASE_PUBLISHABLE_KEY` and `ENV_PROD_JSON`) and a secret key `sb_secret_…` used **only** as the
      Edge Function secret `SUPABASE_SECRET_KEY`. Once nothing uses them, disable the legacy
      `anon` / `service_role` keys on the same page (ADR-015).
- [ ] Project Settings › **JWT Keys**: asymmetric signing key in use; after a rotation, revoke the previous
      key only when no session can still use it (access tokens live 1 h).
- [ ] Project Settings › **Data API**: exposed schemas = `app` only, extra search path `app, extensions`,
      max rows 1000 (`config.toml [api]`). `public` and `graphql_public` are not exposed.

## 3. Authentication

- [ ] Authentication › Sign In / Providers › **Email**: enabled; confirm email on; secure e-mail change on;
      OTP length 6; OTP expiry at most 3600 s (`config.toml [auth.email]`). Passwords are not used.
- [ ] **Google**: web client id (server client id) and iOS client id from Google Cloud › APIs & Services ›
      Credentials; "Skip nonce check" off ([1.5] T1.5.09).
- [ ] **Apple**: Services ID, Team ID, Key ID and the client secret of the Android web flow. The secret
      expires after at most 6 months: rotation runbook in `docs/ops/runbooks.md` + calendar reminder.
- [ ] **Anonymous sign-ins** on (guest mode, [1.5] T1.5.11), anonymous rate limit 30 per hour per IP.
- [ ] **CAPTCHA** — Authentication › Attack Protection (older UI: Bot and Abuse Protection): Cloudflare
      Turnstile or hCaptcha. Enabling it protects *every* sign-up/sign-in endpoint (anonymous and e-mail
      OTP): switch it on only when the app sends a `captchaToken` on all of them, or sign-in breaks.
- [ ] Authentication › **URL Configuration**: Site URL `everslot://auth-callback`; redirect URLs
      `everslot://auth-callback` only (`everslot-dev://…` and `http://127.0.0.1:3000` belong to dev/local).
- [ ] Authentication › Emails › **SMTP Settings**: custom SMTP (sender `no-reply@YOUR_SITE_DOMAIN`), SPF,
      DKIM and DMARC records published, bounce notifications to `[CONTACT EMAIL]`. The built-in mailer is
      for testing (2 e-mails per hour).
- [ ] Authentication › Emails › **Templates**: OTP, magic link and e-mail change templates in EN/FR/AR
      ([1.5] T1.5.15); send one of each locale to a test inbox.
- [ ] Authentication › **Rate Limits** (compare with `config.toml [auth.rate_limit]`): e-mails sent per hour
      sized for launch with custom SMTP (e.g. 100); token verifications 30, sign-ups/sign-ins 30 and token
      refreshes 150 per 5 minutes per IP.
- [ ] Authentication › **Sessions**: no time-box and no inactivity timeout — offline-first clients must be
      able to refresh after weeks offline ([1.5] T1.5.14). Refresh token rotation on, reuse interval 10 s.
- [ ] Authentication › **Multi-Factor**: TOTP only when [1.5] T1.5.17 ships.
- [ ] Auth audit logs: they contain e-mail addresses and IP addresses, also of deleted users. If the project
      offers it, keep them in the log store only (Authentication › Audit Logs); otherwise schedule a purge of
      `auth.audit_log_entries` older than 28 days, the server-log retention stated in the privacy policy.

## 4. Database and network

- [ ] Project Settings › Database › **SSL enforcement** on.
- [ ] **Network restrictions** (same page): optional. `release.yml` runs `supabase db push` from GitHub-hosted
      runners (changing IPs), so restrict only with a fixed-IP runner or a temporary allow-list step.
- [ ] **Database password**: long and random, in the password manager and the CI secret
      `SUPABASE_DB_PASSWORD`. Rotate on exposure or when someone with access leaves: Project Settings ›
      Database › Reset database password, then update the CI secret.
- [ ] Database › **Extensions**: `pg_cron`, `pg_net` and `pg_stat_statements` enabled (`pgtap` only
      locally).
- [ ] Advisors › **Security Advisor** and **Performance Advisor**: no errors; warnings triaged. CLI:
      `supabase db lint --linked --schema app,private --level warning`.
- [ ] Database › Roles: no custom role with `BYPASSRLS`; `service_role` is used only by Edge Functions.
- [ ] Statement timeout: sync pushes of 500 changes stay well under the `authenticated` role's timeout
      (check the slowest `app.sync_push` calls in Reports › Query performance during the beta).

## 5. Storage

- [ ] Storage › Buckets › `attachments`: private, 25 MB file limit and the MIME allow-list of migration
      `…120_create_storage_attachments.sql` — the dashboard shows exactly those values.
- [ ] Storage › Settings: global upload limit ≥ 25 MB.
- [ ] S3 access keys (Storage › Settings › S3 connection) exist only for the backup job of
      `docs/ops/backups_dr.md`. They bypass RLS: store them as CI secrets only and revoke unused keys.

## 6. Edge Functions and secrets

- [ ] Edge Functions list: `health`, `push-dispatch`, `sync-nudge`, `account-delete`, `storage-purge`,
      deployed by `release.yml`; JWT verification off for all of them (they authenticate callers
      themselves, `supabase/README.md` § Edge Functions).
- [ ] Edge Functions › **Secrets**: `FCM_SERVICE_ACCOUNT`, `CRON_SECRET`, `SUPABASE_SECRET_KEY` (and
      `APPLE_CLIENT_SECRET` once Sign in with Apple token revocation ships). Check the names with
      `supabase secrets list --project-ref <YOUR_PROJECT_REF>` (values are never shown).
- [ ] Check: `curl -s https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/health` returns
      `supabase_configured`, `fcm_configured` and `cron_secret_configured` all `true`.

## 7. Vault, cron and Realtime

- [ ] Integrations › **Vault**: secrets `functions_base_url`
      (`https://<YOUR_PROJECT_REF>.supabase.co/functions/v1`) and `cron_secret` (same value as the Edge
      secret `CRON_SECRET`). SQL to create them: `supabase/README.md` § Placeholders & secrets.
- [ ] Integrations › **Cron**: `everslot-push-dispatch` (30 s), `everslot-minutely` (every minute) and
      `everslot-daily` (03:00 UTC) active, recent runs `succeeded`:

      ```sql
      select j.jobname, j.schedule, j.active, d.status, d.start_time
      from cron.job j
      left join lateral (select status, start_time from cron.job_run_details r
                         where r.jobid = j.jobid order by start_time desc limit 1) d on true
      order by j.jobname;
      ```

- [ ] Realtime › Settings: public channel access disabled (private `user:<uid>` channels only, authorized by
      the `realtime.messages` policy of migration `…020_create_sync_plumbing.sql`).

## 8. Backups, monitoring, performance

- [ ] Database › **Backups**: daily backups listed; point-in-time recovery decision recorded and the first
      restore drill done (`docs/ops/backups_dr.md`).
- [ ] Logs & Analytics: the saved queries of `docs/ops/monitoring.md` exist; the uptime check on `health` is
      live and has been tested by disabling a cron job.
- [ ] `pg_stat_statements` shows the sync RPCs (Reports › Query performance).

## Sign-off

| Section | Value / evidence | Date | By |
|---|---|---|---|
| 1 Plan, region, compute, team | | | |
| 2 API keys, JWT keys, Data API | | | |
| 3 Authentication | | | |
| 4 Database and network | | | |
| 5 Storage | | | |
| 6 Edge Functions and secrets | | | |
| 7 Vault, cron, Realtime | | | |
| 8 Backups, monitoring | | | |
