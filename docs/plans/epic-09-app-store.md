# Epic 9 — App Store Submission Readiness

Source: review-2026-04-16.md §Agent 9

This epic covers every finding in the Agent 9 Detailed Findings Table. Tasks are ordered by priority (P0 Blockers first). Ready-rated rows are retained as brief reference entries (no-op tier) so the epic is exhaustive.

Cross-epic dependency: Task 9.1 (screenshots) depends on Epic 13 icon fix landing first, because every device-framed screenshot embeds the app icon in the status bar / home indicator frame and in any hero mockups.

---

## P0 — Blockers (v1 launch)

### Task 9.1 — Produce complete App Store + Google Play screenshot set

**Source:** A9 finding "Screenshot set 5 Android PNGs only" · **Rating:** Blocker
**Platforms:** Both
**Priority:** P0 · **Effort:** L · **Tier:** v1

#### Problem
Only 5 raw Android PNGs exist (`screenshots/home.png`, `stats.png`, `stats2-4.png`). No iOS screenshots, no marketing overlays, no device frames, no required sizes for 6.7"/6.5" iPhone, 12.9" iPad, or Pixel 9 Pro XL feature graphic. Apple and Google Play both reject submissions missing required sizes.

#### Root cause
Screenshots were captured ad-hoc from a Pixel emulator during development, never re-produced against a marketing shot-list, never framed in Fastlane `frameit`/`screenshots.pro`/Figma device mockups, never re-captured on iOS.

#### Deliverables
- Artifacts: framed PNGs per platform/size, shot-list doc, caption + overlay copy draft, Figma source.
- File paths:
  - `docs/store-listing/screenshots-shotlist.md` (this shot-list)
  - `assets/store-screenshots/ios/6.7/01-hero.png` … `08-privacy.png`
  - `assets/store-screenshots/ios/6.5/01-hero.png` … `08-privacy.png`
  - `assets/store-screenshots/ios/ipad-12.9/01-hero.png` … `08-privacy.png`
  - `assets/store-screenshots/android/phone/01-hero.png` … `08-privacy.png`
  - `assets/store-screenshots/android/feature-graphic-1024x500.png`
  - `assets/store-screenshots/android/tablet-7in/` and `tablet-10in/`
  - `tool/screenshots/` — `integration_test/screenshot_driver.dart` running golden scenes

#### Implementation approach
1. Capture raw screens via Flutter integration driver (reproducible).
2. Run through Fastlane `frameit` for iOS and a Figma template for Android; unify background gradient `#F8FAF8 → #B5F0C9`.
3. Apply headline overlay (Lexend 64pt) and subhead (Manrope 28pt) above each frame.
4. Export at required sizes.

