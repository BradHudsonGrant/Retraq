# Epic 10 — DevOps, CI/CD, Release Engineering

Source: review-2026-04-16.md §Agent 10

This epic turns the DevOps & Build Pipeline findings into concrete engineering tasks. The pipeline is already above-average for an indie Flutter project (SHA-pinned actions, coverage gates, smoke release builds, dual-path Android signing), so most work centres on three launch blockers — crash reporting, iOS TestFlight automation, and FVM/CI version drift — plus a handful of script-hygiene items. Automated findings that need no work are kept as reference entries so every row of the source table is traceable.

---

## P0 — Launch blockers

### Task 10.1 — Wire crash reporting (Sentry) before public submission

**Source:** A10 finding "No crash reporting / production observability" · **Rating:** Missing
**Priority:** P0 · **Effort:** M · **Tier:** v1

#### Problem
`pubspec.yaml` ships with no Crashlytics or Sentry dependency, and `lib/` has no equivalent. Production crashes are invisible; the `DatabaseService.onStreamError` hook only emits `debugPrint`. Several bare-catch blocks (flagged by Agents 1, 3) silently swallow exceptions — without an aggregator they never surface after release.

#### Root cause
The app was built privacy-first and deliberately avoided telemetry. Crash reporting was deferred but never revisited; the review flags it as the single biggest production-observability gap before a public launch.

#### Decision: Sentry over Firebase Crashlytics

| Dimension | Sentry | Firebase Crashlytics |
|---|---|---|
| Privacy posture | Self-hostable, EU data region (Frankfurt) available, DSN-level scrubbing, `beforeSend` hook runs on-device | Google-hosted only, ties app to Firebase SDK bundle, US data by default |
| Data minimisation | Breadcrumbs, PII, IP, user-id all individually toggleable; `sendDefaultPii: false` | Less granular; crash payloads auto-include device identifiers |
| Consent story for Retraq | Can gate `Sentry.init` behind explicit opt-in setting, matching privacy-policy tone | Adding Firebase adds privacy-policy surface (Google sub-processor) even if unused |
| SDK weight | `sentry_flutter` ~1.3 MB | `firebase_crashlytics` drags in `firebase_core` + Google Play Services |
| Flutter support | `sentry_flutter` — first-class, dart:ui integration, `Zone`-based uncaught error capture | Mature but tied to Firebase plugins |
| Cost at indie scale | Free tier 5k events/mo, $26/mo after | Free |
| Alignment with existing stack | No other Google SDK in app — Sentry keeps the surface minimal | Would be the first Google SDK |

**Pick: Sentry.** The privacy-policy ("no analytics, no telemetry") posture is the deciding factor — Sentry can be configured opt-in, EU-region, PII-scrubbed, and shipped without Google sub-processors. Cost (~$0-26/mo) is acceptable.

#### Files touched
- `app/pubspec.yaml` — add `sentry_flutter`
- `app/lib/main.dart` — wrap `runApp` in `SentryFlutter.init`
- `app/lib/services/observability/crash_reporter.dart` — new thin wrapper (init, captureException, breadcrumb)
- `app/lib/services/database_service.dart` — replace `debugPrint` in `onStreamError` with `CrashReporter.captureException`
- `app/lib/screens/settings/data_section.dart` — new "Send crash reports" toggle (default **off**)
- `app/lib/legal/privacy_policy.dart` — add sub-processor disclosure (Sentry GmbH, Frankfurt)
- `.github/workflows/release.yml` — pass `SENTRY_AUTH_TOKEN` to upload debug symbols
- `.github/workflows/ci.yml` — no change; CI should not hit Sentry

#### Implementation approach
1. Add dependency:
   ```yaml
   # pubspec.yaml
   dependencies:
     sentry_flutter: ^8.9.0
   ```
2. Create `CrashReporter`:
   ```dart
   class CrashReporter {
     static Future<void> init({required bool enabled, required String dsn}) async {
       if (!enabled) return;
       await SentryFlutter.init((o) {
         o.dsn = dsn;
         o.sendDefaultPii = false;
         o.tracesSampleRate = 0.0;
         o.beforeSend = (event, hint) => _scrub(event);
         o.environment = const String.fromEnvironment('SENTRY_ENV', defaultValue: 'prod');
       });
     }
   }
   ```
