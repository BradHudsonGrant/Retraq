# Google Play Store listing — Retraq

**Status:** Draft for v1 submission · **Task:** 9.2 · **Last updated:** 2026-04-16

Authoritative Play Console listing copy. See [`ios.md`](ios.md) for
differences between platforms.

## App name (50 chars)

Primary: **`Retraq — Remember Your Week`** (27 chars)

## Short description (80 chars)

Primary: **`Jot down your day in seconds. Never draw a blank when asked what you've been up to.`** (80 chars — on the line)

Alternative (ASO-heavy): **`ADHD-friendly journal. Quick traqs, private, on-device, zero tracking.`**

## Full description (4000 chars max)

Same body as iOS (`ios.md`) with these tweaks for Play Console:

- Add an Android-specific "Home screen widget" callout near the top.
- Replace "Face ID" with "Fingerprint / Face Unlock."
- Drop the "iOS + Android (separate purchases)" line.

See `ios.md` body for the full text. Edits limited to platform-specific
substitutions.

## Category

- **Primary:** Lifestyle (avoids Health Apps Declaration form)
- **Tags:** Journaling, Productivity (if Play allows multiple)

**Why not Health & Fitness as primary:** Agent 12 legal + Google Play
Health Apps policy (Jan 2026 enforcement) — Lifestyle is the safe
primary unless the listing makes medical claims, which it deliberately
does not.

## Age rating — IARC questionnaire

- Violence: No
- Profanity / Crude humor: No
- Sexual content: No
- User-generated content visible to other users: No (Retraq has no
  social / sharing / public feed features)
- User-to-user communication: No
- Shares location: No
- Digital purchases: **Yes** (when Retraq Pro ships in v1.1 — update
  the rating form at that point)
- Gambling: No

Expected rating: **Everyone (PEGI 3 / ESRB E)** for v1.

When caregiver (v2) ships, re-rate — adding invite-based data sharing
may push to Teen minimum.

## Data safety form

Google Play's Data Safety declaration (required since July 2022).

### Data collection

Q: Does your app collect or share any of the required user data types?
A: **No.** Retraq is fully on-device. No analytics. No tracking. No
network calls (enforced by Task 12.1 CI guard).

### Data encryption in transit

Not applicable (no data transmitted).

### Deletion

Users can delete all data via Settings → Data → "Delete all data"
(Task 12.9 verified irrecoverable).

### When v1.1 (Sentry crash opt-in) ships

Update the form to declare:
- Data type: Crash logs
- Collection purpose: App functionality, Analytics
- Shared with: Third party (Sentry)
- User control: Data is opt-in (default OFF); user can disable at any
  time in Settings → Data.

### When v1.1 (RevenueCat subscriptions) ships

Update the form to declare:
- Data type: Purchase history
- Collection purpose: Account management, Payments
- Shared with: Third party (RevenueCat)
- User control: Tied to Play Store account; managed via Play Store
  subscriptions.

## Screenshots

Required sizes:
- Phone: 16:9 or 9:16, min 320px, max 3840px (recommend 1080×1920)
- 7-inch tablet, 10-inch tablet: optional
- TV banner / Wear / Auto: N/A

See `docs/external-blockers.md#b-17` for shot-list. Coordinate with
Task 13.1 new icon before finalising.

## Feature graphic

1024×500px. Must be distinct from the icon. Recommended:
- Dark off-white background (matches in-app theme)
- Primary `#33694B` green accent
- Headline: `Lost traq? Retraq.`
- Subhead: `Quick daily journal. ADHD-friendly. Private.`
- 2-3 device frames showing Home, Recap, Stats

## Store listing experiments

Once on Play, run these A/B experiments:

| Experiment | Variant A | Variant B |
|---|---|---|
| Short description | `Jot down your day in seconds...` | `ADHD-friendly journal. Quick traqs...` |
| Feature graphic headline | `Lost traq? Retraq.` | `Your memory backup.` |
| First screenshot | "How've you been?" empathy | Quick-entry flow |

## Contact information

- Website: retraq.app
- Email: hello@retraq.app
- Phone: (optional — skip for privacy)

## Privacy policy URL

`https://retraq.app/privacy` — required by Google Play for apps
collecting any data. Retraq's policy remains live even though no
collection occurs, because Google scans for URL validity and the page
documents the on-device stance.

## Target API level

Must target the latest Android API level per Play Store policy.
Currently: **API 34 (Android 14)** as of 2026. Check Play Console
for the latest required level before every submission.

## App signing

- Android App Bundle (AAB) signed with release keystore managed by
  GitHub Secrets (`KEYSTORE_BASE64`).
- Task 3.3 (commit `9745bee`) added a fail-loud guard: CI and bundle
  builds refuse to fall through to debug keys.
- Play App Signing enabled (upload key separate from app signing key,
  Google manages the signing key).

## Release tracks

1. **Internal testing** — up to 100 testers; no review needed; use
   for rapid iteration.
2. **Closed testing (alpha)** — invite-only; Google reviews.
3. **Open testing (beta)** — anyone with opt-in link; Google reviews.
4. **Production** — all users; full review.

Recommended launch sequence per Task 9.11:
- Internal testing (1-2 weeks)
- Closed testing in CA/AU/NZ (2 weeks)
- Production global

## Submission checklist

- [ ] Screenshots produced per B-17
- [ ] Feature graphic produced
- [ ] New app icon (B-12 / Task 13.1)
- [ ] Listing copy reviewed through forbidden-claims list
- [ ] Data Safety form submitted (v1 = "no data collected")
- [ ] Age rating questionnaire submitted (Everyone)
- [ ] Privacy policy URL live
- [ ] App signed via CI (B-20)
- [ ] Target API level matches current Play requirement
- [ ] Release notes prepared