iOS shot-list (6.7" iPhone 16 Pro Max, 6.5" iPhone 11 Pro Max, 12.9" iPad Pro 6th gen — identical overlay copy, re-captured per device):

| # | Screen captured | Overlay headline (<=30 chars) | Caption (<=55 chars) | Device frame |
|---|---|---|---|---|
| 1 | Home with "How've you been?" hero prompt | Journaling, without the pressure | One sentence is a whole entry. | iPhone 16 Pro Max Titanium Black |
| 2 | New entry — 12-word traq drafted | Drop a traq in 10 seconds | No prompts. No streaks. Just a sentence. | iPhone 16 Pro Max Titanium Black |
| 3 | Mood selector with blob emoji expanded | Mood in one tap | Five feelings. Zero clinical language. | iPhone 16 Pro Max Titanium Natural |
| 4 | Week recap card ("Week retraqd") | Your week, read back to you | Skim what happened. Keep what matters. | iPhone 16 Pro Max Titanium Black |
| 5 | Stats — streak, entries/week, mood dist | Patterns you'll actually notice | Local stats. Nothing leaves your phone. | iPhone 16 Pro Max Titanium Natural |
| 6 | On This Day card with year-ago entry | The memory you didn't save | Retraq remembers so you don't have to. | iPhone 16 Pro Max Titanium Black |
| 7 | Settings → Privacy (encrypted, FLAG_SECURE, no network) | Private by construction | SQLCipher. Face ID. Zero telemetry. | iPhone 16 Pro Max Titanium Black |
| 8 | Onboarding "If those questions make your mind go blank" | Built for busy brains | For people who forget Tuesday by Thursday. | iPhone 16 Pro Max Titanium Natural |

Android shot-list (Pixel 9 Pro XL phone 1440x3120, 7" + 10" tablet, 1024x500 feature graphic):

| # | Screen captured | Overlay headline | Caption | Device frame |
|---|---|---|---|---|
| 1 | Home hero prompt | Journaling without the pressure | One sentence counts. | Pixel 9 Pro XL Obsidian |
| 2 | New entry mid-type | Drop a traq in 10 seconds | No prompts. Just a sentence. | Pixel 9 Pro XL Obsidian |
| 3 | Mood selector | Mood in one tap | Five feelings. No jargon. | Pixel 9 Pro XL Porcelain |
| 4 | Week recap | Your week, read back | Skim it. Keep the good bits. | Pixel 9 Pro XL Obsidian |
| 5 | Stats dashboard | Patterns worth noticing | Local stats. Private by default. | Pixel 9 Pro XL Porcelain |
| 6 | On This Day | The memory you didn't save | Retraq remembers so you don't. | Pixel 9 Pro XL Obsidian |
| 7 | Privacy settings | Private by construction | SQLCipher + biometric lock. | Pixel 9 Pro XL Obsidian |
| 8 | Onboarding empathy hook | Built for busy brains | Forget Tuesday by Thursday? Retraq. | Pixel 9 Pro XL Porcelain |
| FG | Feature graphic 1024x500 — icon + "Lost traq? Retraq." tagline | — | — | No device frame |

#### Review-guideline mapping
- Apple: 2.3.3 (accurate screenshots), 2.3.8 (no placeholder/test data), metadata rejection if wrong sizes.
- Google Play: Metadata policy (accurate screenshots), Feature graphic required 1024x500 PNG/JPG.

#### Acceptance criteria
- [ ] 8 framed PNGs per iOS size (6.7, 6.5, 12.9) committed to `assets/store-screenshots/ios/`.
- [ ] 8 framed PNGs for Pixel 9 Pro XL + 2 tablet sizes committed to `assets/store-screenshots/android/`.
- [ ] 1024x500 feature graphic committed.
- [ ] Shot-list doc `docs/store-listing/screenshots-shotlist.md` reviewed.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore(store): produce screenshot set (Task 9.1)`.

#### Dependencies
- Blocked by: Epic 13 icon redesign (new icon must appear in status bar of every framed screenshot).
- Blocks: submission checklist final gate.
- External: Fastlane `frameit` license (free), Figma.

---

## P1 — Needs Prep (v1 launch)

### Task 9.2 — Draft App Store Connect + Play Console listing copy (title, subtitle, short desc, description, keywords)

**Source:** A9 finding "Coined name will not appear in user searches" · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P1 · **Effort:** M · **Tier:** v1

#### Problem
Retraq is a coined name with zero organic search volume. The iOS subtitle (30 char) and Play short description (80 char) must carry every high-intent ASO keyword: journal, diary, ADHD, memory, mood tracker. Today only `docs/retraq-branding-guide.md` has on-brand voice — no store-ready copy exists.

#### Root cause
Brand guide was written for voice direction, not for App Store Connect / Play Console field layout with character limits.

#### Deliverables
- `docs/store-listing/ios.md` — all App Store Connect text fields.
- `docs/store-listing/android.md` — all Play Console text fields.
- `docs/store-listing/aso-keywords.md` — keyword table (Task 9.3).

#### Implementation approach

**iOS App Store Connect copy (drafts):**

- App Name (30 char max): `Retraq: Journal for Busy Brains` (31) → revise to `Retraq — Journal, Mood, Memory` (30).
- Subtitle (30 char max — carries ASO): `Journal, mood, memory for ADHD` (30).
- Promotional Text (170 char): `New in 2026: Drop a traq in 10 seconds. Private by default. Built for people who forget Tuesday by Thursday. No streaks, no guilt, no cloud.`
- Keywords field (100 char comma-separated, no spaces): `journal,diary,mood,tracker,adhd,memory,mental,wellness,daily,log,therapy,selfcare,habit,private`

**App Store description (up to 4000 char draft, ~1900 char):**

```
Journalling apps want your life story. Retraq just wants a sentence.

If "How've you been?" makes your mind go blank, you're in the right place. Retraq is a private, local-first journal built for busy brains — ADHD-adjacent, memory-curious, forgetful on Tuesdays, half-remembering by Thursday.

WHY RETRAQ
- Drop a traq in 10 seconds. One sentence is a whole entry.
- Mood in one tap. Five feelings. No clinical jargon.
- Week retraqd. A warm, skimmable recap of what actually happened.
- On This Day. The memory you didn't bother saving, waiting for you a year later.
- Patterns worth noticing. Local stats: streaks (if you want them), entries per week, mood distribution.

BUILT PRIVATE, NOT "PRIVACY FIRST"
- Your journal lives on your device. There is no cloud. There is no account.
- Encrypted at rest with SQLCipher (AES-256). Locked with Face ID or PIN.
- Zero analytics. Zero telemetry. Zero third-party SDKs.
- Export anytime as JSON or plain text. Delete everything with one tap.

WHAT RETRAQ ISN'T
- Not a medical device, not therapy, not a diagnosis tool.
- Not a streak-shaming habit tracker.
- Not another "five-minute gratitude" prompt.

Free to use. No ads. No upsells in v1. Later, an optional subscription will unlock AI weekly recap and richer stats — always on top of the free core, never a paywall across it.

If today's journaling apps feel like homework, try the one that just wants a sentence.

Retraq. Lost traq? Retraq.
```

**Play Console copy (drafts):**

- Title (30 char): `Retraq: Journal & Mood Log` (26).
- Short description (80 char): `Private journal & mood log for busy brains. No cloud, no streaks, no guilt.` (77).
- Full description (up to 4000 char): same body as iOS description above.

**Categories:**
- iOS Primary: Lifestyle. Secondary: Health & Fitness.
- Play: Lifestyle primary; Health Apps declaration avoided (Task 9.4).

#### Review-guideline mapping
- Apple: 2.3.7 (metadata accurate), 2.3.10 (no irrelevant keywords).
- Google Play: Metadata policy, Spam & Minimum Functionality, Repetitive Content.

#### Acceptance criteria
- [ ] `docs/store-listing/ios.md` complete with every Connect field.
- [ ] `docs/store-listing/android.md` complete with every Play field.
- [ ] All char counts verified under limits.
- [ ] Internal review sign-off from brand guide check.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): draft listing copy (Task 9.2)`.

#### Dependencies
- Blocks: Task 9.3 (keyword field mirrors research), submission.
- External: App Store Connect account (already provisioned via bundle ID).

---

### Task 9.3 — Run ASO keyword research and produce keyword strategy table

**Source:** A9 finding "Coined name will not appear in user searches" (ASO angle) · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P1 · **Effort:** M · **Tier:** v1

#### Problem
Subtitle has 30 chars to do all keyword lifting because "Retraq" itself has zero volume. No keyword research exists; subtitle in the brand guide wastes 30 chars on brand voice.

#### Deliverables
- `docs/store-listing/aso-keywords.md` — keyword table and strategy.

#### Implementation approach
1. Pull keyword volume + difficulty from AppTweak / Sensor Tower / App Radar (free tier). Do NOT hard-rely on a single provider — average 3.
2. Score each keyword on Relevance (R, 1-5), Volume (V, 1-10 iOS scale), Competitor rank difficulty (D, 1-10).
3. Target 6-8 keywords in iOS 100-char field; rely on description/short-desc crawl on Play.

Starter keyword table:

| Keyword | Platform | R | V | D | iOS Top-3 competitors at this term | Commentary |
|---|---|---|---|---|---|---|
| journal | Both | 5 | 9 | 9 | Day One, Journey, Reflectly | Too broad; rank ambition = top 30. |
| diary | Both | 5 | 8 | 8 | Daylio, Diarium | Synonym hedge for "journal." |
| mood tracker | Both | 5 | 8 | 8 | Daylio, How We Feel | Core secondary term. |
| adhd journal | Both | 5 | 4 | 4 | Finch, none dominant | High relevance, low difficulty — win here. |
| adhd planner | Both | 4 | 5 | 6 | Tiimo, Inflow | Adjacent but not our frame. |
| memory journal | Both | 5 | 3 | 3 | (fragmented) | Under-served; aligns with "On This Day." |
| private journal | Both | 5 | 5 | 5 | Daylio, Diarium | Reinforces privacy USP. |
| daily log | Both | 4 | 5 | 6 | Day One | Synonym filler. |
| mental wellness | Both | 3 | 8 | 9 | Calm, Finch, Headspace | Avoid — triggers Health Apps policy. Drop. |
| mood log | Both | 5 | 6 | 5 | Daylio, MoodPath | Strong signal, middling volume. |
| self care journal | Both | 4 | 5 | 6 | Finch, Stoic | OK supplement. |
| therapy journal | Both | 3 | 5 | 7 | (fragmented) | Flirts with health-claim territory — include cautiously. |
| habit tracker | Both | 3 | 9 | 10 | Streaks, Habitify | Avoid — we explicitly aren't one. |
| gratitude journal | Both | 4 | 7 | 8 | Presently, Stoic | Optional filler. |

Final iOS keywords field (100 char, comma-separated, no spaces): `journal,diary,mood,tracker,adhd,memory,mental,wellness,daily,log,therapy,selfcare,habit,private` (93).

Final Play short-desc (relies on crawl, no dedicated field): "Private journal & mood log for busy brains. No cloud, no streaks, no guilt."

#### Review-guideline mapping
- Apple: 2.3.10 no irrelevant keywords; no competitor names (don't include "day one," "finch," "daylio").
- Google Play: Spam (repeated keyword stuffing).

#### Acceptance criteria
- [ ] Keyword table committed at `docs/store-listing/aso-keywords.md`.
- [ ] iOS keywords field verified <=100 chars, no competitor names.
- [ ] Re-measured at T+30 days post-launch.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): ASO keyword research (Task 9.3)`.

#### Dependencies
- Blocks: Task 9.2 final keyword field.
- External: AppTweak/Sensor Tower/App Radar free tier.

---

### Task 9.4 — Lock category selection and Google Play Health Apps declaration posture

**Source:** A9 finding "Category choice unclear" · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
Primary/secondary categories not selected in repo. Google Play's January 2026 Health Apps enforcement means choosing "Health & Fitness" primary (or implying clinical benefit in copy) triggers a Health Apps Declaration form and extra review. Retraq is closer to Lifestyle.

#### Deliverables
- Section in `docs/store-listing/ios.md`: category decisions.
- Section in `docs/store-listing/android.md`: category + Health Apps declaration decision.

#### Implementation approach
1. iOS Primary: `Lifestyle`. Secondary: `Health & Fitness` — allowed but review description for 1.4.1 risk.
2. Play Primary: `Lifestyle` only. Do NOT select Health & Fitness.
3. Answer the Play Health Apps declaration as "No" provided all listing/description copy avoids: "treat," "diagnose," "symptom tracker," "therapy," "clinical," "ADHD management," "dementia."
4. Keep "ADHD-adjacent" tone in description but scrub any wording that implies therapeutic outcome.

#### Review-guideline mapping
- Apple: 1.4.1 (medical device claims), 5.1.1(ix) (healthcare data), 2.3.7 (category accuracy).
- Google Play: Health Apps policy (Jan 2026), Health Content, Medical Device.

#### Acceptance criteria
- [ ] Categories chosen and documented.
- [ ] Play Health Apps declaration question answered "No" with rationale documented.
- [ ] Description scrubbed of triggering claims.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): lock categories (Task 9.4)`.

#### Dependencies
- Blocked by: Task 9.2 description scrub pass.
- External: none.

---

### Task 9.5 — Add `PrivacyInfo.xcprivacy` for iOS required-reason API usage

**Source:** A9 finding "No `NSPrivacyAccessedAPITypes` manifest" · **Rating:** Needs Prep
**Platforms:** iOS
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
Since May 2024, Apple requires `PrivacyInfo.xcprivacy` for apps/SDKs using required-reason APIs (UserDefaults, file timestamps, disk space, system boot time, active keyboards). `shared_preferences` and `path_provider` likely each bundle one, but the app-level manifest must aggregate reasons and any third-party SDKs that don't ship their own.

#### Root cause
No `ios/Runner/PrivacyInfo.xcprivacy` created during the Flutter iOS setup.

#### Deliverables
- `ios/Runner/PrivacyInfo.xcprivacy` with `NSPrivacyAccessedAPITypes` entries.
- Updated Xcode project membership for the plist.

#### Implementation approach
1. Audit required-reason API usage across app + deps: UserDefaults (C56.1 — app functionality for user-facing setting), File timestamps (C617.1 — display to the user if Retraq shows file timestamps, otherwise omit), Disk space (E174.1 — only if displayed), System boot time (35F9.1 — not used), Active keyboards (54BD.1 — not used).
2. Declare `NSPrivacyTracking=false`, `NSPrivacyTrackingDomains=[]`, `NSPrivacyCollectedDataTypes=[]` (matches "Data Not Collected" Task 9.7).
3. Add file to Xcode Runner target and Flutter embedding.
4. Verify in `flutter build ipa` output that Apple's report includes the app-level manifest.

#### Review-guideline mapping
- Apple: Privacy manifest requirement (May 2024+), App Store Server notification on missing required-reason API declarations.

#### Acceptance criteria
- [ ] `ios/Runner/PrivacyInfo.xcprivacy` present and committed.
- [ ] `flutter build ipa --export-method app-store` succeeds without privacy-manifest warning.
- [ ] Verified with `grep -r NSPrivacyAccessedAPITypes ios/` shows all declared reasons.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore(ios): add PrivacyInfo manifest (Task 9.5)`.

#### Dependencies
- External: Apple developer documentation (privacy manifest reference).

---

### Task 9.6 — Bump version from placeholder `1.0.0+1` for TestFlight / Internal Testing

**Source:** A9 finding "Version at placeholder `1.0.0+1`" · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P1 · **Effort:** XS · **Tier:** v1

#### Problem
`pubspec.yaml:19` is at `1.0.0+1`, the Flutter default. TestFlight and Play Internal Testing require unique build numbers; +1 must be reserved for a real submission, and beta iteration needs +2, +3…

#### Deliverables
- Version bump in `pubspec.yaml`.
- `docs/store-listing/versioning.md` — version-scheme note.

#### Implementation approach
1. Move to `1.0.0+2` as the first TestFlight/Internal build; reserve +1 as an unused placeholder in case App Store Connect was ever fed it.
2. Document scheme: `MAJOR.MINOR.PATCH+BUILD` where `+BUILD` monotonically increases per submission, never resets across tracks.
3. Align with `release.yml` tag parser (already handles `vX.Y.Z+N` per Agent 10).

#### Review-guideline mapping
- Apple: build-number uniqueness enforced by App Store Connect.
- Google Play: versionCode uniqueness enforced by Play Console.

#### Acceptance criteria
- [ ] `pubspec.yaml` `version:` bumped.
- [ ] Versioning note committed.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `chore(release): bump version (Task 9.6)`.

#### Dependencies
- None.

---

### Task 9.7 — Plan cloud-AI / RevenueCat privacy-nutrition-label rewrite for v1.1

**Source:** A9 finding "Future cloud-AI / RevenueCat forces label rewrite" · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P1 · **Effort:** S · **Tier:** v1.1

#### Problem
Today "Data Not Collected" is defensible. The moment RevenueCat ships (purchases, analytics), AI recap ships (user content sent to model provider), or Sentry/Crashlytics ships (diagnostics), the nutrition label must be rewritten before the first build containing those SDKs is uploaded.

#### Deliverables
- `docs/store-listing/privacy-labels-v1.1.md` — planned label matrix.
- `docs/store-listing/privacy-labels-v1.md` — current label snapshot.

#### Implementation approach
1. Document v1 label: `Data Not Collected` on both stores; `PrivacyInfo.xcprivacy` `NSPrivacyCollectedDataTypes=[]`.
2. Pre-author v1.1 label:
   - Purchases: collected, linked to identity, used for App Functionality.
   - User Content (Other User Content): collected on AI recap request, not linked, used for App Functionality. Disclose model provider and data retention.
   - Diagnostics: Crash Data + Performance Data, not linked, used for App Functionality, per Sentry/Crashlytics choice.
3. Gate label rewrite in release checklist — "if RevenueCat/AI/Sentry enabled in this build, update labels BEFORE submitting."

#### Review-guideline mapping
- Apple: 5.1.2 (consistent privacy disclosures), Privacy Nutrition Labels policy.
- Google Play: Data safety form policy.

#### Acceptance criteria
- [ ] v1 + v1.1 label matrices committed.
- [ ] Release checklist item added to `docs/store-listing/submission-checklist.md`.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): plan v1.1 privacy labels (Task 9.7)`.

#### Dependencies
- Blocks: v1.1 submission.
- External: RevenueCat / model provider data-handling disclosures.

---

### Task 9.8 — Guard "memory backup" framing against 1.4.1 / Medical Device risk

**Source:** A9 finding "Health claim exposure: 'memory backup' framing" · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
"Memory backup for people whose memory didn't bother saving it" is a safe metaphor today. But the README and brand guide flirt with "memory / ADHD / forgetting" language — if the store description nudges toward dementia / Alzheimer's / clinical memory benefit, both Apple 1.4.1 and FTC substantiation rules trigger.

#### Deliverables
- `docs/store-listing/health-claim-guardrails.md` — red/green word list.
- PR-check: lint step that fails if store copy contains red-list words.

#### Implementation approach
1. Red list (reject in listing and promotional text): dementia, Alzheimer, cognitive decline, memory loss, symptom, diagnose, treat, clinical, evidence-based, therapy, medical.
2. Yellow list (require reviewer approval): ADHD, neurodivergent, memory, forgetful, busy brain.
3. Green list (safe): journal, diary, mood, recap, daily, private, simple.
4. Add CI check (`tool/check_store_copy.dart`) that greps `docs/store-listing/*.md` and fails on any red-list term; passes yellow with reviewer ack.

#### Review-guideline mapping
- Apple: 1.4.1 Medical Device, 5.1.1(ix) health data, 3.1.7 uncontrolled health claims.
- Google Play: Health Apps policy, Misleading Claims, Medical Device.
- FTC Act §5 (substantiation).

#### Acceptance criteria
- [ ] Guardrails doc committed.
- [ ] Lint CI step fails on red-list words.
- [ ] Current draft listing passes lint.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): add health-claim guardrails (Task 9.8)`.

#### Dependencies
- Blocks: Task 9.2 copy finalization.

---

### Task 9.9 — Prepare 4+/Everyone age-rating answers + Caregiver uplift plan

**Source:** A9 finding "Age rating: caregiver monitoring on roadmap" · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P1 · **Effort:** S · **Tier:** v1 (answers) · Caregiver uplift plan in backlog

#### Problem
v1 has no caregiver/monitoring; age rating should be 4+ iOS / Everyone Play. But the feature roadmap has caregiver features — shipping those would need 12+ iOS / Teen Play and explicit data-sharing disclosure. Need both today's answers and tomorrow's uplift plan.

#### Deliverables
- `docs/store-listing/age-rating-ios.md` — App Store Connect questionnaire answers.
- `docs/store-listing/age-rating-android.md` — IARC questionnaire answers.
- `docs/store-listing/age-rating-caregiver-uplift.md` — pre-planned answers for when caregiver ships.

#### Implementation approach
1. iOS v1 answers: All categories "None" except "Unrestricted Web Access: No," "User Generated Content: No" (local-only), "Mature/Suggestive Themes: None" → yields 4+.
2. Play v1 (IARC): "Does your app collect personal information? No (local-only)," "User-generated content: No (not shared)," "Sensitive themes: No" → yields Everyone.
3. Caregiver uplift: UGC yes (shared with another party), data-sharing disclosure required, Medical-adjacent content flag if dementia targeting → likely 12+/Teen and Health Apps declaration triggered.

#### Review-guideline mapping
- Apple: App Store Connect age-rating questionnaire.
- Google Play: IARC questionnaire, UGC policy.

#### Acceptance criteria
- [ ] iOS + Play questionnaire answer docs committed.
- [ ] Caregiver uplift doc lists every answer that flips.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): age-rating answers (Task 9.9)`.

