#!/usr/bin/env bash
# One-command developer setup (T1.1.13): FVM SDK, dependencies, localizations, codegen check.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v fvm >/dev/null || { echo "Install FVM first: brew install fvm"; exit 1; }
fvm install
fvm dart pub get
fvm dart run tool/merge_arb.dart
(cd app && fvm flutter gen-l10n)
[ -f app/env/dev.json ] || cp app/env/example.json app/env/dev.json
echo "✅ Ready. Run: cd app && fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json"