3. Read the user-preference flag from `UserSettingsTable.crashReportingEnabled` (new column, default `false`) before calling `init`. If the user later toggles it on, lazy-init on the next app launch rather than runtime.
4. Replace bare catches flagged by Agent 1 and 3 with `CrashReporter.captureException(e, stackTrace)` — preserves the control flow but makes the error visible.
5. In `release.yml`, after the iOS/Android builds, add a step that runs `sentry-cli debug-files upload` using `${{ secrets.SENTRY_AUTH_TOKEN }}` — symbols are required for readable stack traces.
6. Update privacy policy "Third parties" section to disclose Sentry as opt-in sub-processor.

#### Test plan
- Unit test `CrashReporter.init` is a no-op when `enabled: false`.
- Manual: flip toggle on, force a test exception, confirm event appears in Sentry EU project.
- Manual: flip off, force exception, confirm **no** network request (Charles/mitmproxy).
- CI does not initialise Sentry (gate on `const bool.fromEnvironment('CI')`).

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] Merged to main with CI passing
- [ ] No secrets in the diff (DSN read from `--dart-define` or secure storage; auth token only in Actions secrets)
- [ ] Opt-in toggle visible in Settings → Data
- [ ] Privacy policy updated and re-consent bumped
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore:` prefix referencing Task 10.1

#### Dependencies
- External: Sentry project + DSN, `SENTRY_AUTH_TOKEN` secret in GitHub
- Blocks: Agents 1 and 3 bare-catch fixes benefit from this landing first
- Coordinate with Epic 12 (Legal) on privacy-policy update

---

### Task 10.2 — Automate iOS TestFlight upload via fastlane + App Store Connect API key

**Source:** A10 finding "iOS release IPA signing / TestFlight upload" · **Rating:** Manual
**Priority:** P0 · **Effort:** L · **Tier:** v1

#### Problem
`release.yml:176` builds the iOS archive with `--no-codesign`; `scripts/build-ios.sh:34-45` does the same. There is no signed IPA, no App Store Connect upload, no TestFlight delivery. Every release requires manual Xcode Organizer work from the one macOS dev box.

#### Root cause
iOS signing was deferred until Apple Developer enrolment completed; no one circled back to wire it into CI.

#### Files touched
- `ios/fastlane/Fastfile` — new
- `ios/fastlane/Appfile` — new
- `ios/fastlane/Matchfile` — new (optional, match for cert sync)
- `ios/Gemfile` — pin fastlane
- `.github/workflows/release.yml` — replace `--no-codesign` block with fastlane lane
- `scripts/build-ios.sh` — mirror the fastlane path for local parity
- `ios/ExportOptions.plist` — add for `app-store` method

#### Implementation approach
1. Enrol a dedicated App Store Connect API key (Key ID, Issuer ID, `.p8` contents) — store all three as GitHub Secrets (`APPSTORE_KEY_ID`, `APPSTORE_ISSUER_ID`, `APPSTORE_P8_BASE64`).
2. Create fastlane skeleton:
   ```ruby
   # ios/fastlane/Appfile
   app_identifier("com.retraq.app")
   apple_id(ENV["FASTLANE_APPLE_ID"])  # optional, API key preferred
   team_id(ENV["APPLE_TEAM_ID"])
   ```
   ```ruby
   # ios/fastlane/Fastfile
   default_platform(:ios)

   platform :ios do
     before_all do
       setup_ci if ENV['CI']
       app_store_connect_api_key(
         key_id: ENV['APPSTORE_KEY_ID'],
         issuer_id: ENV['APPSTORE_ISSUER_ID'],
         key_content: ENV['APPSTORE_P8'],
         is_key_content_base64: false,
         in_house: false,
       )
     end

     desc "Build and upload a signed build to TestFlight"
     lane :beta do
       match(type: "appstore", readonly: is_ci)
       build_app(
         workspace: "Runner.xcworkspace",
         scheme: "Runner",
         configuration: "Release",
         export_method: "app-store",
         export_options: {
           provisioningProfiles: {
             "com.retraq.app" => "match AppStore com.retraq.app"
           }
         },
         output_directory: "../build/ios/ipa",
         output_name: "Retraq.ipa",
       )
       upload_to_testflight(
         skip_waiting_for_build_processing: true,
         changelog: ENV['RELEASE_NOTES'] || "Automated build from GitHub Actions",
       )
     end

     desc "Build signed IPA without uploading (PR smoke)"
     lane :archive_only do
       match(type: "appstore", readonly: true)
       build_app(
         workspace: "Runner.xcworkspace",
         scheme: "Runner",
         configuration: "Release",
         export_method: "app-store",
         output_directory: "../build/ios/ipa",
         output_name: "Retraq.ipa",
       )
     end
   end
   ```
3. Use `match` with a private GitHub repo for cert/profile sync. `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTHORIZATION` as secrets.
4. Replace iOS block in `release.yml`:
   ```yaml
   - name: Decode App Store Connect API key
     run: echo "$APPSTORE_P8_BASE64" | base64 --decode > ios/AuthKey.p8
     env:
       APPSTORE_P8_BASE64: ${{ secrets.APPSTORE_P8_BASE64 }}
   - name: Install fastlane
     working-directory: ios
     run: bundle install
   - name: Build and upload to TestFlight
     working-directory: ios
     run: bundle exec fastlane beta
     env:
       APPSTORE_KEY_ID: ${{ secrets.APPSTORE_KEY_ID }}
       APPSTORE_ISSUER_ID: ${{ secrets.APPSTORE_ISSUER_ID }}
       APPSTORE_P8: ${{ secrets.APPSTORE_P8 }}
       MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
       MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
       MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
       RELEASE_NOTES: ${{ github.event.release.body }}
   ```
5. For PRs, optionally run `archive_only` lane (`readonly: true`) behind a label to keep CI minutes low.
6. Local `scripts/build-ios.sh` wraps `bundle exec fastlane archive_only` so the Windows/macOS split is not a prod-only concern.

#### Test plan
- Dry-run via `workflow_dispatch` on a scratch tag (`v0.0.0-testflight-smoke`); confirm IPA uploads to TestFlight internal group.
- Verify build processes and shows in App Store Connect within 10 minutes.
- Revoke API key if lane fails mid-upload; confirm rotation documented in `docs/release-runbook.md`.
- Charles/mitmproxy not applicable — upload goes to `api.appstoreconnect.apple.com` directly.

#### Acceptance criteria
- [ ] Pipeline green on feature branch with `archive_only` lane
- [ ] Tag push on main produces TestFlight build visible to internal testers within 15 minutes
- [ ] No secrets in the diff; `.p8` never committed; `AuthKey.p8` gitignored
- [ ] `docs/release-runbook.md` updated with rotation steps
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `ci:` prefix referencing Task 10.2

#### Dependencies
- External: Apple Developer enrolment active, App Store Connect API key generated, match repo provisioned
- Blocks: Task 10.7 (Play Store + TestFlight deployment) — this is the iOS half
- Blocked by: `com.retraq.app` bundle ID registered in App Store Connect

---

### Task 10.3 — Align `.fvmrc` Flutter version with CI (3.41.6)

**Source:** A10 finding "Flutter version mismatch FVM vs CI" · **Rating:** Manual
**Priority:** P0 · **Effort:** XS · **Tier:** v1

#### Problem
`app/.fvmrc` pins `3.32.1` while `ci.yml:22` and `release.yml:22` run `3.41.6`. Any developer using FVM locally resolves a different Dart SDK than CI, producing analyzer warnings, lint rule drift, and pub-lock resolution differences that don't show until PR time.

#### Root cause
`.fvmrc` was hand-written and never re-synced when CI was bumped.

#### Files touched
- `app/.fvmrc`
- `.github/workflows/ci.yml` — add assertion step
- `.github/workflows/release.yml` — add assertion step
- `docs/contributing.md` — note FVM command

#### Implementation approach
1. Update `.fvmrc` to the exact version CI uses. File contents in full:
   ```json
   {
     "flutter": "3.41.6",
     "flavors": {}
   }
   ```
2. Add a single shared assertion step to both workflows, run immediately after checkout:
   ```yaml
   - name: Assert .fvmrc matches CI Flutter version
     shell: bash
     run: |
       set -euo pipefail
       CI_VERSION="3.41.6"
       FVMRC_VERSION=$(jq -r '.flutter' app/.fvmrc)
       if [ "$CI_VERSION" != "$FVMRC_VERSION" ]; then
         echo "::error::.fvmrc ($FVMRC_VERSION) does not match CI Flutter ($CI_VERSION)"
         exit 1
       fi
       echo "OK: .fvmrc and CI agree on Flutter $CI_VERSION"
   ```
3. Bonus: add a single source-of-truth env at workflow top — `env: FLUTTER_VERSION: "3.41.6"` — and reference it in both the `subosito/flutter-action` step and the assertion step so future bumps are a one-line change.
4. Document `fvm use 3.41.6` in contributing guide.

#### Test plan
- Modify `.fvmrc` to a wrong version on a scratch branch → CI must fail with the error line above.
- Revert → CI must pass.
- Run `fvm flutter --version` locally and confirm `3.41.6`.

#### Acceptance criteria
- [ ] Pipeline green on feature branch with `.fvmrc` = 3.41.6
- [ ] Intentionally broken `.fvmrc` fails CI with the expected message
- [ ] Merged to main with CI passing
- [ ] No secrets in the diff
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `build:` prefix referencing Task 10.3

#### Dependencies
- None (pure config)

---

## P1 — Release hardening

### Task 10.4 — Fail loud when Android release build falls back to debug keystore

**Source:** A10 finding "Android release signing dual-path" · **Rating:** Automated
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
The Automated rating covers happy-path signing, but the review recommendation is specific: *"Fail loud in release when no real keystore instead of silently using debug."* Today `build.gradle.kts` falls back to the debug config if `key.properties` is missing — a silent miss would ship a debug-signed AAB indistinguishable by eye.

#### Root cause
Dual-path design intentionally falls back to debug for developer convenience; release mode inherits the same fallback.

#### Files touched
- `android/app/build.gradle.kts`

#### Implementation approach
1. Gate the fallback on build type. Keep dev UX but hard-fail release:
   ```kotlin
   buildTypes {
       getByName("release") {
           val hasRealKeystore = signingConfigs.findByName("release")
               ?.storeFile?.exists() == true
           if (!hasRealKeystore) {
               if (gradle.startParameter.taskNames.any {
                       it.contains("Release", ignoreCase = true) &&
                       (it.contains("assemble") || it.contains("bundle"))
                   }) {
                   throw GradleException(
                       "Release build attempted without real keystore. " +
                       "Set KEYSTORE_BASE64 + signing secrets in CI, " +
                       "or create android/key.properties locally."
                   )
               }
           }
           signingConfig = signingConfigs.getByName(
               if (hasRealKeystore) "release" else "debug"
           )
       }
   }
   ```
2. Add a CI log line after signing resolves: `echo "Signed with SHA-256: $(keytool -list -v ...)"` so the fingerprint is visible in release runs.

#### Test plan
- Local `flutter build apk --debug` still works without `key.properties`.
- Local `flutter build appbundle --release` without `key.properties` fails with the new error message.
- CI `release.yml` with secrets still passes.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] Intentional secret-unset CI run fails at gradle step
- [ ] No secrets in the diff
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `build:` prefix referencing Task 10.4

#### Dependencies
- None

---

### Task 10.5 — Rename "Isar schemas" to "Drift schemas" in build scripts

**Source:** A10 finding "Stale 'Isar schemas' references (project uses Drift)" · **Rating:** Manual
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`scripts/setup.sh:11`, `scripts/build-android.sh:29`, `scripts/build-ios.sh:27` all emit "Generating Isar schemas…" even though the app migrated to Drift months ago. Confusing for new contributors and misleading in CI logs.

#### Root cause
Script comments were not updated during the Isar → Drift migration.

#### Files touched
- `scripts/setup.sh`
- `scripts/build-android.sh`
- `scripts/build-ios.sh`

#### Implementation approach
1. `sed -i 's/Isar schemas/Drift schemas/g'` on the three files — or an explicit `Edit` per file to keep the diff reviewable.
2. Double-check no other string references linger: `grep -rn "Isar" scripts/ lib/ android/ ios/`.

#### Test plan
- Run each script locally and confirm new log line.
- Grep post-change returns zero "Isar" matches outside review/history documents.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] No `Isar` string outside review/history docs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore:` prefix referencing Task 10.5

