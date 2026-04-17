# Submission checklist — pre-upload gate

**Status:** Active · **Task sources:** 9.7, 9.11, 12.5, 12.9 · **Last updated:** 2026-04-18

Every Play / App Store upload must pass this checklist before the
binary leaves the developer machine. The goal is zero reviewer
bounces in the first 72 hours post-upload — Apple's 72-hour review
queue doubles every time a rejection sends us back to the start.

## v1 submission gate

### Privacy + legal

- [ ] `test/no_network_invariant_test.dart` passes (Task 12.1)
- [ ] `AndroidManifest.xml` still declares
  `android:allowBackup="false"` and
  `android:fullBackupContent="false"` (Task 12.9 + CI guard)
- [ ] `ios/Runner/PrivacyInfo.xcprivacy` still has
  `NSPrivacyCollectedDataTypes=[]` (matches
  [`privacy-labels-v1.md`](./privacy-labels-v1.md))
- [ ] `lib/legal/privacy_policy.dart` version matches
  `currentPrivacyPolicyVersion` in `user_repository.dart`; any
  text change without a version bump = silent re-consent bypass
  = legal risk
- [ ] Age gate (`lib/screens/onboarding/age_gate_page.dart`)
  still country-aware per Task 12.3
- [ ] Crisis contact still localised per Task 12.16 (no
  hardcoded `988` outside the en/US/CA region)
- [ ] Forbidden-claims lint passes (Task 12.5)

### Build hygiene

- [ ] `flutter analyze` clean
- [ ] `flutter test --exclude-tags integration` passes (baseline
  560+ cases per 2026-04-17 session)
- [ ] Coverage floor ≥ 45% (CI gate)
- [ ] No SDK addition in `pubspec.yaml` that ships a network
  client (triggers v1.1 label rewrite — see below)
- [ ] `pubspec.yaml` `version:` bumped (Task 9.6 — never reuse
  a build number across Play Internal + App Store TestFlight)

### Listing copy

- [ ] Store description passes health-claim guardrails lint
  (Task 9.8 — no red-list words)
- [ ] Subtitle A/B variant selected (Task 9.12)
- [ ] Screenshots current (Task 9.1, blocked on B-17 screenshot
  vendor)
- [ ] Category: Lifestyle or Health & Fitness (Task 9.4
  declaration)
- [ ] Rating: 4+ (iOS) / Everyone (Play) per Task 9.9

### Store-side forms

- [ ] Apple Privacy Nutrition Label → "Data Not Collected"
  everywhere (Task 9.5 + 9.7 v1 snapshot)
- [ ] Google Play Data safety → "No collection" declared
- [ ] Google Play Health apps declaration submitted if category
  is Health & Fitness

## v1.1 submission gate — additional requirements

If the build includes RevenueCat, cloud AI recap, or Sentry:

### Trigger: Any v1.1 SDK compiled into the build

- [ ] **Privacy label rewrite shipped** —
  [`privacy-labels-v1.1.md`](./privacy-labels-v1.1.md) lists
  the required disclosures; paste the matching sections into
  App Store Connect Privacy + Play Data Safety forms BEFORE
  uploading the binary.
- [ ] Counsel sign-off on file — B-8 (subscription, Task 12.10) +
  B-9 (AI, Task 12.4/12.13)
- [ ] `PrivacyInfo.xcprivacy` updated with the XML block from
  the v1.1 plan doc
- [ ] Re-consent flow tested with a pre-v1.1 backup DB
  (existing users MUST see the re-consent page on first launch
  with the new SDKs)

### Trigger: RevenueCat

- [ ] Paywall disclosure UI renders all 5-jurisdiction strings
  (Task 12.10)
- [ ] App Store Connect Subscriptions configured with matching
  tier names / prices
- [ ] Play Console Subscriptions configured with matching tier
  names / prices
- [ ] California one-tap cancel URL live
- [ ] EU 14-day cooling-off acknowledgement present on paywall
- [ ] Quebec C.P.A. 230-231 rights copy present on paywall

### Trigger: Cloud AI recap

- [ ] Art. 9 explicit consent page gated on first recap
  generation (Task 12.4)
- [ ] AI Act Art. 50 transparency disclosures present
  (Task 12.13)
- [ ] Quebec PIA completed before first Quebec-region rollout
  (B-9 / Task 12.13)
- [ ] DPA with chosen model provider signed (0-retention terms
  enforced)
- [ ] Per-recap pre-send confirmation dialog shows which text
  will be sent + to whom
- [ ] "Revoke consent" toggle in Settings → Data works +
  purges any cached server-side state

### Trigger: Sentry

- [ ] `SENTRY_DSN` in GitHub Secrets (B-1)
- [ ] `SENTRY_AUTH_TOKEN` for symbol upload (B-1)
- [ ] `release.yml` dSYM upload step runs on tag push
- [ ] Settings → Data → "Help improve Retraq (anonymous crash
  reports)" toggle defaults OFF
- [ ] Breadcrumbs disabled in `sentry_flutter` init config (no
  risk of capturing journal text)

## Cross-references

- v1 privacy snapshot:
  [`privacy-labels-v1.md`](./privacy-labels-v1.md)
- v1.1 privacy plan:
  [`privacy-labels-v1.1.md`](./privacy-labels-v1.1.md)
- Health-claim guardrails:
  [`health-claim-guardrails.md`](./health-claim-guardrails.md)
- Launch plan: [`launch-plan.md`](./launch-plan.md)
- A/B subtitle: [`ab-tests.md`](./ab-tests.md)
- Age rating: [`age-rating-ios.md`](./age-rating-ios.md),
  [`age-rating-android.md`](./age-rating-android.md)
- IAP posture: [`iap-posture.md`](./iap-posture.md)