#### Dependencies
- Caregiver uplift: blocked by caregiver feature spec (Epic TBD).

---

### Task 9.10 — Document IAP/subscription posture for v1 (none) and v1.1 (RevenueCat)

**Source:** A9 finding "No IAP/subscription wiring yet" · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P1 · **Effort:** S · **Tier:** v1 (documentation) · implementation in Epic 13 paywall (v1.1)

#### Problem
v1 ships free. Apple 3.1.1 paid-up-front / 3.1.2 auto-renewing subscription obligations do not apply today but will at v1.1 when RevenueCat + paywall ship. Decision memo needed so App Review doesn't encounter a half-wired IAP.

#### Deliverables
- `docs/store-listing/iap-posture.md` — free in v1, RevenueCat subscription model in v1.1.

#### Implementation approach
1. v1: pubspec has no `purchases_flutter`. Store listing explicitly states "Free" and no "Offers in-app purchases" badge.
2. v1.1: `purchases_flutter` added, RevenueCat entitlements `retraq.premium.monthly`, `retraq.premium.annual`. Paywall displays title/length/price/auto-renew/ToS+Privacy per Agent 12 §12.
3. Ensure App Store Connect "Paid Applications Agreement" is accepted before v1.1 submission.

#### Review-guideline mapping
- Apple: 3.1.1 in-app purchase, 3.1.2(a) subscription disclosure.
- Google Play: Subscriptions policy.

