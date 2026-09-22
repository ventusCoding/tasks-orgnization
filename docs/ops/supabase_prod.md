# Supabase production hardening (T9.2.05)

- [ ] Pro plan (free projects pause after 1 week idle); region close to users.
- [ ] New API keys: publishable key in the app, secret key only in Edge Function secrets.
- [ ] Custom SMTP for auth emails; OTP/magic-link templates in EN/FR/AR.
- [ ] Auth: redirect URLs (`everslot://auth-callback`), rate limits, leaked-password protection, CAPTCHA
      for anonymous sign-ins, JWT expiry reviewed.
- [ ] Vault secrets: `functions_base_url`, `cron_secret`. Edge secrets: `FCM_SERVICE_ACCOUNT`, `CRON_SECRET`.
- [ ] Cron jobs present (dispatch 30 s, reaper 1 min, daily purge) — Dashboard › Integrations › Cron.
- [ ] Backups / PITR enabled; restore drill done (`docs/ops/runbooks.md#restore`).
- [ ] `pg_stat_statements` on; advisors clean.
