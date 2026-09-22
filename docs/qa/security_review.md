# Security review (T9.1.12)

| Area | Check | Status |
|---|---|---|
| Secrets | No secret keys in repo/app bundle (only publishable key); gitleaks in CI | ✅ by design (see .gitignore, env/example.json) |
| RLS | Every `app` table has RLS + pgTAP isolation tests | ✅ supabase/tests/database |
| Storage | Path-prefix policies on `attachments` bucket | ✅ migration + tests |
| Sessions | Supabase session in secure storage | see [1.5] T1.5.02 |
| Deep links | Parser rejects unknown roots/oversized params | ✅ `DeepLinkParser` + tests |
| Edge Functions | JWT or cron secret verified; secrets never logged | ✅ `_shared/auth.ts` |
| Logs | No PII (ids only) | ✅ `AppLog` policy |
| Dependencies | `dart pub outdated`, `osv-scanner` before release | release checklist |
