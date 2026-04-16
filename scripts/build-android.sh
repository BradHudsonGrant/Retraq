#!/bin/bash
# Retraq — build Android release APK and App Bundle.
#
# Prerequisites:
#   1. Create a keystore:
#      keytool -genkey -v -keystore android/release-keystore.jks -keyalg RSA \
#        -keysize 2048 -validity 10000 -alias retraq
#   2. Create android/key.properties:
#      storePassword=<your-password>
#      keyPassword=<your-password>
#      keyAlias=retraq
#      storeFile=release-keystore.jks
#
# For CI, set KEYSTORE_BASE64 / KEYSTORE_PASSWORD / KEY_ALIAS / KEY_PASSWORD
# as GitHub Secrets and let the workflow hydrate key.properties.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# ── Prerequisite checks (Task 10.6) ───────────────────────────────────
echo "==> Checking prerequisites..."
command -v flutter >/dev/null 2>&1 || {
  echo "ERROR: flutter CLI not found in PATH."
  exit 1
}
command -v java >/dev/null 2>&1 || {
  echo "ERROR: java not found in PATH (needed for Gradle)."
  exit 1
}

# ── Signing check ─────────────────────────────────────────────────────
echo "==> Checking key.properties..."
if [ ! -f android/key.properties ]; then
  echo "WARNING: android/key.properties not found."
  echo "Building with debug signing (not suitable for Play Store)."
  echo "See Task 3.3 / Task 10.4 — CI fails loud on missing keystore;"
  echo "local builds accept debug fallback but must not be uploaded."
  echo ""
fi

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
echo "==> Building APK (fat)..."
flutter build apk --release

echo "==> Building App Bundle (for Play Store)..."
flutter build appbundle --release

echo ""
echo "Build complete!"
echo "  APK:         build/app/outputs/flutter-apk/app-release.apk"
echo "  App Bundle:  build/app/outputs/bundle/release/app-release.aab"
