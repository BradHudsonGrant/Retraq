# Epic 3 — Security & Privacy Hardening

Source: review-2026-04-16.md §Agent 3

Tier legend: `v1` = must-ship before 1.0 launch · `v1.1` = fast-follow patch · `v2` = post-launch (cloud sync / caregiver) · `backlog` = nice-to-have · `no-op` = documented as intentional, no code change.

---

## P0 — Launch blockers (Vulnerable / correctness)

### Task 3.1 — Set `AndroidOptions(encryptedSharedPreferences: true)` on hardened secure storage

**Source:** A3 finding "`AndroidOptions()` default, NOT `encryptedSharedPreferences: true`" · **Rating:** Weak
**Priority:** P0 · **Effort:** XS · **Tier:** v1

#### Problem
`lib/services/secure_storage.dart:12-15` declares a `hardenedSecureStorage` with a leading docstring promising `EncryptedSharedPreferences (Jetpack Security)`, but the actual `AndroidOptions()` constructor is empty — which on `flutter_secure_storage` v10 defaults to RSA/ECB/PKCS1Padding wrapping of values stored in plain SharedPreferences XML. Implementation contradicts documented intent.

#### Root cause
The flag was either dropped in a refactor or never set. The docstring was written for the intended behaviour and drifted from the code.

#### Threat model
- **Who:** An attacker with physical access to an unlocked/rooted device, forensic extraction (Cellebrite / ADB backup on older Android) or a malicious app with root.
- **What they gain:** Access to the encrypted SQLite database key (`_dbKeyName`), lockout state, biometric unlock flags. Possessing the DB key lets them decrypt the journal offline.
- **How:** Pull `/data/data/com.retraq.app/shared_prefs/FlutterSecureStorage.xml`, attack the RSA-wrapped blob using known padding-oracle / key-extraction techniques against the StrongBox-less RSA key.

#### Files touched
- `lib/services/secure_storage.dart:12-15` — enable `encryptedSharedPreferences: true`
- `test/services/secure_storage_test.dart` (new) — assert option is set
- `docs/audit-2026-04-07.md` or new security CHANGELOG entry — note the migration

#### Implementation approach
1. Update the const to pass the flag and (optionally) a dedicated preferences file name:
   ```dart
   const hardenedSecureStorage = FlutterSecureStorage(
     aOptions: AndroidOptions(
       encryptedSharedPreferences: true,
       // keystoreAlias optional; default is acceptable
     ),
     iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
   );
   ```
2. Handle migration: on first run after upgrade, `flutter_secure_storage` will auto-migrate keys from RSA-wrapped prefs to EncryptedSharedPreferences. Verify by running a pre-upgrade build that writes a test key, then the new build that reads it.
3. Add a one-shot read of every secure-storage key on app init wrapped in try/catch — if any key throws `PlatformException` (migration failure), re-derive / regenerate rather than crash:
   ```dart
   // lib/services/secure_storage.dart
   Future<void> warmUpSecureStorage() async {
     for (final key in _knownKeys) {
       try { await hardenedSecureStorage.read(key: key); }
       catch (e) { await _handleMigrationFailure(key, e); }
     }
   }
   ```
4. If DB key read fails after migration, app must surface a clear recovery screen (ties into Task 3.4 forgot-PIN fallback) rather than silently re-keying and orphaning the encrypted DB.

#### Test plan
- Unit test asserting the `AndroidOptions` is constructed with `encryptedSharedPreferences == true` (reflect via `toMap()` or wrap in a factory).
- Manual upgrade drill on Pixel 10 Pro: install v1.0.0 (pre-fix), create PIN + entries, upgrade to v1.0.1 (post-fix), verify app still unlocks and DB decrypts.
- Regression: `flutter analyze`, `flutter test` (full 445+ suite).
- Forensic spot check: `adb shell run-as com.retraq.app cat shared_prefs/*.xml` — confirm no RSA-wrapped Base64 blobs survive after a fresh install.

#### Acceptance criteria
- [ ] `AndroidOptions(encryptedSharedPreferences: true)` present in `secure_storage.dart`
- [ ] Upgrade-in-place from pre-fix build preserves PIN + DB unlock
- [ ] No readable values in `shared_prefs/*.xml` for a fresh install
- [ ] DB extracted from device cannot be decrypted without secure-storage key
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `fix(security):` prefix referencing Task 3.1