#### Dependencies
- None

---

### Task 10.6 — Add prerequisite checks to build scripts

**Source:** A10 finding "Build scripts lack prerequisite checks" · **Rating:** Manual
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`scripts/setup.sh`, `build-android.sh`, `build-ios.sh` fail late with cryptic errors when `flutter`, `dart`, `java`, or `fvm` are missing, or the Flutter version diverges from `.fvmrc`.

#### Root cause
Scripts assume a blessed dev environment and skip `command -v` / version assertions.

#### Files touched
- `scripts/setup.sh`
- `scripts/build-android.sh`
- `scripts/build-ios.sh`
- `scripts/_prereq.sh` — new shared helper

#### Implementation approach
1. Add `scripts/_prereq.sh`:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   require_cmd() {
     if ! command -v "$1" >/dev/null 2>&1; then
       echo "::error::Required command '$1' not found on PATH."
       exit 127
     fi
   }

   require_flutter_version() {
     local expected="$1"
     local actual
     actual=$(flutter --version --machine | grep -o '"frameworkVersion": *"[^"]*"' | cut -d'"' -f4)
     if [ "$expected" != "$actual" ]; then
       echo "::error::Flutter version mismatch: expected $expected, got $actual."
       echo "Run: fvm use $expected"
       exit 1
     fi
   }
   ```
2. Each script sources it:
   ```bash
   source "$(dirname "$0")/_prereq.sh"
   require_cmd flutter
   require_cmd dart
   EXPECTED=$(jq -r '.flutter' .fvmrc)
   require_flutter_version "$EXPECTED"
   ```
3. `build-android.sh` additionally requires `java`, `gradle` or `./gradlew`; `build-ios.sh` requires `xcodebuild`, `pod`.

#### Test plan
- Temporarily rename `flutter` on PATH → script exits with message 127.
- Flutter version mismatch → script exits with explicit message.
- Normal path unchanged.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] Missing-tool scenarios produce readable errors
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore:` prefix referencing Task 10.6

