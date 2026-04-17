#!/bin/bash
# Retraq — initial project setup.
# Run this after cloning the repo (or after pulling major changes).
#
# Scripts live at app/scripts/ and assume the working directory can be
# anywhere inside the app/ tree; they change to app/ before running tools.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Task 10.6 — shared prereq helpers.
source "$SCRIPT_DIR/_prereq.sh"

echo "==> Checking prerequisites..."
require_cmd flutter "Install Flutter: https://flutter.dev/docs/get-started/install"
require_cmd dart "Should ship with Flutter."
require_flutter_version "3.41.6"

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