#### Dependencies
- Blocks Task 3.4 (needs reliable secure storage before adding forgot-PIN biometric gate).

---

### Task 3.2 — Gate "Forgot PIN" wipe behind biometric/device-passcode and offer encrypted export

**Source:** A3 finding "'Forgot PIN' wipes all data after lockoutCount >= 2, no recovery path" · **Rating:** Weak
**Priority:** P0 · **Effort:** L · **Tier:** v1

#### Problem
`lib/screens/lock_screen.dart:168-198,278-290` exposes a "Forgot PIN" action that, once `lockoutCount >= 2`, unconditionally wipes the encrypted DB and secure-storage keys. An attacker with physical access who triggers 60 failed attempts (5 attempts × 2 lockout cycles) can irreversibly destroy the user's journal. Combined with `allowBackup=false` and no cloud copy, data is unrecoverable.

#### Root cause
The wipe is the single exit path from a forgotten PIN. No re-auth challenge, no export-before-wipe, no undo window.

#### Threat model
- **Who:** Someone who gets the phone unlocked briefly (roommate, co-worker, thief who shoulder-surfed the unlock PIN) but does not know the app PIN, or a malicious actor with short physical access.
- **What they gain:** Destructive denial-of-service against the user's journal — a targeted "delete someone's diary" attack.
- **How:** Open app, spam wrong PIN through 2 lockout cycles, tap "Forgot PIN", confirm → all data gone.

#### Files touched
- `lib/screens/lock_screen.dart:168-198,278-290` — replace direct wipe with multi-step flow
- `lib/services/export_service.dart` — add `exportEncryptedBackup(String userPassphrase)` returning a file path
- `lib/services/pin_service.dart` — no change (PIN is still lost)
- New `lib/screens/forgot_pin_screen.dart` — hosts the new flow
- `test/screens/lock_screen_test.dart` + new `test/screens/forgot_pin_screen_test.dart`

#### Implementation approach
1. **Step 1 — Strong re-auth before wipe** (biometric if enrolled, else device-credential fallback via `local_auth`):
   ```dart
   final ok = await LocalAuthentication().authenticate(
     localizedReason: 'Confirm it is you before erasing your journal',
     options: const AuthenticationOptions(
       biometricOnly: false,  // allow device PIN/pattern as fallback
       stickyAuth: true,
     ),
   );
   if (!ok) return;
   ```
   If no biometric and no device credential enrolled, require the user to type a confirmation phrase (`ERASE`) in locale.
2. **Step 2 — Offer encrypted export**: before wiping, prompt user with three options: `Cancel`, `Export encrypted backup then erase`, `Erase only`. Encrypted export takes a new passphrase (min 12 chars), derives a key via Argon2id (add `cryptography` or `argon2` pub dep) and writes an AES-GCM envelope over the JSON export. The file goes through the share sheet — user is responsible for storing it.
3. **Step 3 — 10-second undo**: after wipe command, show a non-dismissible SnackBar with countdown "Erasing in 10s — Tap to cancel". Actual DB/secure-storage wipe is scheduled via `Timer(10s, _performWipe)`. Cancelling clears the timer.
4. **Step 4 — Telemetry-free audit log**: append `wipe_initiated_at` / `wipe_completed_at` to a local `security_events.log` that survives wipe via secure-storage key only readable after next PIN setup. Helpful for the user to see "this happened at X" if device is recovered. (Optional — skip if adds scope; note in v1.1.)

#### Data-recovery / undo design notes
- **Undo window:** 10 s cancellable timer covers "fat-finger" scenarios.
- **Encrypted export before wipe:** user controls key; if they lose passphrase, data is still gone (acceptable — warned on the export screen).
- **No silent data destruction:** every wipe path now requires (a) device-level re-auth AND (b) explicit "Erase only" tap.
- **Future:** when cloud sync lands (v2) the wipe can be made reversible via a server-side soft-delete window.

