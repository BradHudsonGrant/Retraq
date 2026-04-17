# External blockers — action items for the user

This is an actionable checklist of every task in the implementation plan that
cannot be completed by me (Claude) inside the repo. Each item requires a
real-world action — an account, a payment, a vendor engagement, a design
artifact — from you.

When you complete one, check its box and ping me with the artifact/credential.
I'll then execute the implementation half of the task inside the repo.

Budget totals: see [`implementation_plan.md` Appendix D](../implementation_plan.md#appendix-d--budget-summary) — $5.6k–$18.6k CAD for v1 launch, up to ~$44k for the full plan.

---

## Infrastructure & accounts

### [ ] B-1. Sentry account + DSN  _(blocks Task 1.2, Task 10.1)_

**What I need from you:**
- Sentry.io account (free tier is sufficient: 5k events/month, 30-day retention)
- Create a Flutter project in Sentry
- Supply the DSN string (looks like `https://xxxxxxx@o000000.ingest.sentry.io/0000000`)
- Supply an auth token for dSYM/symbol uploads in CI

**Where to put them:**
- Add `SENTRY_DSN` to GitHub Secrets (for `release.yml`)
- Add `SENTRY_DSN_DEV` for optional dev flavor
- Add `SENTRY_AUTH_TOKEN` to GitHub Secrets (read-only symbol-upload scope)

**Cost:** Free tier suffices initially. Team plan ~$26/mo if volume grows.

---

### [ ] B-2. RevenueCat account  _(blocks Task 4.9, Task 12.10, Task 5.5, Epic 11 monetization metrics)_

**What I need from you:**
- RevenueCat.com account (free up to $2.5k MTR)
- App configured for both iOS (App Store Connect linking) and Android (Google Play linking)
- API keys (public)
- Products configured: `retraq_pro_lifetime` (one-time $5.99) + `retraq_cloud_monthly` / `retraq_cloud_yearly` (subscription $2.99/mo or $24.99/yr) — matching the v1.1 monetization decision.

**Where to put them:**
- `ios/Runner/RevenueCat-Info.plist` or env-driven config
- `android/app/build.gradle.kts` buildConfig field
- GitHub Secrets for CI-driven paywall preview builds

**Cost:** Free until $2.5k MTR. Then 1% take-rate (industry standard).

---

### [ ] B-3. Apple Developer Program  _(blocks Task 10.2 iOS TestFlight automation, Task 9.1 iOS screenshots, Task 12.10 subscription disclosure)_

**What I need from you:**
- Apple Developer Program enrollment ($99 USD/yr) — organization or individual
- Team ID
- App Store Connect app record created for `com.retraq.app`
- App Store Connect API key (.p8 file) with the correct key ID + issuer ID for fastlane uploads
- Signing identities (Distribution) and provisioning profiles (App Store + TestFlight)

**Where to put them:**
- `.xcconfig` for `RETRAQ_DEVELOPMENT_TEAM` (local, NOT committed)
- GitHub Secrets: `APP_STORE_CONNECT_API_KEY_CONTENT`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
- Fastlane `match` repo for cert sync (optional but recommended)

**Cost:** $99 USD/yr.

---

### [ ] B-4. Google Play Developer account  _(blocks Task 10.7 Play Store internal track deploy, Task 9.1 Android screenshots)_

**What I need from you:**
- Google Play Console account ($25 USD one-time)
- App record created for `com.retraq.app`
- Service account (JSON key) with Play Console access for CI uploads (via `r0adkll/upload-google-play`)
- Internal testing track set up

**Where to put them:**
- GitHub Secret `PLAY_STORE_SERVICE_ACCOUNT_JSON` (base64 of the JSON)

**Cost:** $25 USD one-time.

---

### [ ] B-5. Canadian business entity  _(blocks Task 12.2 privacy policy controller, Task 12.11 address disclosure, Task 13.6 trademark filing as entity)_

**What I need from you:**
- Sole proprietorship, numbered company, or incorporation (CIPO federal or provincial)
- Registered business name (can be "Retraq" if available, or "Brad Hudson Grant DBA Retraq")
- Physical mailing address (home, virtual office, iPostal1, Earth Class Mail — roughly $10–30/mo for virtual)
- Business email alias (e.g. `privacy@retraq.app`, `contact@retraq.app`)

**Where to put them:**
- Update `lib/legal/privacy_policy.dart` controller disclosure
- Update `lib/legal/terms_of_service.dart` address block
- Record in `docs/legal/entity-disclosure.md`

**Cost:** $0–$300 CAD for registration. Virtual office optional ~$10–30/mo.

---

## Legal / counsel engagements

### [ ] B-6. Privacy counsel — initial review  _(blocks Task 12.2 polished release)_

**Scope:** One-pass Canadian/EU privacy-policy review; validate controller disclosure, GDPR 13/14 completeness, PIPEDA accountability, Quebec Law 25 alignment.

**Cost:** $500–$1500 CAD.

**Vendors:** Any Canadian tech-privacy lawyer (Cassels, Osler, Borden, INQ, Privcom — or smaller solo firms).

---

### [ ] B-7. Privacy counsel — ToS carve-out review  _(blocks Task 12.6)_

**Scope:** Verify the mandatory-local-consumer-law carve-out language works against Quebec C.P.A., EU Unfair Terms, Cal. ARL, UK CRA. ~1 hour of counsel time.

**Cost:** $500–$1000 CAD. May bundle with B-6 for efficiency.

---

### [ ] B-8. Privacy counsel — subscription disclosure  _(blocks Task 12.10, gates v1.1 paid release)_

**Scope:** Paywall copy passes Apple 3.1.2(a), Google Play Subs, Cal. ARL one-tap, EU CRD 14-day cooling-off, Quebec C.P.A. 230-231. Review the disclosure matrix at `docs/legal/paywall-disclosure-matrix.md`.

**Cost:** $1000–$2500 CAD.

---

### [ ] B-9. Privacy counsel — Art. 9 / AI transparency  _(blocks Task 12.4, Task 12.13; gates any cloud AI ship)_

**Scope:** Explicit-consent Art. 9 gate; EU AI Act Art. 50 transparency; Quebec PIA for cross-border transfer.

**Cost:** $2000–$5000 CAD one-time; $1500–$3000 more for each new AI provider/DPA.

---

### [ ] B-10. Privacy counsel — caregiver pre-build framework  _(blocks Task 12.12; gates ALL Retraq Care work)_

**Scope:** Controllership model; capacity attestation; substitute-decision authority (Ontario SDA, Quebec Curatelle, US state equivalents); mandatory elder-abuse reporter analysis; DPA template. Non-negotiable — cannot start any caregiver code without this.

**Cost:** $5000–$15000 CAD. Single largest external cost in the plan.

---

### [ ] B-11. Accessibility audit (independent WCAG 2.2 AA)  _(blocks Task 12.14, gates EU market release)_

**Scope:** WCAG 2.2 AA + EN 301 549 + mobile. Vendors: Deque, TPG, Accessible Web, Inclusive Design Research Centre (IDRC, Canadian).

**Cost:** $3000–$10000 CAD.

---

## Brand / design

### [ ] B-12. Icon designer  _(blocks Task 13.1 — single biggest first-impression lever in the plan)_

**Scope:** 3 concept directions (Q-pin, Q-speech-bubble, Q-dot-marker — see `docs/plans/epic-13-brand.md#task-131`) at 192×192 with 4 color variants. Two revision rounds. Final asset matrix: iOS (1024 App Store + 8 smaller sizes), Android adaptive (foreground+background+monochrome), notification monochrome 24dp.

**Where to source:** Dribbble search "app icon designer", Fiverr Pro, 99designs contest, or personal network.

**Cost:** $500–$2500 CAD.

---

### [ ] B-13. Icon shelf test  _(part of Task 13.1)_

**Scope:** Export each concept at 180×180; arrange in a 4×6 grid beside 12 competitor icons (Instagram, TikTok, Notes, Day One, Daylio, Apple Journal, How We Feel, Finch, Reflectly, Journey, Moodnotes, Stoic); rank by category-signal with 5–10 friends/testers.

**Cost:** $0 (volunteer feedback).

---

### [ ] B-14. Sub-brand decision (v2, caregiver)  _(blocks Task 13.5 execution; gates Retraq Care work)_

**Scope:** Decide: standalone sub-brand ("Retraq for Family") or feature toggle within current app. Recommendation in the plan is standalone. Produce 3 concept sketches with user-test feedback.

**Cost:** $500–$2000 CAD (designer concepts) + time for user testing.

---

## Trademark

### [ ] B-15. CIPO (Canada) trademark filing  _(blocks Task 13.6 ® usage in Canada)_

**Scope:** Word mark "RETRAQ" in Nice Classes 9 (software) + 42 (SaaS). Filed at https://ised-isde.canada.ca/.

**Cost:** $458 CAD first class + $139 second class. Optional attorney: $500–$1500.

**Timeline:** ~18 months to registration; immediate use of ™.

---

### [ ] B-16. USPTO (US) trademark filing  _(blocks Task 13.6 ® usage in US)_

**Scope:** TEAS Plus filing, Classes 9 + 42, intent-to-use basis (switch to use-based at launch).

**Cost:** $250/class = $500. Optional attorney: $500–$1500.

**Timeline:** ~12–18 months; immediate use of ™.

---

## App Store / Play Console assets

### [ ] B-17. Screenshot production  _(blocks Task 9.1)_

**Scope:** 6–8 framed screenshots per platform, narrative arc: empathy hook → quick entry → mood → week recap → stats → privacy pillar. Requires:

- Live builds running on iPhone 15 Pro / 15 Plus / iPad Pro 12.9" simulators (or real devices)
- Live builds on Pixel 9 Pro XL simulator (or real device) for Play feature graphic
- A tool to add device frames + overlay copy (Figma, Screenshots.pro, AppLaunchpad, or Rotato)

**Cost:** Free if you use Figma + simulators; $15–50/mo for a tool like AppLaunchpad.

**Artifact location:** `app/assets/store-screenshots/` (new) and `docs/store-listing/`.

---

### [ ] B-18. ASO keyword research  _(feeds Task 9.3)_

**Scope:** Keyword-volume + competition data for ADHD journaling, memory journal, mood diary, daily log, etc. I can draft a strategy table; you verify with a real ASO tool.

**Vendors:** MobileAction free tier, AppTweak trial, Sensor Tower, App Radar.

**Cost:** $0–$80/mo for trial access; $200+/mo for full ASO tool. Free tier may suffice initially.

---

### [ ] B-19. Marketing listing copy final review  _(feeds Task 9.2)_

**Scope:** Once I draft listing copy, you approve / copy-edit before submitting to App Store Connect / Play Console. No external vendor required unless you want a copywriter polish ($200–$500).

---

## Commercial signing credentials

### [ ] B-20. Android release keystore  _(blocks Task 10.4 fail-loud guard, though the keystore already exists per audit)_

**What I need:**
- Confirm keystore file is stored somewhere safe and not in the repo
- Confirm `key.properties` (local) and GitHub Secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) are set for CI

