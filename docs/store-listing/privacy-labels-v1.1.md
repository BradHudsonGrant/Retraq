# Privacy nutrition labels — v1.1 rewrite plan

**Status:** Planned (not yet active) · **Task:** 9.7 · **Last updated:** 2026-04-18

v1 ships with "Data Not Collected" across the board (see
[`privacy-labels-v1.md`](./privacy-labels-v1.md)). v1.1 introduces
monetization (RevenueCat), optional cloud AI recap, and Sentry
crash reporting. The moment ANY of those SDKs compiles into a
build, the privacy nutrition label must be rewritten. This file
is the pre-authored rewrite so the label change is reviewable
before the SDK ships, not after.

## Scope triggers (which v1.1 SDKs force a rewrite)

A build requires the v1.1 labels if AT LEAST ONE of the following
lands:

- **RevenueCat** — adds `purchases` + `installed_at` identifiers
- **Cloud AI recap (Anthropic / Gemini / OpenAI)** — sends entry
  text to a model provider
- **Sentry Flutter SDK** — ships diagnostic events + optionally
  breadcrumbs

Each trigger has its own disclosure obligations; disable any one
and its section reverts to "Data Not Collected" in the label.

## Apple App Store — planned Privacy Nutrition Label (v1.1)

Each row fires only if the corresponding SDK is compiled into the
build. Rows marked "Not in v1.1" are placeholders for later.

### Financial Info → Purchases (RevenueCat trigger)

| Field | Value |
|---|---|
| Collected | Yes |
| Linked to identity | Yes — RevenueCat App User ID |
| Used for tracking | No |
| Purpose | App Functionality (entitlement check) |
| Disclosure | "Purchase history, subscription state, and an anonymous RevenueCat App User ID are collected so Retraq can restore your purchase across installs." |

### User Content → Other User Content (cloud AI trigger)

| Field | Value |
|---|---|
| Collected | Yes — only on explicit per-recap tap |
| Linked to identity | No — no account linkage |
| Used for tracking | No |
| Purpose | App Functionality (generate weekly recap) |
| Disclosure | "When you tap 'Generate AI recap,' the current week's journal text is sent to {provider} solely to produce the recap. No long-term server retention per DPA; see [`docs/legal/ai-transparency.md`](../legal/ai-transparency.md)." |

### Diagnostics → Crash Data + Performance Data (Sentry trigger)

| Field | Value |
|---|---|
| Collected | Yes (opt-in, default OFF) |
| Linked to identity | No |
| Used for tracking | No |
| Purpose | App Functionality (fix crashes) |
| Disclosure | "Crash stack traces, device model, OS version, and app version are sent to Sentry ONLY if you have 'Help improve Retraq' enabled. No journal content is ever captured by Sentry." |

### Identifiers → User ID (RevenueCat trigger only)

| Field | Value |
|---|---|
| Collected | Yes — RevenueCat anonymous App User ID |
| Linked to identity | Yes (to purchases) |
| Used for tracking | No |
| Purpose | App Functionality |

### Every other Apple category → Data Not Collected

Unchanged from v1. Journal entries, mood, contact info, location,
health data, photos, biometric templates, and search history ALL
stay local. The only net-new upload paths are purchases (RevenueCat)
and optional recap text (cloud AI tier).

### `NSPrivacyTracking` / `NSPrivacyCollectedDataTypes` values

```xml
<key>NSPrivacyTracking</key>
<false/>
<!-- no tracking domains even in v1.1 - RevenueCat/Sentry are not trackers -->
<key>NSPrivacyTrackingDomains</key>
<array/>
<key>NSPrivacyCollectedDataTypes</key>
<array>
  <!-- Financial Info - Purchases -->
  <dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypePurchaseHistory</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <true/>
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
      <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
    </array>
  </dict>
  <!-- User Content - Other User Content (cloud AI tier only) -->
  <dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeOtherUserContent</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <false/>
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
      <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
    </array>
  </dict>
  <!-- Diagnostics - Crash Data (Sentry, opt-in) -->
  <dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeCrashData</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <false/>
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
      <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
    </array>
  </dict>
</array>
```