#### Test plan
- Unit: forgot-PIN flow requires biometric/device-cred success before wipe fires.
- Unit: export-then-wipe produces a file + clears DB in correct order; cancel aborts both.
- Widget: 10 s undo SnackBar cancels timer on tap.
- Manual security drill: enroll biometric, trigger 2 lockouts, attempt wipe with biometric denial — data must remain.
- Manual drill: export encrypted backup, wipe, reinstall, import backup with correct/wrong passphrase.
- Regression: full `flutter test`.

#### Acceptance criteria
- [ ] Cannot reach wipe without biometric OR device passcode OR typed `ERASE` confirmation
- [ ] Encrypted export option produces a file the app can re-import
- [ ] 10-second undo cancels the wipe reliably
- [ ] Wipe zeroes DB file (existing `.bak` path extended to main DB) before deletion
- [ ] DB extracted before wipe cannot be decrypted without the exported passphrase
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(security):` prefix referencing Task 3.2

#### Dependencies
- Depends on Task 3.1 (stable secure storage).
- Pulls in `local_auth` (already in pubspec) and a new AEAD lib — check `cryptography` package licensing before adding.

---

### Task 3.3 — Fail the release build when no real Android keystore is configured

**Source:** A3 finding "Debug key fallback if neither keystore found" · **Rating:** Weak
**Priority:** P0 · **Effort:** XS · **Tier:** v1

#### Problem
`android/app/build.gradle.kts:78-80` silently falls back to debug signing when `key.properties` is missing and the env-var path fails. A release APK/AAB can ship signed with the universally known Android debug key, opening the door to malicious updates published via sideload channels.

#### Root cause
The fallback exists to keep local `flutter run --release` working without requiring every dev to have the prod keystore.

#### Threat model
- **Who:** Anyone who grabs a release build signed with debug key.
- **What they gain:** Ability to produce a "fake update" APK signed with the same (public) debug key that the Android installer will accept as an in-place upgrade on a sideloaded install.
- **How:** Sign a trojaned APK with the public Android debug key, convince user to sideload as an "update".

#### Files touched
- `android/app/build.gradle.kts:42-80` — add CI guard
- `android/key.properties.example` — document required fields
- `.github/workflows/release.yml` (if exists) or new CI check — fail PR if release target selected without keystore

#### Implementation approach
1. Replace silent fallback with an explicit error in `buildTypes.release`:
   ```kotlin
   buildTypes {
       getByName("release") {
           val hasKeystore = file("../key.properties").exists() ||
               (System.getenv("RETRAQ_KEYSTORE_PATH") != null)
           if (!hasKeystore && gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }) {
               throw GradleException(
                   "Release keystore not configured. Set RETRAQ_KEYSTORE_PATH env or create android/key.properties."
               )
           }
           signingConfig = signingConfigs.getByName(if (hasKeystore) "release" else "debug")
           // ...
       }
   }
   ```
2. Allow debug-signed release only when `RETRAQ_ALLOW_DEBUG_SIGN=1` is set (local dev override, never in CI).
3. CI check: add a workflow step that asserts `RETRAQ_ALLOW_DEBUG_SIGN` is unset on `main` branch builds.

#### Test plan
- Local: run `flutter build appbundle --release` without keystore → must fail with clear message.
- Local with override: `RETRAQ_ALLOW_DEBUG_SIGN=1 flutter build apk --release` → succeeds.
- CI: dry-run with no keystore → fails.

#### Acceptance criteria
- [ ] Release build without keystore throws during configuration
- [ ] Override env var works for local dev only
- [ ] CI prevents debug-signed release artifacts
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(security):` prefix referencing Task 3.3

#### Dependencies
- None (pure build-config change).

---

## P1 — Launch-quality hardening (Weak)

### Task 3.4 — Apply FLAG_SECURE unconditionally (not only when app lock is enabled)

**Source:** A3 finding "FLAG_SECURE blocks screenshots + Recents — but only when app lock on" · **Rating:** Weak
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`lib/main.dart:115` calls `ScreenSecurityService.instance.setSecure(enabled)` where `enabled` tracks the app-lock toggle. Users who skip setting a PIN still have all journal content screen-shottable and cached in the Android Recents thumbnail.

#### Root cause
The gate was written as "only users who want lock want screenshot protection" — wrong model: journal content is sensitive regardless of whether the user has a PIN.