Per the audit, this is already in place — just needs verification.

---

## Creator / community outreach

### [ ] B-21. ADHDTok creator seeding list  _(blocks Task 5.8)_

**Scope:** Compile 20–30 handles of ADHD-focused TikTok creators (mid-tier, 10k–500k followers). Seed each with a free Retraq Pro code and the "for people who forget Tuesday by Thursday" creative brief.

**Cost:** $0 (free codes) + time to curate list. Optional paid seeding service: ~$200–$1000 per campaign via agencies like Linqia or Insense.

---

### [ ] B-22. r/ADHD mod outreach  _(blocks Task 5.8)_

**Scope:** Soft introduction of Retraq to r/ADHD mods; request sticky post or launch-day AMA. Requires building a relationship — do NOT spam.

**Cost:** $0 + relational time.

---

### [ ] B-23. Therapist referral partnerships  _(blocks Task 5.7 caregiver + Task 5.8 ADHD channels)_

**Scope:** List of 5–10 therapists / ADHD coaches willing to mention Retraq to clients. Provide them with a printable "why a simple journal helps" one-pager.

**Cost:** $0 + outreach time. Optional: small affiliate program via ReferralCandy ($100/mo).

---

### [ ] B-24. Codecov token  _(activates Task 10.8 upload step)_