## Google Play — planned Data safety form (v1.1)

### Data collected

| Data type | Purpose | Linked to account | Shared? | Processed ephemerally? | Required? |
|---|---|---|---|---|---|
| Purchase history (RevenueCat) | App functionality | Yes (to RC App User ID) | No | No — retained for receipt verification | Yes (to subscribe) |
| App interactions — recap request payload (cloud AI) | App functionality | No | Yes — to chosen model provider | Yes — 0-retention DPA | No (optional feature) |
| Crash logs (Sentry, opt-in) | App functionality | No | Yes — to Sentry | No — retained per Sentry plan | No (opt-in) |

### Security practices

- **Encrypted in transit:** All three uploads use TLS 1.3.
- **User can request deletion:** Yes — Settings → Data → Delete
  All Data (plus per-service: RevenueCat receipt refund flow,
  Sentry "forget me", cloud recap 0-retention DPA = nothing to
  forget).
- **Data follows Play Families Policy:** N/A (app is not targeted
  at children; age gate at Task 12.3 blocks under-threshold users).
- **Independent security review:** WCAG audit (Task 12.14) is the
  closest analogue; no SOC 2 applicable for a local-first app.

## Per-SDK provider disclosures

### RevenueCat

- **Data sent:** anonymous App User ID, purchase receipt,
  subscription entitlement state.
- **Data retained by provider:** purchase receipts (per their
  privacy policy), no journal content.
- **User-facing disclosure:** paywall page (Task 12.10) must name
  RevenueCat as the sub-processor.

### Cloud AI provider (Anthropic / Google / OpenAI — TBD)

- **Data sent:** current week's journal text (title + body), no
  mood / timestamps / user ID.
- **Data retained by provider:** **zero** — enforced by DPA
  requiring 0-retention terms as a launch gate. If any candidate
  provider refuses 0-retention, we do not integrate.
- **User-facing disclosure:** Art. 9 consent row (Task 12.4) +
  AI transparency disclosure (Task 12.13) + per-recap pre-send
  confirmation.

### Sentry

- **Data sent:** crash stack trace, device model, OS version, app
  version, Dart exception type, optional breadcrumbs (we disable
  breadcrumbs that could contain journal text).
- **Data retained by provider:** 30 days on free plan; 90 days on
  Team plan.
- **User-facing disclosure:** Settings → Data → "Help improve
  Retraq (anonymous crash reports)" toggle, default OFF. Opt-in
  only.

## Release-checklist gate

Before uploading the first v1.1 build that includes ANY of the
three triggers:

1. Update `ios/Runner/PrivacyInfo.xcprivacy` to match the XML
   block above (only the triggered sections).
2. Update the App Store Connect Privacy form under
   App Information → App Privacy.
3. Update the Google Play Console Data safety form under
   Policy → App content → Data safety.
4. Re-upload screenshots of the completed forms to
   `docs/store-listing/privacy-label-screenshots/v1.1/` for
   audit trail.
5. Privacy counsel sign-off (B-8 subscription, B-9 AI) before
   first paid / AI build ships.

If ANY step is skipped, the submission will fail Apple's privacy
review within the first 48 hours and delay launch.

## Crosslinks

- v1 baseline: [privacy-labels-v1.md](./privacy-labels-v1.md)
- Paywall disclosure (Task 12.10):
  [../legal/paywall-disclosure-matrix.md](../legal/paywall-disclosure-matrix.md) (TBD)
- AI transparency (Task 12.13):
  [../legal/ai-transparency.md](../legal/ai-transparency.md)
- Right to be forgotten (Task 12.9):
  [../legal/right-to-be-forgotten.md](../legal/right-to-be-forgotten.md)
- IAP posture (Task 9.10): [iap-posture.md](./iap-posture.md)
- Age rating uplift (Task 9.9):
  [age-rating-caregiver-uplift.md](./age-rating-caregiver-uplift.md)