#### Threat model
- **Who:** Anyone with momentary access to an unlocked phone (e.g., double-tap Recents), or an OS screenshot API misuse by a malicious app with accessibility service.
- **What they gain:** Thumbnail of the current entry.
- **How:** Open Recents, read visible snippet; install accessibility-abuse app; trigger OS share-sheet screenshot.

#### Files touched
- `lib/main.dart:115-116` — always enable FLAG_SECURE on app start
- `lib/settings/advanced_settings_screen.dart` (or similar) — add user-facing toggle `Disable screen-protection` (default off) for accessibility users who need screen readers / mirroring
- `lib/services/screen_security_service.dart` — no change

#### Implementation approach
1. On app init, call `setSecure(true)` unconditionally.
2. Wire a new `Settings.disableScreenProtection` bool (default `false`). If true, call `setSecure(false)`.
3. Show explanatory dialog the first time user toggles it off: "Disabling this allows screenshots and screen-mirror tools to capture your journal".

#### Test plan
- Unit: settings service reads/writes `disableScreenProtection`.
- Manual on Pixel 10 Pro: without lock enabled, confirm Recents thumbnail is blanked; enable override → thumbnail visible again.
- Regression: `flutter test`.

#### Acceptance criteria
- [ ] Recents thumbnail is blanked on fresh install with no PIN
- [ ] User can opt out via Advanced settings after explicit warning
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(security):` prefix referencing Task 3.4

#### Dependencies
- None.

---

### Task 3.5 — Render lock/blur overlay on `inactive`/`paused`, not only `resumed`

**Source:** A3 finding "Backgrounding shows previous screen briefly before lock overlays" · **Rating:** Weak
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`lib/main.dart:127-131` sets `_isLocked = true` only on `AppLifecycleState.paused`. On many Android OEMs the Recents thumbnail is snapshotted during `inactive` (the transition before `paused`), so the home screen flashes visible before the lock overlay ever paints.

#### Root cause
Naive lifecycle handler assumed `paused` is the earliest signal. Real capture happens during `inactive`.

#### Threat model
- **Who:** Shoulder-surfer, Recents-thumbnail reader.
- **What they gain:** A frame of whatever was on screen (likely current entry).
- **How:** Hit the recents button / app-switcher on the user's unlocked device.

#### Files touched
- `lib/main.dart:127-131` — expand state check
- `lib/widgets/lock_overlay.dart` (or wherever lock overlay is rendered) — add blur layer
- Optional `ios/Runner/AppDelegate.swift` — paint a blur on `applicationWillResignActive` (ties into Task 3.6)

#### Implementation approach
1. Trigger on `inactive` and `paused`:
   ```dart
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
       if (_appLockEnabled) setState(() => _isLocked = true);
       setState(() => _isBlurring = true);  // always blur regardless of lock
     } else if (state == AppLifecycleState.resumed) {
       setState(() => _isBlurring = false);
     }
   }
   ```
2. Add `ImageFiltered(imageFilter: ImageFilter.blur(...))` wrapper over the current screen when `_isBlurring`.

#### Test plan
- Widget test: simulate lifecycle callback with `inactive`, assert blur overlay paints.
- Manual: Pixel 10 Pro, fling to Recents, confirm no readable frame.
- Regression: `flutter test`.

#### Acceptance criteria
- [ ] Recents thumbnail shows blur regardless of lock state
- [ ] Lock overlay paints before `paused` completes
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(security):` prefix referencing Task 3.5

#### Dependencies
- Complements Task 3.4 and Task 3.6.

---

### Task 3.6 — Add iOS blur hook on `applicationWillResignActive`

**Source:** A3 finding "iOS has no FLAG_SECURE equivalent; service no-ops" · **Rating:** Weak (platform limit)
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`lib/services/screen_security_service.dart` is a no-op on iOS because Apple has no direct equivalent of FLAG_SECURE. `review` thumbnails in the iOS app-switcher currently capture whatever is on screen.

#### Root cause
iOS policy: apps must self-blur during `applicationWillResignActive`.

#### Threat model
- **Who:** Shoulder-surfer on iPhone, enterprise MDM screen capture.
- **What they gain:** Snapshot of current entry in the App Switcher.
- **How:** Swipe up to App Switcher.