#### Dependencies
- Relates to Task 10.3 (shares the `.fvmrc` version assertion idea)

---

### Task 10.7 — Wire Play Store internal track deployment

**Source:** A10 finding "No Play Store / TestFlight deployment" · **Rating:** Manual
**Priority:** P1 · **Effort:** M · **Tier:** v1

#### Problem
`release.yml` only uploads artifacts to GitHub; nothing lands in Play Console or TestFlight automatically. iOS side is Task 10.2; this task covers the Android half.

#### Root cause
Release workflow was built to produce signed AABs but stop there — deployment integration was deferred.

#### Files touched
- `.github/workflows/release.yml`
- `android/fastlane/` — alternative if we prefer fastlane parity with iOS (Task 10.2)
- `docs/release-runbook.md`

#### Implementation approach
Option A (simplest, keep GH Actions): `r0adkll/upload-google-play@v1` pinned to a SHA.
```yaml
- name: Upload AAB to Play Console internal track
  uses: r0adkll/upload-google-play@935ef9c68bb393a8e6116b1575626a7f5be3a7fb # v1.1.3
  with:
    serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
    packageName: com.retraq.app
    releaseFiles: app/build/app/outputs/bundle/release/app-release.aab
    track: internal
    status: draft
    whatsNewDirectory: distribution/whatsnew
```

