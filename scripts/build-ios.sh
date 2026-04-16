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

# ── Prerequisite checks (Task 10.6) ───────────────────────────────────
echo "==> Checking prerequisites..."
command -v flutter >/dev/null 2>&1 || {
  echo "ERROR: flutter CLI not found in PATH."
  exit 1
}
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "ERROR: Xcode command-line tools not found."
  echo "Install with: xcode-select --install"
  exit 1
fi
command -v pod >/dev/null 2>&1 || {
  echo "WARN: CocoaPods (pod) not found. Install with: sudo gem install cocoapods"
  echo "      Continuing — flutter will attempt to invoke pod install itself."
}

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