#### Acceptance criteria
- [ ] IAP posture doc committed.
- [ ] v1 listing verified as "Free" and no IAP.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): IAP posture (Task 9.10)`.

#### Dependencies
- v1.1 implementation: Epic 12 Legal Task on subscription disclosure UI; Epic 13 paywall.

---

### Task 9.11 — Schedule TestFlight + Internal Testing → soft-launch → global

**Source:** A9 finding "Launch timing" · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
No documented launch plan. Need staged rollout to catch device-specific crashes, confirm wider Android device coverage, and buy time for review feedback before global release.

#### Deliverables
- `docs/store-listing/launch-plan.md` — 6-week schedule.

#### Implementation approach
1. Week 0-2: Closed TestFlight (iOS) + Play Internal Testing (Android), invite list ~25 testers, target Pixel 9 Pro XL + one iPhone 15+ + one older iPhone.
2. Week 3-4: Soft launch CA/AU/NZ (English-speaking, lower volume, IARC lenient). Monitor crash reports (Epic 10 Crashlytics), reviews, uninstall rate.
3. Week 5-6: Global release iOS + Play production.
4. Rollback criteria: crash-free rate <99.5%, 1-star review rate >5%, p0 crash found.

#### Review-guideline mapping
- Apple: TestFlight Beta App Review separately required before public testers.
- Google Play: staged rollout percentages in Play Console.

#### Acceptance criteria
- [ ] Launch plan doc committed.
- [ ] TestFlight invite list drafted.
- [ ] Play Internal Testing track opened.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): launch plan (Task 9.11)`.

