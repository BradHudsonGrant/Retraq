# Privacy nutrition labels — v1 snapshot

**Status:** Active v1 baseline · **Task:** 9.7 · **Last updated:** 2026-04-18

This file pins the privacy disclosure surface for the v1 build
(fully free, no network calls, no analytics). The Task 9.7
companion file [`privacy-labels-v1.1.md`](./privacy-labels-v1.1.md)
pre-authors the rewrite that MUST land before any v1.1 build
introducing RevenueCat, cloud AI, or Sentry.

## Apple App Store — Privacy Nutrition Label

**Collected:** `Data Not Collected` on every category.

**Tracking:** None. `NSPrivacyTracking=false`.
`NSPrivacyTrackingDomains=[]`.

**Collected-Data-Types:** `NSPrivacyCollectedDataTypes=[]` in
`ios/Runner/PrivacyInfo.xcprivacy`.

**Required-reason APIs declared:** none beyond what Flutter / the
current plugin set already declare (file timestamps for DB
management, disk space for settings cache). Every declared reason
ties to a documented on-device purpose; no reason is declared for
uploading to a server.

**Subcategories pre-filled as empty (so v1.1 rewrite knows what
moved):**

| Category | Current v1 disclosure | Reason |
|---|---|---|
| Contact Info | — (not collected) | No account system |
| Health & Fitness | — (not collected) | Local journal only |
| Financial Info | — (not collected) | No IAP in v1 |
| Location | — (not collected) | No geo features |
| Sensitive Info | — (not collected) | No cloud processing |
| Contacts | — (not collected) | No social surfaces |
| User Content | — (not collected) | Journal text stays on device |
| Browsing History | — (not collected) | No in-app browser |
| Search History | — (not collected) | FTS5 lives on device |
| Identifiers | — (not collected) | No account / ad IDs |
| Purchases | — (not collected) | No IAP in v1 |
| Usage Data | — (not collected) | Zero analytics |
| Diagnostics | — (not collected) | Sentry gated behind B-1 |
| Other Data | — (not collected) | n/a |

## Google Play — Data safety form

**"Does your app collect or share any of the required user data
types?"** → **No.**

**"Is all of the user data collected by your app encrypted in
transit?"** → Not applicable (no collection).

**"Does your app provide a way for users to request their data be
deleted?"** → Yes — Settings → Data → Delete All Data. See
`docs/legal/right-to-be-forgotten.md`.

**Security practices declared:** none required (no collection).

## Supporting artifacts

- `ios/Runner/PrivacyInfo.xcprivacy` (Task 9.5 delivered)
- `lib/legal/privacy_policy.dart` — matching narrative
- `test/no_network_invariant_test.dart` — runtime guard
- `.github/workflows/ci.yml` "Android backup-disabled lint" — Task 12.9
- `docs/legal/no-network-attestation.md` — TODO (Task 12.1 follow-up)

## Submission gate

Before submitting a v1 build to either store, verify:

1. `flutter analyze` clean — no new network imports since this
   label was written.
2. `test/no_network_invariant_test.dart` passes locally and in CI.
3. No new dependency in `pubspec.yaml` that ships a network
   client (check the next Dependabot PR's transitive graph).
4. `ios/Runner/PrivacyInfo.xcprivacy` still lists
   `NSPrivacyCollectedDataTypes=[]`.

If ANY of these fail, you're not shipping a v1 build — you're
shipping v1.1 and must rewrite labels first.
