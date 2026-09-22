#!/usr/bin/env bash
# Re-applies all migrations + seed to the local Supabase stack (requires Docker + Supabase CLI).
set -euo pipefail
cd "$(dirname "$0")/.."
supabase start
supabase db reset
supabase test db
