# Right to be forgotten — Delete All Data invariant

**Status:** Active · **Task:** 12.9 · **Last updated:** 2026-04-18

Retraq's Privacy Policy promises users a one-tap, irrevocable
"Delete All Data" option that wipes every journal entry, consent
record, user row, and setting from the device. This document
pins what "irrevocable" means in practice and links to the tests
that enforce it.

## Regulatory anchor

- **GDPR Art. 17** — right to erasure / right to be forgotten.
  Data controllers must honour erasure requests without undue
  delay where one of the bases applies (withdrawn consent, no
  longer necessary, unlawful processing, etc.).
- **PIPEDA Principle 5** — limiting use, disclosure, and
  retention. Personal information that is no longer required
  should be destroyed, erased, or made anonymous.
- **Quebec Law 25 s. 28** — right to rectification / cessation of
  dissemination, including deletion of PI no longer needed.
- **CCPA §1798.105** — California consumer right to delete.

Retraq is a local-first app: the "data controller" is the user
themselves, running on their own device. There is no server-side
copy, no cloud backup, no analytics pipeline. The right to be
forgotten reduces to: **when the user taps Delete All Data, the
on-device data must be gone.**

## What gets deleted

Wiped in a single DB transaction (`UserRepository.deleteAllData`,
see `lib/services/user_repository.dart:98`):

1. **Journal entries** — every row of `journal_entries`, plus the
   FTS5 shadow table that backs full-text search. Verified by
   `test/services/delete_all_data_test.dart:115` (search a
   distinctive needle pre-wipe; assert empty result post-wipe).
2. **User row** — `users` table emptied.
3. **Consent records** — every row of `consent_records` (privacy
   policy, terms of service, health disclaimer acceptance
   timestamps + version hashes). Verified in test.
4. **User settings** — the `user_settings` singleton row is
   deleted, then a fresh default row is re-inserted so the app
   can cold-start cleanly. The fresh row carries **no** user
   input (no PIN hash, no theme choice, no preferences).
5. **SharedPreferences keys** — `age_verified`, `age_denied`,
   `review_prompt_shown`, `pin_length` are explicitly removed.
6. **Hardened secure storage** — `pin_length`,
   `lock_failed_attempts`, `lock_lockout_count`,
   `lock_lockout_start`, `lock_lockout_end` are explicitly
   removed. The DB encryption key (`retraq_db_key`) is
   **preserved** so the DB can be reopened post-wipe — that key
   protects only the empty shell at that point.
7. **Home-screen widget cache** — streak / total entries / last
   entry date / mood all zeroed, widget refreshed.
8. **App restart** — on real devices the app exits so the UI
   cannot hold references to wiped data. Skipped in test envs
   where `FLUTTER_TEST` is set.

## What is NOT deleted

The DB encryption key (`retraq_db_key`) in FlutterSecureStorage
is intentionally **retained**. Rationale:

- `deleteAll()` on secure storage would destroy the key,
  leaving the empty DB file unopenable. On the next launch we
  would generate a new key and the file's ciphertext would be
  unreadable — effectively the same deletion, but with an
  ambiguous state (the file exists, its contents look like
  garbage) that's harder to reason about for diagnostics.
- With the key preserved, the next app launch opens the empty
  DB cleanly, shows the fresh-install onboarding, and the user
  sees a consistent state matching the "everything is gone"
  mental model.
- Net effect on attacker: identical. An attacker with physical
  access post-wipe sees either an empty DB or an unreadable
  ciphertext; in both cases no user data is recoverable.

## What the test verifies

`test/services/delete_all_data_test.dart` covers three cases:

1. **Total wipe across tables** — seed user + 3 entries + 2
   consent records, call `deleteAllData`, assert every
   user-data table reads back empty and the re-inserted
   settings row carries no stale values.
2. **FTS5 search surface is swept** — seed an entry with a
   distinctive needle, confirm search finds it, wipe, confirm
   the needle is no longer findable via search. Guards against
   a regression where the FTS5 content table is orphaned when
   its backing row is deleted.
3. **Idempotent** — calling `deleteAllData` twice in a row on
   an already-empty DB does not throw.

## What is beyond the test's reach

- **Raw on-disk recoverability.** The SQLCipher file itself is
  encrypted with AES-256-GCM. When rows are deleted, the file
  pages become unreferenced but are not zero-filled (SQLite
  does not `WAL truncate` by default). Forensic recovery of
  ciphertext pages is theoretically possible; they would still
  need the key to decrypt. The key lives in the Android
  Keystore / iOS Keychain and does not leave the device. This
  is an OS-layer invariant, not unit-testable.
- **Android auto-backup.** `android:allowBackup="false"` plus
  `android:fullBackupContent="false"` plus the
  `data_extraction_rules` XML together prevent `adb backup`,
  Google's cross-device transfer, and device-to-device migration
  from scooping the DB. Verified in the manifest; CI asserts the
  `allowBackup="false"` attribute on every push (see
  `.github/workflows/ci.yml` "Android backup lint").
- **iOS iCloud Keychain sync.** The DB key is written with
  `first_unlock_this_device_only` accessibility, so it does not
  sync to iCloud Keychain. A restored-from-backup device would
  not have the key and would be unable to decrypt any
  surviving-but-encrypted file fragments.

## CI enforcement

- **Unit test:** `flutter test --exclude-tags integration` runs
  `delete_all_data_test.dart` on every PR.
- **Manifest lint:** CI fails the build if
  `android:allowBackup` is anything other than `"false"` in
  `AndroidManifest.xml`.

## If this contract ever changes

Any code change that modifies `deleteAllData` semantics —
retaining data across a wipe, skipping a table, deferring to a
background queue — must also:

1. Update this document with the new contract.
2. Update the test to match.
3. Bump `ConsentVersion` so existing users re-consent on launch.
4. Update `lib/legal/privacy_policy.dart` to describe the new
   behaviour.
5. Get counsel review (est. $500–1000 CAD) before merging.