#### Files touched
- `ios/Runner/AppDelegate.swift` — add UIView overlay on `applicationWillResignActive` / remove on `applicationDidBecomeActive`
- `lib/services/screen_security_service.dart` — document iOS path (no code change on Dart side, or expose a platform channel)
- `ios/Runner/Info.plist` — no change

#### Implementation approach
1. In `AppDelegate.swift`:
   ```swift
   private var privacyOverlay: UIView?

   override func applicationWillResignActive(_ application: UIApplication) {
     super.applicationWillResignActive(application)
     let overlay = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
     overlay.frame = window?.bounds ?? .zero
     overlay.tag = 0xBEEF
     window?.addSubview(overlay)
     privacyOverlay = overlay
   }

   override func applicationDidBecomeActive(_ application: UIApplication) {
     super.applicationDidBecomeActive(application)
     privacyOverlay?.removeFromSuperview()
     privacyOverlay = nil
   }
   ```
2. Coordinate with Task 3.5 so Dart-side and iOS-side blurs don't double-render.

#### Test plan
- Manual on iOS simulator / TestFlight: swipe to App Switcher, verify blur.
- Regression: full test suite (iOS build green).

#### Acceptance criteria
- [ ] iOS App Switcher shows blurred thumbnail
- [ ] Overlay is removed on foreground
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(security):` prefix referencing Task 3.6

#### Dependencies
- User currently only has Pixel 10 Pro for testing (per `user_location.md`/`project_targets.md`); iOS verification must happen via simulator or ship behind feature flag.

---

### Task 3.7 — Raise PBKDF2 iterations to 200-300K and re-version hash

**Source:** A3 finding "PBKDF2-HMAC-SHA256, 16-byte CSPRNG salt, 32-byte key, versioned `v3:iterations:salt:hash` format, legacy v2/SHA-256 auto-upgrade" · **Rating:** Secure (with recommendation)
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`lib/services/pin_service.dart:17` uses 100K PBKDF2 iterations. For a 4-digit PIN (10K keyspace) on modern GPUs, 100K iterations means the entire keyspace cracks in seconds if an attacker ever obtains both the DB *and* the secure-storage export. Key Findings flags this as a hardening opportunity.

#### Root cause
Iteration count was lowered from v2's 600K to 100K, likely to improve cold-start latency. Too aggressive a trim for a 10^4-entropy secret.

#### Threat model
- **Who:** Attacker with offline copy of DB hash and salt (physical-access forensic scenario).
- **What they gain:** Full PIN recovery → full journal decryption.
- **How:** GPU dictionary attack over all 10K possible PINs.

#### Files touched
- `lib/services/pin_service.dart:17,73,124` — bump const to 250K, bump hash version to `v4`
- `lib/services/pin_service_migrations.dart` (create or fold into existing) — add v3→v4 auto-upgrade on next successful unlock
- `test/services/pin_service_test.dart`

#### Implementation approach
1. Change `_iterationsV3` (or equivalent) from `100000` to `250000`.
2. Introduce `_hashVersionV4 = 4`; stored format `v4:250000:<salt>:<hash>`.
3. On successful PIN verify against a `v3` hash, re-derive with v4 and persist.
4. Benchmark on Pixel 10 Pro: unlock latency should stay under ~300 ms (acceptable).

#### Test plan
- Unit: v3 hash verifies, is upgraded to v4, and still verifies next time.
- Perf: measure average verify time on real device (target <400 ms).
- Regression: full `flutter test`.

#### Acceptance criteria
- [ ] New PIN hashes use 250K iterations and `v4` prefix
- [ ] Existing v3 hashes still verify and auto-upgrade
- [ ] Unlock latency regression <100 ms vs. baseline
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(security):` prefix referencing Task 3.7

#### Dependencies
- None.

---

### Task 3.8 — Verify widget never reads DB while locked

**Source:** A3 finding "Widget `exported=true` — required for AppWidgetProvider" · **Rating:** Weak
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`AndroidManifest.xml:38-47` exports the home-screen widget (required by `AppWidgetProvider`). Exported components are reachable by any app. We must confirm the widget never reads decrypted journal content while the app is locked (or, more strictly, at all without a PIN-unlock session token).