Option B (parity): `android/fastlane/Fastfile` with a `supply` lane that does the same, mirroring Task 10.2 style. Recommended once fastlane is already in the repo for iOS.

Pick B for consistency once 10.2 lands.

#### Test plan
- Scratch tag dry run; confirm AAB appears in Play Console internal track as a draft (do not promote).
- Service account has only `Release manager` scope, not full admin.
- Rotate documented in runbook.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] Internal tester can install via Play Store after draft is promoted
- [ ] No secrets in the diff; JSON only via `secrets.PLAY_SERVICE_ACCOUNT_JSON`
- [ ] Runbook updated
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `ci:` prefix referencing Task 10.7

#### Dependencies
- External: Google Play service account JSON with Release Manager scope
- Blocked by: Task 10.4 (fail-loud) landing first so no one ships a debug-signed bundle
- Pairs with: Task 10.2 (iOS half)

---

### Task 10.8 — Upload LCOV coverage to Codecov

**Source:** A10 finding "CI pipeline (analyze, format, test, coverage, smoke builds, integration)" · **Rating:** Automated
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`codecov.yml` with a 70% patch threshold is committed, but `ci.yml` never actually uploads the LCOV file — the config is inert.

#### Root cause
Codecov integration was half-wired: config present, upload step forgotten.

#### Files touched
- `.github/workflows/ci.yml`

#### Implementation approach
1. After the test step that produces `coverage/lcov.info`:
   ```yaml
   - name: Upload coverage to Codecov
     uses: codecov/codecov-action@ad3126e916f78f00edff4ed0317cf185271ccc2d # v5.4.2
     with:
       token: ${{ secrets.CODECOV_TOKEN }}
       files: coverage/lcov.info
       fail_ci_if_error: false
       verbose: true
   ```
2. `fail_ci_if_error: false` keeps Codecov outages from bricking CI; the 70% patch gate is enforced by Codecov's PR comment, not the workflow itself.

#### Test plan
- PR with coverage drop → Codecov comment flags it.
- Codecov outage → CI still passes.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] Codecov report visible on PR
- [ ] No secrets in the diff
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `ci:` prefix referencing Task 10.8

