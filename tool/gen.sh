#!/usr/bin/env bash
# Regenerates Drift code and localizations.
set -euo pipefail
cd "$(dirname "$0")/.."
fvm dart run tool/merge_arb.dart
(cd app && fvm flutter gen-l10n && fvm dart run build_runner build)
