#!/usr/bin/env bash
# Usage: tool/new_migration.sh add_foo_table
set -euo pipefail
cd "$(dirname "$0")/.."
supabase migration new "$1"