#### Root cause
`exported=true` is non-negotiable for widgets; mitigation must happen in widget code, not manifest.

#### Threat model
- **Who:** Malicious app on same device trying to pull widget RemoteViews or launch widget intents.
- **What they gain:** If widget renders entry text, malicious app could scrape it; if widget intents accept extras, could be used as an injection vector.
- **How:** Bind to the widget provider via `AppWidgetManager`, read RemoteViews.

#### Files touched
- `android/app/src/main/kotlin/.../RetraqWidgetProvider.kt` (verify path) — confirm it reads only a static "Open Retraq" label when locked
- `lib/services/widget_bridge_service.dart` (if exists) — ensure no decrypted payload is ever pushed to widget while `_isLocked`
- `test/services/widget_bridge_test.dart`

#### Implementation approach
1. Audit widget code: produce a table of every data item shown → confirm each is either (a) a static string or (b) only pushed after successful unlock.
2. Add guard: `if (SettingsRepo.appLockEnabled && !PinSessionTracker.isUnlocked) { renderGenericWidget(); return; }`.
3. Clear widget data on `AppLifecycleState.paused` when app-lock is on.

#### Test plan
- Unit: widget update path with `_isLocked=true` produces static RemoteViews only.
- Manual: lock app, confirm widget on home screen does not render entry text.
- Regression: full test suite.

#### Acceptance criteria
- [ ] Widget never exposes decrypted content when app is locked
- [ ] Widget clears any cached snippet on `paused`
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `fix(security):` prefix referencing Task 3.8

#### Dependencies
- None.

---

### Task 3.9 — Add in-UI warning on plaintext share-sheet export

**Source:** A3 finding "Export via share sheet writes plaintext JSON/TXT to temp dir, deletes after share; pinHash excluded" · **Rating:** Secure (with recommendation)
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`lib/services/export_service.dart:140-157,470-487` writes plaintext JSON/TXT to the OS temp dir, passes to Android share sheet, then deletes. Destination app (Gmail, Drive, random text editor) receives decrypted data with no visible warning to the user.

#### Root cause
Export UX pre-dates privacy maturity; user consent was implicit.

#### Threat model
- **Who:** A 3rd-party app the user accidentally selects in the share sheet (ad-supported, logging-heavy).
- **What they gain:** Copy of the user's entire journal in cleartext.
- **How:** User taps "Share" → picks the wrong app.

#### Files touched
- `lib/screens/export_screen.dart` (or equivalent) — add pre-share dialog
- Copy strings in ARB files

#### Implementation approach
1. Before invoking `Share.shareXFiles`, show a blocking dialog:
   > Sharing this file sends your journal to the chosen app in readable form. Only pick an app you trust (e.g., your file manager or Drive). Cancel and use the Encrypted backup option for safer storage.
2. Buttons: `Cancel`, `Share anyway`.
3. Persist a "don't show again" checkbox keyed to the same dialog (still show for encrypted vs. plaintext differently).

#### Test plan
- Widget test: share action is blocked on dialog until user taps "Share anyway".
- Manual: verify copy matches brand voice.
- Regression: `flutter test`.

#### Acceptance criteria
- [ ] Plaintext export always requires one-tap explicit consent
- [ ] Encrypted export path (when Task 3.2 lands) shows a different, less alarming notice
- [ ] `flutter analyze` clean, `flutter test` passes
- [ ] Commit pushed with `feat(security):` prefix referencing Task 3.9

#### Dependencies
- Complements Task 3.2 (encrypted export).

---

## P2 — Future-risk (tied to unshipped features)

### Task 3.10 — Design zero-knowledge cloud-sync envelope (future work gate)

**Source:** A3 finding "**Future risk — cloud sync**: `_dbKeyName` in Android EncryptedSharedPreferences + iOS Keychain only" · **Rating:** Future Vulnerable
**Priority:** P2 · **Effort:** XL · **Tier:** v2

#### Problem
Today the DB key lives only in platform secure storage, which is fine for offline-only. The moment we introduce cloud sync, the DB file will travel to a server; unless the server-facing payload is encrypted under a key the server never sees, the operator (or a breach) reveals all journals.

