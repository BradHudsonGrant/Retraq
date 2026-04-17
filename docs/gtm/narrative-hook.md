# Retraq narrative hook

**Status:** Ship-ready · **Task:** 5.1 · **Last updated:** 2026-04-16

The one-sentence hook used across every external surface: App Store
subtitle, Play short description, press outreach, creator DMs,
landing page hero.

## The hook

> **The on-device memory backup for people who forget their week by
> Friday. Drop a sentence a day; get it back as a recap when you
> need it.**

### Compressed variants by slot

| Slot | Character budget | Copy |
|---|---|---|
| iOS App Store subtitle | 30 | `Lost traq? Retraq.` |
| iOS App Store promotional text | 170 | `The on-device memory backup for ADHD brains. Drop a sentence a day — get your week back as a recap. No streaks to protect, no data to lose.` |
| Play short description | 80 | `Memory backup for ADHD brains. Drop a sentence a day, retraq your week.` |
| Play full description — opening line | — | Same as full hook above. |
| Press outreach subject line | ~60 | `Retraq — the recall-first journal for ADHD adults.` |
| Creator DM opener | ~200 | `Hey {name} — I built Retraq for the week-blackout problem ADHD folks keep posting about. On-device, no streak shaming, one sentence a day, and a recap you can actually re-read when your brain goes blank. Would love your take.` |
| Landing page H1 | — | `Lost traq? Retraq.` |
| Landing page subhead | — | `The on-device memory backup for people who forget their week by Friday.` |

## Testing rules

- The hook MUST pass the 3-second recall test in creator outreach
  (re-shown 3 seconds after reading, the recipient can restate it).
- The hook MUST NOT use: "simple," "powerful," "clinical,"
  "complete," "comprehensive," "ultimate."
- The hook MUST work without the pun (i.e. the one-liner has to land
  even in markets where "Retraq" wordplay doesn't translate — the
  "memory backup + forget their week" frame carries).

## What this hook is NOT

- It is NOT a mood-tracker pitch. Mood is opt-in and off by default;
  leading with mood lands us in the Daylio / Finch pool we're
  flanking.
- It is NOT a journaling app pitch. "Journal" pattern-matches to Day
  One and Apple Journal which own "long-form writing." Retraq is a
  sentence-a-day memory backup.
- It is NOT a caregiver pitch. Caregiver is v2 (Part III) — keep
  that narrative completely out of v1 store surfaces.
- It is NOT an AI pitch. Cloud AI summaries are v2 behind explicit
  consent. The v1 recap is rule-based, on-device, and deterministic.

## Distribution checklist

When this hook changes, update all of:

- [ ] `lib/l10n/app_en.arb` — `appTagline` or equivalent if it
      surfaces in-app.
- [ ] `docs/brand/taglines.md` — primary/secondary table.
- [ ] `docs/store-listing/ios.md` — subtitle + promotional text.
- [ ] `docs/store-listing/android.md` — short + full description.
- [ ] `docs/gtm/positioning-one-pager.md` — "One-sentence hook"
      header block.
- [ ] Landing page (when it ships — blocked on B-17 screenshots +
      B-18 ASO vendor).

## Sibling artifacts

- [`positioning-one-pager.md`](./positioning-one-pager.md) — the
  90-second read this hook is extracted from.
- [`../brand/taglines.md`](../brand/taglines.md) — tagline A/B bank.
