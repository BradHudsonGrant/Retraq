# Daylio battlecard

**Status:** Ship-ready · **Task:** 5.2 · **Last updated:** 2026-04-16

> **Usable by creators / sales / press without modification.** If you
> open this thinking "can I paste this into a DM?" — yes. Copy the
> relevant section, swap the creator name, send.

Pair with the positioning one-pager (`../positioning-one-pager.md`)
and the primary narrative hook. Do NOT use this card to debate
Daylio's privacy posture in public — we flank via recall, not via
attack.

## The competitor at a glance

| Field | Daylio |
|---|---|
| Install base | 20M+ (Play Store) |
| Rating | 4.8★ (393K reviews Play, ~4.6★ iOS) |
| Price model | Free with Premium ($2.99–$4.99/mo or ~$23.99/yr) |
| Core pitch | "Track your mood + micro-activities in 30 seconds" |
| Platforms | iOS + Android |
| Positioning age | ~8+ years (launched ~2017) |
| Moat | Install base + mood-icon familiarity + streak gamification |

## Strengths — do not try to out-compete on these

- **Speed of entry.** Two-tap mood log. Competing on 30-second entry
  is a losing fight — they've optimized this for years.
- **Visual mood grid.** The mood-color grid is instantly recognizable
  and has pattern-recognition value. Do NOT clone it.
- **Install base flywheel.** Family/friend recommendation density
  pre-seeds new installs. We can't beat this with product alone.

## Weaknesses — where Retraq flanks

### 1. Recap depth

- Daylio shows a calendar of mood dots and aggregate pie charts.
- It does NOT generate a weekly summary you can re-read. It does
  NOT surface "here's what you wrote on a Tuesday" in a narrative
  form. Pattern-spotting lives with the user, not with the app.
- **Retraq counter:** Recap tab is a first-class read surface with
  week/month summary cards, "on this day last year," weekly trend,
  full-text search across entries. You open Retraq to *read your
  past self*, not to log.

### 2. Privacy story

- Daylio has ads, in-app Google Sign-In for backup, cloud sync via
  Dropbox/Google Drive, and their privacy policy permits analytics.
- The privacy nutrition labels list: Data Used to Track You (Usage
  Data, Identifiers).
- **Retraq counter:** Zero network calls in the app binary (enforced
  by `no_network_invariant_test.dart`). SQLCipher-encrypted DB. No
  ads. No trackers. No cloud sync in v1 — when it lands (v2), it's
  zero-knowledge envelope-encrypted per the Epic 3 threat model.

### 3. Anti-streak-shaming

- Daylio's streak breaks on any missed day and surfaces a red
  indicator + notification to "get back on track."
- **Retraq counter:** Freeze-equipped streaks — one gap per rolling
  7-day window without breaking. Milestone copy warm, not
  guilt-inducing. Nudges skip themselves if you've already journaled
  that day (surfaced in the nudge settings card per Task 2.14).

### 4. Caregiver / eldercare

- Daylio has no caregiver / family-sharing / cognitive-decline
  support surface. They're an individual-habit tool.
- **Retraq counter:** Deferred to v2. Do NOT lead with this in v1
  store listings — keep the caregiver narrative completely out of
  the Daylio flank. It's a separate market (Retraq Care).

## When Retraq wins — three scenarios

### Scenario A — "I stopped using Daylio because the streak broke"

- Daylio user misses two days, streak resets, feels shame, deletes.
- Retraq keeps the streak via freeze, doesn't surface red
  indicators, milestone copy celebrates ("Look at you go") not
  scolds ("You've broken your streak!").
- **Creator DM copy:** "If you've ever deleted Daylio because the
  streak made you feel bad after one bad week — Retraq keeps going
  when you don't."

### Scenario B — "I want to look back at my week, not log it"

- Daylio user wants Sunday-night reflection but only sees mood
  dots and pie charts. No narrative to re-read.
- Retraq's Recap tab is the read-first spine. Weekly summary card.
  Full-text search. "On this day last year" recurrence.
- **Creator DM copy:** "Retraq's Recap tab is the thing you open
  Sunday night to see your week. Daylio tells you the mood. Retraq
  tells you the story."

### Scenario C — "I don't want my journal on Google's servers"

- Daylio's backup flow routes through Google Drive / Dropbox.
- Retraq's data never leaves the device unless the user explicitly
  exports to a file and hands it to the OS share sheet.
- **Creator DM copy:** "Retraq's data can't leak because Retraq
  doesn't have servers. Your entries are on your phone, encrypted,
  full stop."

## Objection handling

### "But Daylio is free and established"

> Retraq's free tier is also free. The v1.1 Pro IAP is a one-time
> $5.99 unlock for advanced features (see our pricing page); core
> journaling stays free forever. The 'established' case cuts both
> ways — if you've been on Daylio for 3 years and your mood grid
> hasn't surfaced a recap worth re-reading, that's the problem
> Retraq is designed for.

### "Switching costs — I have 2 years of Daylio data"

> We ship a CSV/JSON import path. Your Daylio export lands in
> Retraq as date-stamped entries with mood and note. (Import path
> tracked in Task 8.3 / 11.1 — verify with the user before
> committing a public claim.)
>
> **Internal note to self:** Confirm this import path is built
> before making the public claim. If not, the honest copy is:
> "Not yet, but it's on the v1.1 roadmap. For now, treat Retraq
> as your go-forward log and Daylio as your archive."

### "Does Retraq have the mood grid?"

> No, and that's deliberate — we're not a mood-tracker, we're a
> memory backup that happens to support opt-in mood. If mood
> tracking is your primary pitch to yourself about journaling,
> Daylio is the right tool. If you open your journaling app to
> *read your past self* rather than to *log right now*, that's
> where Retraq starts winning.

## What creators should NOT do

- Do NOT tag @Daylio or their team in comparison posts. We're
  flanking, not dunking.
- Do NOT claim Daylio is "spying on you" — their privacy posture
  is consistent with their free-tier business model and the attack
  lands us in counter-claims we can't back.
- Do NOT promise feature parity on mood UX. Mood is a deliberately
  reduced surface in Retraq (single switch per Task 4.5).

## Sibling artifacts

- [`../positioning-one-pager.md`](../positioning-one-pager.md)
- [`../narrative-hook.md`](../narrative-hook.md)
- [`competitor-keywords-daylio.md`](./competitor-keywords-daylio.md)
  *(planned as part of this task — see below)*

## Follow-up artifacts to generate from this battlecard

- **Screenshot overlay copy** for the Recap tab in iOS + Play
  listings: *"The week you forgot. Retraqed."* — blocked on B-17
  screenshot vendor.
- **ASO keyword overlap** — 10 Daylio-ranking keywords Retraq can
  rank adjacent-to (`mood tracker`, `daily journal`, `micro journal`,
  `quick mood log`, `feeling tracker`). See `docs/store-listing/aso-keyword-strategy.md`.