**What I need from you:**
- Codecov.io account (free tier — public repos unlimited; private repos free under 5 users)
- Add the Retraq repo
- Copy the repo token from Codecov → add to GitHub Secrets as `CODECOV_TOKEN`

**Why:** `ci.yml` now uploads `coverage/lcov_filtered.info` to Codecov on every PR (commit `8790891`). Without the token the action runs but silently no-ops — that's intentional (`fail_ci_if_error: false`). Adding the secret flips on the 70% patch-coverage gate already configured in `codecov.yml`.

**Cost:** Free.

---

## Recommended ordering

**Earliest (before v1 submission):**
- B-3, B-4 (developer accounts) — you literally cannot ship without these
- B-5 (Canadian entity) — required for privacy policy completeness
- B-20 (keystore verification) — quick sanity check
- B-12 (icon designer) — 2-week turnaround typical
- B-17 (screenshots) — can start once icon is chosen
- B-15, B-16 (trademark filings) — file early for priority date
- B-6, B-7 (privacy counsel basic) — ~$1k total; unblocks legal text

**Mid (v1.1 / post-launch):**
- B-1 (Sentry) — can go live any time
- B-2 (RevenueCat) — needed when you wire the paywall
- B-8 (subscription counsel review)
- B-18, B-19 (ASO polish)
- B-11 (independent WCAG audit, before EU release)
- B-21, B-22, B-23 (creator/community seeding)