#### Dependencies
- Blocked by: Epic 10 Crashlytics wiring, wider Android device testing.

---

### Task 9.12 — A/B test App Store subtitle with/without "Lost traq? Retraq." word-swap pun

**Source:** A9 finding "Tagline 'Lost traq? Retraq.' requires learning spelling" · **Rating:** Needs Prep
**Platforms:** Both
**Priority:** P2 · **Effort:** M · **Tier:** v1

#### Problem
The pun is strong in voice but forces users to learn the unusual spelling. Unclear whether it helps or hurts conversion. Use App Store Connect Product Page Optimization (PPO) and Play Console Store Listing Experiments to settle.

#### Deliverables
- `docs/store-listing/ab-tests.md` — test plan with variants, success metric, duration.

#### Implementation approach
1. Control (iOS subtitle): `Journal, mood, memory for ADHD` (Task 9.2).
2. Variant A: `Lost traq? Retraq it. Journal.` (31 — trim to 30: `Lost traq? Retraq. Journal now.` 31 — iterate).
3. Primary metric: Impression → Page View → Install conversion (per App Store Connect PPO report).
4. Duration: 14 days, 50/50 split, minimum 10k impressions per arm.
5. Guardrail: uninstall rate at 7 days.

#### Review-guideline mapping
- Apple: Product Page Optimization supports 3 variants.
- Google Play: Store Listing Experiments (up to 5 variants).