#### Dependencies
- External: `CODECOV_TOKEN` secret

---

### Task 10.9 — Add CI enforcement of l10n/ARB regeneration

**Source:** A10 finding "No CI enforcement of l10n/ARB regeneration" · **Rating:** Manual
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`l10n.yaml` exists, but nothing in CI asserts that `flutter gen-l10n` output is current. Translators can edit `.arb` files and the generated Dart stays stale until someone notices in review.

#### Root cause
Code-gen step runs in scripts but the diff is never asserted in CI.

#### Files touched
- `.github/workflows/ci.yml`

#### Implementation approach
1. After the existing `flutter pub get`:
   ```yaml
   - name: Regenerate l10n and fail on drift
     shell: bash
     run: |
       set -euo pipefail
       flutter gen-l10n
       if ! git diff --quiet -- lib/l10n ; then
         echo "::error::Stale l10n output. Run 'flutter gen-l10n' and commit."
         git --no-pager diff -- lib/l10n
         exit 1
       fi
   ```
2. Same pattern can later be extended to `dart run build_runner` for Drift if desired.

#### Test plan
- Edit an `.arb` file without running `gen-l10n` → CI fails with diff.
- Regenerate → CI passes.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] Intentional stale-ARB test fails CI
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `ci:` prefix referencing Task 10.9

#### Dependencies
- None

---

## P2 — Cross-platform dev UX and supply chain

### Task 10.10 — Port build scripts to Dart (or add PowerShell equivalents)

**Source:** A10 finding "Build scripts Bash-only, non-portable on Windows dev box" · **Rating:** Manual
**Priority:** P2 · **Effort:** M · **Tier:** v1.1

#### Problem
The primary dev box is Windows (per memory/project_targets.md); `setup.sh`, `build-android.sh`, `build-ios.sh` require WSL or Git Bash. New contributors on Windows cannot follow the README verbatim.

#### Root cause
Scripts were written on macOS and never ported.

#### Files touched
- `tool/build.dart` — new Dart entrypoint
- `tool/src/setup.dart`, `tool/src/build_android.dart`, `tool/src/build_ios.dart`
- `pubspec.yaml` — dev dependency `args`
- `README.md`, `docs/contributing.md`
- Keep `scripts/*.sh` as thin wrappers that call `dart run tool/build.dart <cmd>`

#### Implementation approach
1. Single-binary Dart CLI:
   ```dart
   // tool/build.dart
   void main(List<String> argv) {
     final runner = CommandRunner('retraq', 'Retraq build helpers')
       ..addCommand(SetupCommand())
       ..addCommand(BuildAndroidCommand())
       ..addCommand(BuildIosCommand());
     runner.run(argv);
   }
   ```
2. Each command wraps existing logic with `Process.run`, so CI can call `dart run tool/build.dart setup` cross-platform.
3. `.sh` wrappers become one-liners for muscle memory. No `.ps1` needed (Dart handles Windows).

#### Test plan
- Run `dart run tool/build.dart setup` on Windows cmd, macOS zsh, Linux bash.
- CI uses Dart command on every runner.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] Windows contributor can run setup without WSL
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore:` prefix referencing Task 10.10

#### Dependencies
- Depends on Task 10.6 (prereq checks) so the Dart port inherits the same guards

---

### Task 10.11 — Evaluate `ios-podfile` ecosystem for Dependabot

**Source:** A10 finding "Dependabot covers pub, gradle, github-actions weekly" · **Rating:** Automated
**Priority:** P2 · **Effort:** XS · **Tier:** v1.1

#### Problem
Dependabot already watches pub, gradle, and GitHub Actions. iOS CocoaPods are not monitored — there is no `ios-podfile` ecosystem in GitHub Dependabot yet, but `cocoapods` via `bundler` (Gemfile) is. Worth a quick evaluation.

#### Root cause
No current support in Dependabot for `Podfile.lock`; only `Gemfile` is parsable.

#### Files touched
- `.github/dependabot.yml` — add `bundler` block covering `ios/Gemfile` (once Task 10.2 introduces one)

#### Implementation approach
1. After Task 10.2 adds `ios/Gemfile` for fastlane, extend Dependabot:
   ```yaml
   - package-ecosystem: "bundler"
     directory: "/ios"
     schedule:
       interval: "weekly"
     open-pull-requests-limit: 5
   ```
2. Document in `docs/dependency-policy.md` that native Pod updates remain manual via `pod outdated`.

#### Test plan
- Dependabot dry run on fork; confirm PRs land for fastlane minor bumps.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] Bundler PRs arrive weekly
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `ci:` prefix referencing Task 10.11

#### Dependencies
- Blocked by: Task 10.2 (iOS fastlane introduces the Gemfile)

---

### Task 10.12 — Introduce hand-curated CHANGELOG.md

**Source:** A10 finding "No CHANGELOG.md; auto-generated release notes" · **Rating:** Automated
**Priority:** P2 · **Effort:** XS · **Tier:** v1.1

#### Problem
Release notes are auto-generated from commit messages; fine for devs, not for App Store / Play Store review notes which benefit from curated language.

#### Root cause
No human-readable log exists; we lean on GitHub's generator.

#### Files touched
- `CHANGELOG.md`
- `.github/workflows/release.yml` — optionally consume the top section as the release body
- `docs/release-runbook.md`

#### Implementation approach
1. Adopt Keep-a-Changelog format with an `[Unreleased]` section.
2. `release.yml` uses `sed`/`awk` to extract the `## [X.Y.Z]` block and post it as the release body (and pipe to `fastlane upload_to_testflight changelog:`).
3. PR template checkbox: "Added a CHANGELOG entry."

