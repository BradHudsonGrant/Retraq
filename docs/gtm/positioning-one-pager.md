# Retraq positioning one-pager

**Status:** Ship-ready · **Task:** 5.1 · **Last updated:** 2026-04-16

A single page a creator, ASO copywriter, or press contact can read in
90 seconds and restate Retraq's value in one sentence without using
the word "simple." Paired with the narrative hook (below) and the
Daylio/Apple Journal/Rosebud battlecards (`docs/gtm/battlecards/`).

## One-sentence hook

> **Retraq is the on-device memory backup for ADHD adults who forget
> their week by Friday — drop a sentence a day, get it back as a
> recap when your brain goes blank.**

Use this verbatim in creator DMs, press outreach, and the paid-ads
headline slot. The store-listing subtitle is the shorter pun version
(`Lost traq? Retraq.`) because the app icon + screenshots carry the
rest of the story on store.

## Target persona — v1

- **Who:** ADHD adults, 25–45, who have tried Daylio or Apple Journal
  and bounced because the friction didn't fit the "open the app when
  you actually remember" use pattern.
- **Core job-to-be-done:** "When I try to remember what happened last
  week, my brain is blank. I want to open an app and see a warm
  recap of the week I just had, not a blank page asking me to
  journal."
- **NOT targeted in v1:** elderly memory-loss / caregiver
  (deferred to v2 — see `implementation_plan.md` Part III).
  The caregiver market is real and addressed separately by
  Retraq Care; do NOT let that narrative leak into v1 copy.

## The wedge — three proof points

Retraq wins on **recall**, not on entry friction. The three things
Daylio, Apple Journal, and Rosebud do weakly are the three things
Retraq leads with:

1. **On-device privacy as the default, not an upsell.**
   Zero network calls. Zero analytics. CI-guarded (Task 12.1).
   SQLCipher-encrypted. Users who export a file pick where it goes
   — the app never opens a socket itself.
   *Counter-positioning line:* "Your memories never leave your
   phone."

2. **Recap-first interaction model.**
   Every tab above the bottom-nav is a read surface (Home with
   recent-recall, Recap with week/month summary, Stats with streak
   visualization). The Jot tab is *one* of the tabs, not the
   centerpiece. Daylio and Apple Journal force you into "new entry"
   flow first. Retraq assumes you open the app to *see*, not to
   write.
   *Counter-positioning line:* "The week you forgot. Retraqed."

3. **Anti-streak-shaming.**
   Freeze days every 7 (one gap allowed per rolling week without
   breaking the streak). Milestone copy is warm ("Look at you go")
   not Duolingo-red-bird ("You've broken your streak!"). Nudges
   skip themselves if you've already journaled (surfaced in the
   Nudge settings card per Task 2.14). The goal is *a habit you
   keep*, not *a metric the app demands you protect*.
   *Counter-positioning line:* "No streaks to protect, no guilt
   to carry."

## "Why now" line

- **ADHD journaling apps are all converging on the same UX** (mood
  icon + one-tap save) and the differentiation has collapsed. The
  "streak shaming" backlash (visible in r/ADHD and TikTok "I deleted
  Finch because it made me cry") is a real opening.
- **iOS Apple Journal shipped in iOS 17.2** and has the
  "write-first" model as its spine. Users who want recall-first
  have nowhere to go on iPhone. Retraq's iOS listing leads with
  this gap.
- **On-device privacy regulatory tailwind** — Apple's Privacy
  Nutrition Label, Play Data Safety, Quebec Law 25, GDPR Art. 25
  by-design expectations — every quarter makes "Zero data leaves
  your device" more valuable, not less.

## How this differs from "just another ADHD journal"

An ADHD journal competitor hears "ADHD + journal + mood tracker" and
reaches for the same feature list. Retraq reaches past the feature
list:

| They claim | Retraq claims |
|---|---|
| Simple | Nothing. "Simple" is table stakes. |
| ADHD-friendly UX | **Recall-first** UX. Simple is a *consequence* of recall-first, not the pitch. |
| Mood tracking | Mood opt-in (off by default). Because ADHD users who want mood already know they want it; forcing it makes the first-run feel clinical. |
| Private | **On-device only, CI-guarded.** Not a marketing claim — a verifiable architectural promise. |
| Streaks | **Freeze-equipped streaks.** The freeze is a product philosophy statement. |
| Journaling app | **Memory backup.** The frame is different — you're not keeping a journal, you're keeping a week you'll otherwise lose. |

## Writing rules for anyone using this one-pager

- **Never use the word "simple"** in marketing copy. It's the most
  crowded word in this category and it's lazy positioning.
- **Never use "powerful" or "complete solution"** — clinical-software
  language. Brand voice is warm, not medical.
- **Never promise "clinical outcomes"** (see Epic 12 health-claims
  audit Task 12.5 / 9.8). We're a journaling app, not a treatment.
- **Do lean into the pun** (`Lost traq? Retraq.`) in English-market
  short slots. The pun passes the 3-second recall test.
- **Do lean into specifics** — "forget Tuesday by Thursday" beats
  "ADHD-friendly" in every click-through test we've seen on similar
  positioning.

## Sibling artifacts

- [`docs/brand/taglines.md`](../brand/taglines.md) — the 5 tagline
  variants with A/B rationale (maps to Task 5.1 deliverable
  `docs/gtm/taglines-ab.md`).
- [`docs/brand/retraq-branding-guide.md`](../brand/retraq-branding-guide.md)
  — canonical voice, palette, vocabulary.
- [`docs/store-listing/`](../store-listing/) — iOS/Play listing copy.
- [`docs/gtm/battlecards/`](./battlecards/) — per-competitor wins (5.2 onward).
- [`implementation_plan.md`](../../implementation_plan.md) Part II + III —
  the v1.1 monetization + v2 dropped-scope narrative.

## Out-of-scope for this one-pager

- Paywall language — handled in v1.1 Pro IAP artifacts (`docs/gtm/pricing-ab.md`, Task 5.5/5.11).
- Caregiver messaging — v2 only (`implementation_plan.md` Part III.1).
- Clinical positioning — explicitly avoided (see Task 9.8 guardrails).