#### Root cause
Cloud sync isn't designed yet. Current architecture doesn't separate "at-rest DB key" from "at-transit/server-side envelope key".

#### Threat model
- **Who:** Server operator (insider risk), server breach attacker, state actor subpoena.
- **What they gain:** All users' plaintext journals.
- **How:** Read DB backups from server; there is no client-side envelope protecting them.

#### Files touched
- `docs/cloud-sync-design.md` (new spec)
- Future: `lib/services/cloud_sync_service.dart` (do not create yet)

#### Implementation approach
1. Spec a zero-knowledge scheme:
   - User chooses a sync passphrase at opt-in (separate from the 4-digit app PIN).
   - Derive a 256-bit root key via Argon2id(passphrase, per-account salt).
   - Wrap the existing DB AES key under AES-KW / AES-GCM with the Argon2 root → store wrapped key on server.
   - Sync payload = AES-GCM(DB_key, serialized_entries) + version + nonce.
2. Document recovery flow: user must retain passphrase; server cannot reset.
3. Document how this interacts with Task 3.2 (encrypted export could reuse same envelope format).

#### Test plan
- N/A (spec only). When implementation begins, define:
  - Unit: envelope round-trip with correct/wrong passphrase.
  - Integration: server never sees plaintext (mock server logs assertion).

#### Acceptance criteria
- [ ] `docs/cloud-sync-design.md` exists with threat model, key hierarchy, recovery flow
- [ ] Review sign-off from user before any code lands
- [ ] Commit pushed with `docs(security):` prefix referencing Task 3.10

#### Dependencies
- Gated on product decision to ship cloud sync (per `project_feature_decisions.md` cloud sync is not v1).

---

### Task 3.11 — Design role + per-entry visibility for family sharing (future work gate)

**Source:** A3 finding "**Future risk — family sharing**: PinService single-user, Users table has no role column" · **Rating:** Future Vulnerable
**Priority:** P2 · **Effort:** XL · **Tier:** v2

#### Problem
`lib/services/database_service.dart:47-59` defines a Users table with no role column, and `PinService` is single-user. If caregiver/family sharing ships without schema changes, any shared account would see all entries with no way to restrict.

#### Root cause
v1 scope is solo; multi-user schema hasn't been designed yet.

#### Threat model
- **Who:** A family member the owner grants access to intending to share only happy events / daily check-ins.
- **What they gain:** Accidental access to private entries (mental-health notes, financial thoughts, etc.).
- **How:** Owner hits "Invite caregiver" → caregiver sees everything.

#### Files touched
- `docs/family-sharing-design.md` (new spec)
- Future: `lib/services/database_service.dart` migration, `lib/models/user_role.dart`

#### Implementation approach
1. Spec roles: `owner`, `caregiver_readonly`, `caregiver_limited` (limited = only entries tagged `shareable`).
2. Spec per-entry `visibility` enum: `private`, `shared_with_caregiver`, `shared_public` (future).
3. Spec audit log: every caregiver read is logged client-side; owner can review.
4. Consider child-account flow (under-13) separately — PIPEDA implications noted per `user_location.md`.

#### Test plan
- N/A (spec).

#### Acceptance criteria
- [ ] `docs/family-sharing-design.md` with role/visibility/audit-log spec
- [ ] Review sign-off before code begins
- [ ] Commit pushed with `docs(security):` prefix referencing Task 3.11

#### Dependencies
- Gated on product decision to ship family sharing.

---

## P3 — Secure findings documented as intentional (no-op)

The following items were rated **Secure** in the audit and require no code change. They are captured here so the epic has a complete audit trail and future auditors can trace every row.

### Task 3.12 — PBKDF2-HMAC-SHA256 implementation (Secure — baseline retained)

**Source:** A3 finding "PBKDF2-HMAC-SHA256, 16-byte CSPRNG salt, 32-byte key, versioned `v3:iterations:salt:hash` format, legacy v2/SHA-256 auto-upgrade" · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action beyond Task 3.7's iteration bump. Algorithm choice, salt length, versioning strategy all remain as-is. Documented as intentional.

### Task 3.13 — Constant-time PIN comparison (Secure)