#### Test plan
- Cut a scratch release; confirm store-review notes pull from CHANGELOG, not git log.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] First entry covers v1.0.0
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore:` prefix referencing Task 10.12

#### Dependencies
- None

---

## v2 — Deferred until backend/paywall exists

### Task 10.13 — Introduce dev/staging/prod product flavors

**Source:** A10 finding "No dev/staging/prod flavor configs" · **Rating:** Missing
**Priority:** P3 · **Effort:** XL · **Tier:** v2

#### Problem
Single `applicationId com.retraq.app`. No flavor for internal testing, no way to run dev and prod side-by-side on the same device.

#### Root cause
Nothing to differentiate — app is local-only, no backend URL to switch, no paywall envs yet. Review rating explicitly says *"Introduce flavors once backend/paywall exists."*

#### Files touched
- `android/app/build.gradle.kts` — `productFlavors { dev { applicationIdSuffix ".dev" } ... }`
- `ios/Runner.xcodeproj/*` — schemes + xcconfig per flavor
- `.github/workflows/release.yml`, `ci.yml` — matrix over flavors
- `lib/config/environment.dart` — new
- `scripts/build-android.sh`, `build-ios.sh`, `tool/build.dart`

#### Implementation approach
1. Defer until a paywall environment (RevenueCat sandbox vs prod) or backend URL exists. Revisit at v1.1 planning.
2. Sketch only: dev → `.dev` suffix, grey icon; staging → `.staging`, orange icon; prod → canonical.
3. Environment config via `--dart-define` per flavor: `RETRAQ_ENV=dev|staging|prod`.

#### Test plan
- All three installable side-by-side on a test device.
- Analytics/Crashlytics environment tag routes correctly.

#### Acceptance criteria
- [ ] Pipeline green on feature branch
- [ ] All three flavors build signed artifacts in CI
- [ ] No secrets leaked across flavor configs
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `build:` prefix referencing Task 10.13

#### Dependencies
- Blocked by: RevenueCat sandbox env or any backend URL existing — currently neither
- Blocked by: Task 10.1 (Sentry environment tagging is flavor-aware)

---

## Reference entries (Automated — no action, for traceability)

### Task 10.14 — Tag-driven release versioning (reference)

**Source:** A10 finding "Tag-driven release with parsed versioning from `vX.Y.Z+N`" · **Rating:** Automated
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. `release.yml:104-116` parses `v1.2.3+45` correctly into `versionName` + `versionCode`. The recommendation ("Add iOS codesign + TestFlight upload") is tracked in Task 10.2.

#### Root cause
n/a — working as intended.

#### Files touched
- n/a

#### Implementation approach
1. Keep. Do not change without bumping Task 10.2 first.

#### Test plan
- n/a

#### Acceptance criteria
- [ ] No change

#### Dependencies
- Referenced by Task 10.2 (iOS TestFlight)

---

### Task 10.15 — SHA-pinned GitHub Actions (reference)

**Source:** A10 finding "SHA-pinned GitHub Actions" · **Rating:** Automated
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. All third-party actions in `ci.yml:18-173` and `release.yml:18-139` are pinned by commit SHA — supply-chain best practice. Review: *"Keep."*

#### Root cause
n/a

#### Files touched
- n/a (new actions added by Tasks 10.1/10.2/10.7/10.8 must follow the same SHA-pin rule — enforced via PR review)

#### Implementation approach
1. When adding any new action, pin by SHA and include the version in a trailing comment: `uses: actions/foo@<sha>  # v1.2.3`.

#### Test plan
- n/a; lint via PR review.

#### Acceptance criteria
- [ ] No change

#### Dependencies
- Cross-cuts every CI task

---

### Task 10.16 — `pubspec.lock` committed (reference)

**Source:** A10 finding "pubspec.lock committed" · **Rating:** Automated
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Lock file is correctly committed per Dart guidance for application projects. Review: *"Correct for app projects."*

#### Root cause
n/a

#### Files touched
- n/a

#### Implementation approach
1. Keep committed.

#### Test plan
- n/a

#### Acceptance criteria
- [ ] No change

#### Dependencies
- None

---

### Task 10.17 — Code generation integrated into every workflow (reference)

**Source:** A10 finding "Code generation integrated into every workflow + script" · **Rating:** Automated
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. `ci.yml:30`, `release.yml:30`, `setup.sh:12` all run `build_runner`. `.g.dart` is gitignored and regenerated.

#### Root cause
n/a

#### Files touched
- n/a

#### Implementation approach
1. Keep.

#### Test plan
- n/a

#### Acceptance criteria
- [ ] No change

#### Dependencies
- Task 10.9 (ARB regeneration) is the analogous check for l10n output

---

### Task 10.18 — Coverage thresholds 45/70/70 (reference)

**Source:** A10 finding "Coverage thresholds (45% CI, 70% release, 70% Codecov patch)" · **Rating:** Automated
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Tiered gating — lenient on PR, strict on release — is the review's recommended pattern.

#### Root cause
n/a

#### Files touched
- n/a

#### Implementation approach
1. Keep. Revisit thresholds after Task 10.8 surfaces real coverage numbers.

#### Test plan
- n/a

#### Acceptance criteria
- [ ] No change

#### Dependencies
- Task 10.8 (Codecov upload)

---

### Task 10.19 — Smoke build on PR (reference)

**Source:** A10 finding "Smoke build on PR catches release-mode R8/ProGuard failures" · **Rating:** Automated
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. `ci.yml:72-114` builds `--release` on every PR and has already caught at least one ProGuard regression in history.

#### Root cause
n/a

#### Files touched
- n/a

#### Implementation approach
1. Keep.

#### Test plan
- n/a

#### Acceptance criteria
- [ ] No change

#### Dependencies
- None

---

### Task 10.20 — Gradle + Flutter caching (reference)

**Source:** A10 finding "Gradle + Flutter cache enabled" · **Rating:** Automated
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Caching in `ci.yml:89-95` and `release.yml:76-82` keeps CI runtimes reasonable.

#### Root cause
n/a

#### Files touched
- n/a

#### Implementation approach
1. Keep. If CI time grows, revisit `actions/cache` keys before reaching for self-hosted runners.

#### Test plan
- n/a

#### Acceptance criteria
- [ ] No change

#### Dependencies
- None

---

### Task 10.21 — iOS DEVELOPMENT_TEAM via xcconfig (reference)

**Source:** A10 finding "iOS DEVELOPMENT_TEAM via xcconfig variable" · **Rating:** Automated
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. `ios/Runner.xcodeproj/project.pbxproj:366,547,571` reads team ID from xcconfig — no team identifier committed.

#### Root cause
n/a

#### Files touched
- n/a

#### Implementation approach
1. Keep. Task 10.2 will set the team ID via fastlane env, not via project file.

#### Test plan
- n/a

#### Acceptance criteria
- [ ] No change

#### Dependencies
- Referenced by Task 10.2

---

## Summary

- **22 tasks**, one per row of the Agent 10 Detailed Findings Table.
- **3 P0** launch blockers: crash reporting (Sentry), iOS TestFlight automation, `.fvmrc` alignment.
- **6 P1** hardening items: fail-loud signing, Drift rename, script prereq checks, Play Store deploy, Codecov upload, l10n drift check.
- **3 P2** dev-UX/supply-chain: Dart port, Dependabot bundler, CHANGELOG.
- **1 v2** deferred: product flavors.
- **8 no-op** reference entries for already-Automated findings.

Execution order for launch: 10.3 → 10.5 → 10.4 → 10.9 → 10.8 → 10.1 → 10.2 → 10.7 → 10.6. Remaining items can land post-launch.