**Later (v1.1 cloud AI, v2 caregiver):**
- B-9 (Art. 9 / AI Act counsel review)
- B-10 (caregiver pre-build framework, $5–15k — single biggest cost)
- B-14 (sub-brand decision)

---

## Deferred internal follow-up work

Items that I encountered during implementation but chose to defer to
dedicated follow-up commits. These are NOT external blockers — they're
code work I will come back to — but you asked me to track them here
for visibility. Each has a note on when to tackle it.

### [ ] D-1. Expand lint rules deferred during Task 1.5

When I shipped the Task 1.5 lint expansion (commit `15987f4`), I scoped
it to the rules that land clean. Four rules would have surfaced ~100
info-level warnings each needing per-site judgment:

- `unawaited_futures` — ~30 sites, mostly intentional fire-and-forget in
  Flutter widget lifecycle callbacks. Fix by wrapping with
  `unawaited(...)` per-site.
- `discarded_futures` — similar; often `onPressed: () => asyncFn()`.
  Fix by making callbacks async or wrapping with `unawaited(...)`.
- `unnecessary_lambdas` — mostly in test closures; cosmetic tearoff
  refactor.
- `avoid_dynamic_calls` — mostly test-double shims; tests legitimately
  use `dynamic` for mocking patterns.

**When:** v1.1 polish. Split into 4 separate commits, one per rule, so
each is reviewable.

### [ ] D-2. Real virtualization for Recap screen (follow-up to Task 8.1)

Task 8.1 (commit `46ed3e9`) flattened the fake-sliver `CustomScrollView`
inside MonthView and SearchView to plain Column for semantic clarity
and small perf win. TRUE lazy virtualization — meaningful at 500+
search results or multi-year month views — requires restructuring the
outer `recap_screen.dart` SingleChildScrollView into a single
`CustomScrollView` with slivers for calendar + week/month toggle +
entry list.

**When:** v1.1 performance polish, or when user complaints about search
latency surface. Current FTS5 `LIMIT 50` makes this non-urgent.

### [ ] D-3. True iOS FLAG_SECURE equivalent (follow-up to Task 3.5/3.6)

Task 3.5 (commit `4994f72`) added in-Flutter lock on `inactive`/`paused`/
`hidden` lifecycle. That's defense-in-depth; the canonical iOS fix is
a native blur overlay swapped in on `applicationWillResignActive`.
Task 3.6 is still pending — it requires iOS native Swift work in
`ios/Runner/AppDelegate.swift` + a method-channel hook. Can't be done
from inside Flutter code alone.

**When:** before iOS TestFlight launch. Requires Apple Developer Program
access (B-3) to test on a real device. Logged as pending in
implementation_plan.md.

### [ ] D-4. Fix 8 pre-existing test failures from in-flight l10n work