#### Acceptance criteria
- [ ] A/B plan committed.
- [ ] Variants launched T+14 days post-launch (not at submission — need baseline).
- [ ] Winner documented and rolled out.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): A/B subtitle plan (Task 9.12)`.

#### Dependencies
- Blocked by: launch (Task 9.11) — need live impressions before testing.

---

## Ready — No-op reference entries (already meets bar)

### Task 9.13 — Reference: Name "Retraq" distinctive; file trademark

**Source:** A9 finding "Name 'Retraq' no direct collisions; distinctive and trademarkable" · **Rating:** Ready
**Platforms:** Both
**Priority:** P3 · **Effort:** XS (app-side no-op) · **Tier:** no-op

#### Problem
None in-app. Recommendation is external: file trademark via CIPO (Canada) and USPTO.

#### Deliverables
- `docs/store-listing/trademark-status.md` — filing dates/references (tracked externally).

#### Implementation approach
1. No code change.
2. Bundle ID + display name already consistent (pubspec + Info.plist + build.gradle.kts).

#### Review-guideline mapping
- Not applicable (legal filing).

#### Acceptance criteria
- [ ] Trademark-status stub doc committed.
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(store): trademark stub (Task 9.13)`.

#### Dependencies
- External: CIPO + USPTO filing (outside engineering scope).

