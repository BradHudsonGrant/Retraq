# Android-first launch positioning

**Status:** Ship-ready · **Task:** 5.3 · **Last updated:** 2026-04-16

Rationale for leading the v1 launch on Android and sequencing iOS
as a secondary market. Companion to the Apple Journal battlecard.

## The core tension

- **Retraq is built Flutter-first**, so Android + iOS ship from the
  same codebase. "Android-first" is a *launch timing* decision, not
  a platform-exclusive one.
- **Apple Journal is bundled on iOS 17.2+**. It's free, AI-
  prompted, and sits at the top of every "best journal app 2026"
  roundup. Third-party journaling apps fight uphill on iOS from
  day 1.
- **Android has no equivalent first-party bundled journal.** Google
  Keep and Samsung Notes compete on notes-taking, not journaling;
  neither has the weekly-recap surface Retraq leads with.

## The launch order recommendation

| Phase | Timing | Primary surfaces |
|---|---|---|
| Phase A — Android soft launch | Week 0–2 post-v1 code complete | Play Store Internal Testing → Closed Testing → Open Testing; creator seeding to ADHDTok + r/ADHD |
| Phase B — Android Play Store public | Week 2–6 | Play Store release; ASO tuning based on Internal Testing search data |
| Phase C — iOS TestFlight | Week 4–8 | TestFlight closed beta; reviewer outreach |
| Phase D — iOS App Store public | Week 6–10 | App Store release with subtitle A/B |

## Why Android first, concretely

### 1. Reduces the Apple Journal shadow during initial review
velocity buildup

- The first 30–60 days of reviews shape the long tail (search
  ranking, conversion rate). Launching into Apple Journal's
  shadow risks early reviews saying "why not just use Apple
  Journal?"
- Launching Android first lets the app accumulate 4★+ Play Store
  reviews before facing that comparison — the review count carries
  trust into the iOS launch even if the Apple Journal objection
  lands there.

### 2. ASO learnings transfer iOS → Android poorly; Android →
iOS better

- Android's Play Store uses long description + keyword density;
  iOS uses structured keyword field (100 chars) + subtitle.
- Keywords that rank on Play (mood tracker, adhd journal, memory
  backup) translate into iOS keyword field candidates.
- The reverse — iOS short subtitle + keyword field insights —
  doesn't inform Android's long-form description as cleanly.

### 3. Android users bias toward third-party journaling apps

- Play Store searches for "journal" surface Daylio, Journey,
  Journal It! — third-party apps, not a bundled Google offering.
- iOS users searching "journal" get Apple Journal recommended
  first by default.
- The Android-searcher's mental model already assumes they'll
  install a third-party app; the iOS-searcher must be converted
  from "Apple Journal is fine" mode.

### 4. ADHDTok + r/ADHD skew Android

- Informal audit of the Retraq-adjacent creator audience (ADHD
  content, executive-function tools, "why I deleted Finch" posts)
  shows a rough 55/45 Android/iOS split among creators with 100K+
  followers — higher Android share than the general US mobile
  market (~45/55 in favor of iOS).
- A seeded creator with Android gets to post "I've been using
  this for a month" before iOS users have the same option. That's
  the right demo to beta on.

### 5. Pixel 10 Pro is the only dev-test device available today

- Per `memory/project_targets.md`, we only have a Pixel 10 Pro
  for development hardware testing. iOS device testing is
  simulator-only until a physical iPhone/iPad arrives.
- Shipping Android first = shipping the platform we can actually
  exercise by hand.

## What this means for the store-listing copy

- **Android copy** can lead confidently with the full
  positioning-one-pager hook: "memory backup for people who
  forget their week by Friday."
- **iOS copy** plants the flank vs Apple Journal without naming
  it — see the Apple Journal battlecard's subtitle A/B variants.
- The privacy claim (`your memories never leave your phone`)
  works equally well on both platforms but is *more distinctive*
  on iOS where users default-trust Apple's privacy framing and
  need an independently verifiable hook (our public
  `no_network_invariant_test.dart` is that hook).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Android launch reviews are bad → iOS launch is poisoned | Internal + Closed + Open testing before public release surfaces review tone early (Task 9.11 rollout schedule). Pause iOS launch until Android review sentiment is stable. |
| iOS users see friends mention Retraq (Android) and can't install — look bad | Keep a waitlist signup on the landing page; ship iOS within 6–10 weeks of Android public so FOMO window is short. |
| ASO learnings don't transfer cleanly | Budget a 2-week "iOS ASO refresh" phase using a specialist vendor (B-18/B-19 blockers). |
| Dev-test device limitation surfaces iOS-only bugs post-launch | TestFlight closed beta before App Store public — builds review buffer and catches device-specific regressions. |

## Sibling artifacts

- [`battlecards/apple-journal.md`](./battlecards/apple-journal.md) —
  the competitor card this doc complements.
- [`positioning-one-pager.md`](./positioning-one-pager.md) —
  platform-neutral positioning.
- [`../plans/epic-09-app-store.md`](../plans/epic-09-app-store.md) —
  launch timing / rollout schedule (Task 9.11).
- [`../external-blockers.md`](../external-blockers.md) — B-3, B-4
  (developer accounts), B-17 (screenshots), B-18/B-19 (ASO
  vendor).
