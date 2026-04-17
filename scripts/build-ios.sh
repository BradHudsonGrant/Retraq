#!/bin/bash
# Retraq — build iOS release IPA.
#
# Prerequisites:
#   1. Valid Apple Developer account
#   2. Xcode installed with signing certificates configured
#   3. Open app/ios/Runner.xcworkspace in Xcode at least once to set:
#      - Team (Signing & Capabilities) via $RETRAQ_DEVELOPMENT_TEAM xcconfig
#      - Bundle Identifier (com.retraq.app)
#      - Deployment Target

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Task 10.6 — shared prereq helpers.
source "$SCRIPT_DIR/_prereq.sh"

echo "==> Checking prerequisites..."
require_cmd flutter
require_xcode
require_cocoapods_optional
require_flutter_version "3.41.6"

# ── Clean + deps + codegen ────────────────────────────────────────────
echo "==> Cleaning previous build..."
flutter clean

echo "==> Getting dependencies..."
flutter pub get

echo "==> Generating Drift schemas + other code..."
dart run build_runner build --delete-conflicting-outputs

echo "==> Regenerating localizations..."
flutter gen-l10n

echo "==> Running analysis..."
flutter analyze

# ── Build ─────────────────────────────────────────────────────────────
echo "==> Building iOS release (archive)..."
flutter build ipa --release

echo ""
echo "Build complete!"
echo "  IPA: build/ios/ipa/*.ipa"
echo ""
echo "To upload to App Store Connect:"
echo "  1. Open build/ios/archive/Runner.xcarchive in Xcode"
echo "  2. Window > Organizer > Distribute App"
echo "  — or automate via fastlane (see Task 10.2 when implemented) —"
echo "  xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \\"
echo "    -u your@apple.id -p @keychain:altool"