**Source:** A3 finding "Constant-time byte/string comparison" (`lib/services/pin_service.dart:127-144`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Protects against timing side-channels on PIN verify.

### Task 3.14 — Brute-force lockout (Secure)

**Source:** A3 finding "Brute-force lockout: 5 attempts, exponential backoff capped at 300s, persists on every failure" (`lib/services/lockout_controller.dart:15-16,95-107`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Force-stop bypass was closed in prior audit.

### Task 3.15 — Clock-rewind defense on lockout (Secure)

**Source:** A3 finding "Clock-rewind defense on lockout" (`lib/services/lockout_controller.dart:63-83`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Lockout timestamps resist manual clock rollback.

### Task 3.16 — Lockout state persisted to secure storage (Secure)

**Source:** A3 finding "Lockout state stored in secure storage (survives force-stop/reinstall on iOS Keychain)" (`lib/services/lockout_controller.dart:9,152-176`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Android-side reinstall resets (acceptable tradeoff).

### Task 3.17 — iOS Keychain `first_unlock` accessibility (Secure)

**Source:** A3 finding "iOS Keychain `first_unlock` accessibility" (`lib/services/secure_storage.dart:14`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Chosen to allow post-reboot biometric unlock without losing key access.

### Task 3.18 — SQLCipher DB encryption via sqlite3mc (Secure)

**Source:** A3 finding "SQLite AES via sqlite3mc, 256-bit CSPRNG key, hex-encoded PRAGMA key" (`lib/services/database_service.dart:149-169; pubspec.yaml:24-28`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Protection of the DB key is the downstream concern addressed by Task 3.1.

### Task 3.19 — `.bak` zeroed before deletion during migration (Secure)

**Source:** A3 finding "`.bak` zeroed before deletion on migration" (`lib/services/database_service.dart:184-193,246-255`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Consider extending same zeroing to the main DB during forgot-PIN wipe (handled in Task 3.2).

### Task 3.20 — Biometric auth configuration (Secure)

**Source:** A3 finding "Biometric: `biometricOnly: true`, `persistAcrossBackgrounding: true`, gated by lockout" (`lib/screens/lock_screen.dart:74-90`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Lockout continues to apply to biometric path.

### Task 3.21 — Import validation (Secure)

**Source:** A3 finding "Import validates size (50MB), entry count (500K), dates, types; strips C0/C1 control chars" (`lib/services/export_service.dart:77-93,337-442`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Prevents malformed-JSON bomb and control-char injection.

### Task 3.22 — Zero network calls (Secure)

**Source:** A3 finding "Zero network calls anywhere" (all of `lib/`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Add a CI guard (grep for `http://`, `https://`, `dart:io` socket imports) as a regression fence. Tracked separately under Epic 4 or wherever CI lives; no new task here.

### Task 3.23 — Minimal Android permissions (Secure)

**Source:** A3 finding "Android permissions minimal: USE_BIOMETRIC, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED" (`AndroidManifest.xml:3-5`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Any future permission addition requires security review.

### Task 3.24 — Android backup fully disabled (Secure)

**Source:** A3 finding "`allowBackup=false`, `fullBackupContent=false`, data_extraction_rules excludes all" (`AndroidManifest.xml:12-14; data_extraction_rules.xml`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Prevents ADB backup + Google cloud backup from copying the encrypted DB off device with keys.

### Task 3.25 — iOS export compliance + Face ID usage string (Secure)

**Source:** A3 finding "iOS `ITSAppUsesNonExemptEncryption=false`, Face ID usage string" (`ios/Runner/Info.plist:48-59`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. `ITSAppUsesNonExemptEncryption=false` accurate because only platform-provided crypto (CommonCrypto / sqlite3mc AES) is used.

### Task 3.26 — Release signing via `key.properties` / env vars (Secure)

**Source:** A3 finding "Release signing: `key.properties` or env vars; NOT committed" (`android/app/build.gradle.kts:42-69`) · **Rating:** Secure
**Priority:** P3 · **Effort:** XS · **Tier:** no-op
- No action; documented as intentional. Fallback weakness handled in Task 3.3.

---

## Summary

- Total tasks: 26 (one per table row + P0 build-signing item referenced in both Key Findings and Bottom Line)
- Note: Task 3.3 addresses the "Debug key fallback" row (also called out in Key Findings).