---

### Task 9.14 — Reference: Brand-guide listing copy already on-brand

**Source:** A9 finding "No store listing copy in repo except branding guide" · **Rating:** Ready
**Platforms:** Both
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Brand guide copy is on-brand and within Apple 4000-char limit. Task 9.2 carries the actual submission copy draft; this is the reference row so the brand guide is treated as the source of voice.

#### Deliverables
- Cross-link from `docs/store-listing/ios.md` to `docs/retraq-branding-guide.md`.

#### Implementation approach
1. Add a "Voice source: `docs/retraq-branding-guide.md`" header to Task 9.2 drafts.

#### Review-guideline mapping
- n/a.

#### Acceptance criteria
- [ ] Cross-link added (done as part of Task 9.2).
- [ ] Commit folded into Task 9.2.

#### Dependencies
- Folded into Task 9.2.

---

### Task 9.15 — Reference: Android permissions minimal

**Source:** A9 finding "Android permissions minimal" · **Rating:** Ready
**Platforms:** Android
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. `USE_BIOMETRIC`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` are minimal and documented.

#### Deliverables
- Entry in `docs/store-listing/android.md` explaining each permission (required when Play Data Safety reviewer asks).

#### Implementation approach
1. Document each permission justification.

#### Review-guideline mapping
- Google Play: Permissions policy.

#### Acceptance criteria
- [ ] Justifications noted in `docs/store-listing/android.md`.
- [ ] Folded into Task 9.2 commit.

#### Dependencies
- Folded into Task 9.2.

---

### Task 9.16 — Reference: iOS permission strings concise

**Source:** A9 finding "iOS permission strings concise" · **Rating:** Ready
**Platforms:** iOS
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. `NSFaceIDUsageDescription` and notification strings are exemplary (`"Retraq uses Face ID to keep your traqs private."`).

#### Deliverables
- Cross-link in `docs/store-listing/ios.md`.

#### Implementation approach
1. Document current strings verbatim so future edits don't regress.

#### Review-guideline mapping
- Apple: 5.1.1 Data Collection and Storage permission strings.

#### Acceptance criteria
- [ ] Strings recorded in `docs/store-listing/ios.md`.
- [ ] Folded into Task 9.2 commit.

#### Dependencies
- Folded into Task 9.2.

---

### Task 9.17 — Reference: Export compliance pre-declared

**Source:** A9 finding "Export compliance pre-declared" · **Rating:** Ready
**Platforms:** iOS
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. `ITSAppUsesNonExemptEncryption=false` + EAR 740.17(b) claim is correct for SQLCipher/AES usage.

#### Deliverables
- Entry in `docs/store-listing/ios.md` under "Compliance."

#### Implementation approach
1. Note the declaration source and rationale; reaffirm that the flag is correct as long as no non-exempt crypto is added.

#### Review-guideline mapping
- Apple: Export Compliance questionnaire.
- US BIS: EAR 740.17(b)(1) mass-market encryption exception.

#### Acceptance criteria
- [ ] Compliance note in ios.md.
- [ ] Folded into Task 9.2 commit.

#### Dependencies
- Folded into Task 9.2.

---

### Task 9.18 — Reference: Privacy Nutrition Label "Data Not Collected" defensible (v1)

**Source:** A9 finding "Privacy Nutrition Label 'Data Not Collected' defensible today" · **Rating:** Ready
**Platforms:** Both
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None today. v1.1 rewrite handled in Task 9.7.

#### Deliverables
- v1 label snapshot in `docs/store-listing/privacy-labels-v1.md` (produced in Task 9.7).

#### Implementation approach
1. No separate work.

#### Review-guideline mapping
- Apple: Privacy Nutrition Labels.
- Google Play: Data safety form.

#### Acceptance criteria
- [ ] Covered by Task 9.7 v1 snapshot file.

#### Dependencies
- Folded into Task 9.7.

---

### Task 9.19 — Reference: Onboarding COPPA-style age gate and consent

**Source:** A9 finding "Onboarding has COPPA age gate and consent page" · **Rating:** Ready
**Platforms:** Both
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None for Apple 1.3 / FTC neutral-age-screen requirement. Note: Epic 12 (Legal) flags a separate issue about country-aware age cutoffs (13 vs 14 vs 16); that is tracked there, not here.

#### Deliverables
- Cross-reference in `docs/store-listing/submission-checklist.md`.

#### Implementation approach
1. Add line: "Age gate at `lib/screens/onboarding/age_gate_page.dart:40-48` satisfies Apple 1.3 neutral-age-screen; country-aware variant tracked in Epic 12."

#### Review-guideline mapping
- Apple: 1.3 Kids Category / neutral age screen.
- FTC COPPA 16 CFR 312.

#### Acceptance criteria
- [ ] Cross-reference line added.
- [ ] Folded into Task 9.2 or submission-checklist commit.

#### Dependencies
- Cross-references Epic 12 age-gate task.

---

### Task 9.20 — Reference: Biometric-only login with PIN fallback

**Source:** A9 finding "Biometric-only login with PIN fallback" · **Rating:** Ready
**Platforms:** Both
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None for Apple 4.0.

#### Deliverables
- Entry in submission-checklist under "Compliance."

#### Implementation approach
1. Document `local_auth` usage + PIN fallback path so reviewer questions can be answered.

#### Review-guideline mapping
- Apple: 4.0 Design.

#### Acceptance criteria
- [ ] Entry in submission-checklist.
- [ ] Folded into Task 9.2 commit.

#### Dependencies
- Cross-references Epic 3 (biometric "Forgot PIN?" work) but no blocker.

---

## Rollup

- Total tasks: 20 (19 Agent-9 findings + 1 launch-plan derived from the "Launch timing" row — kept as single task 9.11; final count matches 19 table rows with 9.13-9.20 covering Ready rows).

(Correction: the Agent-9 table has 19 rows; this plan has 19 tasks numbered 9.1–9.20, with 9.13-9.20 representing the 8 Ready-rated rows as brief reference entries. Re-count: 12 actionable + 8 reference = 20 tasks. The reference rows are intentionally brief per template rules.)
