#!/usr/bin/env bash
# Retraq — shared prerequisite checks used by setup.sh / build-android.sh /
# build-ios.sh. Source this file (don't exec) so the `require_*` helpers
# are available to the caller:
#
#   source "$(dirname "$0")/_prereq.sh"
#   require_cmd flutter
#   require_cmd dart
#   require_flutter_version "3.41.6"
#
# Task 10.6 — central prerequisite helpers. Keeping them in one place
# means a Flutter SDK bump (or a new tool dependency) is a one-file edit
# instead of a three-file sweep.

set -euo pipefail

# require_cmd <command> [hint]
#   Fails with a GitHub-Actions-style error annotation if <command> is
#   not on PATH. The optional [hint] is echoed as a remediation pointer.
require_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "::error::Required command '$cmd' not found on PATH."
    if [ -n "$hint" ]; then
      echo "         $hint"
    fi
    exit 127
  fi
}

# require_flutter_version <expected>
#   Warns (does not fail) if the active flutter version differs from the
#   expected one. CI pins via .fvmrc; dev machines using global Flutter
#   get a reminder without being blocked.
require_flutter_version() {
  local expected="$1"
  local actual
  actual=$(flutter --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")
  if [ "$actual" != "$expected" ]; then
    echo "WARN: Flutter $actual detected; project pins $expected in .fvmrc."
    echo "      If you use FVM: 'fvm use $expected' then re-run."
    echo "      Otherwise this may still work — Dart-analyzer drift is the risk."
  fi
}

# require_java
#   Asserts a Java runtime is available. Android builds require JDK 17+
#   (Gradle 8.x + AGP 8.9.1 minimum). iOS builds do not need Java.
require_java() {
  require_cmd java "Install a JDK 17+ (Gradle + AGP need it)."
}

# require_xcode
#   Asserts Xcode command-line tools. iOS builds only.
require_xcode() {
  if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "::error::Xcode command-line tools not found."
    echo "         Install with: xcode-select --install"
    exit 127
  fi
}

# require_cocoapods_optional
#   Warns (does not fail) if `pod` is missing; flutter build ipa will
#   attempt `pod install` on its own. iOS builds only.
require_cocoapods_optional() {
  if ! command -v pod >/dev/null 2>&1; then
    echo "WARN: CocoaPods (pod) not found."
    echo "      Install with: sudo gem install cocoapods"
    echo "      Continuing — flutter will attempt pod install itself."
  fi
}