The working tree had uncommitted modifications to `lib/l10n/*`,
`lib/legal/*`, `lib/utils/entry_action_dialogs.dart`, etc. before this
session started. Those changes partially localize strings but their
matching test fixtures still look for the English literals ("No entry
for this day", "Search entries...", etc.). Running `flutter test`
reports 8 failures unrelated to anything I shipped.

**When:** as part of the ongoing l10n workstream commits. Either the
in-flight mods need a matching test-fixture update, or the tests
need to be updated to use L10n.of() lookups for expected strings.

### [ ] D-5. iOS release signing automation (follow-up to plan)

Currently `release.yml` builds iOS with `--no-codesign`. A full
TestFlight upload requires fastlane + App Store Connect API key.
Blocked by B-3 (Apple Developer Program).

**When:** as soon as B-3 lands. This is Epic 10 Task 10.2.

### [ ] D-6. Sentry wiring (follow-up to Task 1.11 deferred)

AppLog wrapper + 9 bare-catch replacements are scheduled for dedicated
commits (Task 1.2, 1.6, 1.11 per plan). They were NOT included in the
Task 1.5 lint commit. Blocked by B-1 (Sentry DSN).

**When:** as soon as B-1 lands.

### [ ] D-7. Android Gradle Plugin 9.x upgrade — blocked upstream by Flutter SDK

> **PR status (2026-04-16):** Dependabot PR #22 was closed with this
> context. When Dependabot opens the next AGP 9.x bump, reopen this
> item and retry after checking the Flutter SDK unblock below.

Dependabot opened PR #22 bumping com.android.application from 8.9.1 to
9.1.1. This is a MAJOR version bump of the Android Gradle Plugin.

#### 2026-04-16 investigation — why it can't merge yet

I attempted to merge PR #22 in this session. The required toolchain
moves are all well-understood:

1. `android/gradle/wrapper/gradle-wrapper.properties` — Gradle 8.11.1 → 9.3.1
   (Gradle 8.13 was attempted first; AGP 9.1.1 rejects it with
   "Minimum supported Gradle version is 9.3.1").
2. `android/app/build.gradle.kts` — `JavaVersion.VERSION_11` → `VERSION_17`
   for both `sourceCompatibility`/`targetCompatibility` and
   `kotlinOptions.jvmTarget`. CI already runs JDK 17 and the dev
   machine has JDK 17 installed, so this bump is compatible with the
   current environment.

After those two bumps, the build failed with:

```
Failed to apply plugin 'kotlin-android'.
  Cannot add extension with name 'kotlin', as there is an extension
  already registered with that name.
```

This is **AGP 9's built-in Kotlin support** colliding with the
separately-applied `kotlin-android` / `org.jetbrains.kotlin.android`
plugin. The recommended opt-out is `android.newDsl=false` in
`gradle.properties`, and when I applied that the Flutter CLI itself
printed:

```
[!] Starting AGP 9+, only the new DSL interface will be read. This
results in a build failure when applying the Flutter Gradle plugin
...
To resolve this update flutter or opt out of `android.newDsl`. For
instructions on how to opt out, see:
https://docs.flutter.dev/release/breaking-changes/migrate-to-agp-9
```

So both paths fail in Flutter 3.41.6:
- `android.newDsl=true` (AGP 9 default) — Flutter Gradle plugin
  throws NullPointerException because it doesn't read the new DSL.
- `android.newDsl=false` — AGP 9's built-in Kotlin extension
  collides with the Kotlin Gradle Plugin that Flutter still
  auto-applies.

**This is not a config we can fix from inside the Retraq repo.** The
block is upstream in `dev.flutter.flutter-gradle-plugin` — that plugin
needs to support the AGP-9 new-DSL path AND either stop auto-applying
KGP or use AGP's built-in Kotlin when running on AGP 9.

#### Verification that the revert is clean

After reverting the PR #22 cherry-pick (commit 3d5f151) the repo
returns to AGP 8.9.1 / Gradle 8.11.1 / Java 11. I re-ran
`flutter build apk --debug --target-platform android-arm64` and it
built successfully — confirming the revert left no residue.

#### Unblock path

Two options:

1. **Wait for a Flutter SDK update that supports AGP 9 natively.** As
   of 2026-04-16, the released Flutter channels (including the 3.41.x
   stable pinned at `.fvmrc`) all break under AGP 9 per the error
   above. Watch the Flutter release notes for "AGP 9 support" and
   upgrade `.fvmrc` + CI when it lands. At that point Dependabot's
   next AGP bump becomes mergeable.

2. **Upgrade Flutter SDK pre-emptively to a beta/master channel that
   has the fix.** Not recommended for a pre-launch app. Stability of
   the app > staying on the latest plugin.

Low-priority follow-up: when the Flutter SDK unblock ships, also bump
`android/app/build.gradle.kts` Java source/target and kotlinOptions
jvmTarget to 17 in the same commit (they were already 17 in CI but
11 in the local build file — a gentle mismatch that the next release
engineering pass should fix regardless of AGP version).

**When:** as soon as a Flutter stable release lists AGP 9 support in
its release notes.

**History:** PR #22 (commit `17eb7e1`) was reverted on main via
`3d5f151` and the PR itself closed on 2026-04-16 with a pointer to
this section. Dependabot will open a fresh PR when a newer AGP 9.x
release lands — by then the Flutter SDK unblock above may be in
place, so retry the same two-line bump (Gradle + Java) at that point.

## How to unblock

Each checklist item is a `B-N` (external) or `D-N` (deferred internal).
When you complete an external blocker, comment on the relevant Task
or open an issue with the artifact / credential / decision, and I'll
resume work on the blocked tasks.

Cross-referenced blockers per Epic task ID live in
[`docs/plans/epic-*.md`](plans/) — search for "External" in the Dependencies
section of each task.
