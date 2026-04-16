#!/bin/bash
# Retraq — initial project setup.
# Run this after cloning the repo (or after pulling major changes).
#
# Scripts live at app/scripts/ and assume the working directory can be
# anywhere inside the app/ tree; they change to app/ before running tools.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# ── Prerequisite checks (Task 10.6) ───────────────────────────────────
echo "==> Checking prerequisites..."
command -v flutter >/dev/null 2>&1 || {
  echo "ERROR: flutter CLI not found in PATH."
  echo "Install Flutter: https://flutter.dev/docs/get-started/install"
  exit 1
}
command -v dart >/dev/null 2>&1 || {
  echo "ERROR: dart CLI not found in PATH (should ship with Flutter)."
  exit 1
}

EXPECTED_FLUTTER="3.41.6"
ACTUAL_FLUTTER="$(flutter --version 2>/dev/null | head -n1 | awk '{print $2}' || echo 'unknown')"
if [ "$ACTUAL_FLUTTER" != "$EXPECTED_FLUTTER" ]; then
  echo "WARN: Flutter $ACTUAL_FLUTTER detected; project pins $EXPECTED_FLUTTER in .fvmrc."
  echo "      If you use FVM: 'fvm use $EXPECTED_FLUTTER' then re-run."
  echo "      Otherwise this may still work — Dart-analyzer drift is the risk."
fi

# ── Install deps + codegen ────────────────────────────────────────────
echo "==> Installing Flutter dependencies..."
flutter pub get

echo "==> Generating Drift schemas + other code..."
dart run build_runner build --delete-conflicting-outputs

echo "==> Regenerating localizations..."
flutter gen-l10n

echo "==> Running static analysis..."
flutter analyze

echo ""
echo "Setup complete! Run 'flutter run' to start the app."
