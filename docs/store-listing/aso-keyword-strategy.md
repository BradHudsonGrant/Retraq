# ASO Keyword Strategy — Retraq

**Status:** Draft · **Task:** 9.3 · **Last updated:** 2026-04-16

> **Caveat:** exact search-volume data requires a paid ASO tool
> (MobileAction, AppTweak, Sensor Tower, App Radar). This document
> reflects the *strategy* and rank-competition estimates; numerical
> refinement belongs in external blocker **B-18**. I've noted where
> data fidelity matters most.

## Targets at a glance

iOS keyword field is a single 100-char comma-separated string.
Play Console has a long-description that is indexed but no explicit
keyword field.

### iOS 100-char keyword field (committed for v1)

```
adhd,journal,diary,memory,mood,daily,log,private,offline,lexend,simple,recap,habit,notes,brain
```

That's 95 chars including separators — 5 chars of headroom for a
future tuning pass.

## Research strategy

Keywords are scored on three axes:

1. **Search volume** — how many users type the term per day/month.
   (True data via B-18 tool.)
2. **Competition** — how many apps already rank for it. Head terms
   like "journal" compete with Daylio (20M+ installs) and Day One —
   unwinnable for an indie launch.
3. **Relevance / intent match** — does a searcher for this term
   actually want Retraq? "journal" yes; "brain training game" no.

Best picks: **high intent × moderate competition × non-trivial volume**.

## Keyword table

Head = high volume, unwinnable short-term
Mid = moderate volume, winnable with good ranking signal
Long = low volume, exact-intent, winnable immediately

| Keyword | Type | Volume (est.) | Competition | Intent | Action |
|---|---|---|---|---|---|
| adhd | Head | High | High (Inflow, Finch, Stoic) | Very High for target | Included; lead with it |
| adhd journal | Mid | Med | Med | Exact match | Not in 100-char (comma-split), but covered by "adhd" + "journal" tokens — App Store tokenizes |
| adhd app | Mid | Med | High | Med (search intent may be tracker, therapy) | Not included; too broad |
| journal | Head | Very High | Very High (Day One, Daylio) | Med (generic) | Included as fallback |
| diary | Head | High | High (Daylio) | Med | Included |
| memory journal | Long | Low | Low | Very High | Split: "memory" + "journal" |
| memory | Mid | Med | Med | Variable (memory games dominate) | Included with risk |
| mood tracker | Mid | High | High (Daylio) | High for mood users | "mood" token included |
| mood | Head | High | Very High | High | Included |
| daily | Head | High | Very High | Low direct intent | Included (indexed combos) |
| daily journal | Long | Med | Med | Very High | Covered by combo tokens |
| daily log | Long | Low | Low | High | "log" included |
| private journal | Long | Low | Low | Very High | "private" included |
| offline journal | Long | Low | Low | Very High | "offline" included |
| simple journal | Long | Low | Low | High | "simple" included |
| recap | Long | Low | Low | Med (brand-sense only) | Included as brand-term reinforcement |
| habit tracker | Mid | High | High | Med | "habit" included; not head-on competing |
| notes app | Head | Very High | Unwinnable (Apple Notes, Google Keep) | Low | "notes" included only as combo support |
| brain dump | Long | Low | Low | Very High | "brain" included |
| lexend | Long | Very Low | Very Low (no other app name-drops) | Very High for reading-font searchers | Included as brand differentiator |
| adhd diary | Long | Low | Low | Exact match | Covered by combo tokens |
| dementia | n/a | n/a | n/a | Off-limits (health-claim risk) | NOT included |
| alzheimer | n/a | n/a | n/a | Off-limits | NOT included |
| therapy | n/a | n/a | n/a | Off-limits (not a clinical tool) | NOT included |
| depression | n/a | n/a | n/a | Off-limits | NOT included |
| anxiety | n/a | n/a | n/a | Off-limits | NOT included |
| tracker | Mid | High | Very High (mega-generic) | Low for journal intent | NOT included (dilution) |
| AI | Head | Very High | Very High | Off-topic for v1 (no cloud AI yet) | NOT included until v1.1 |

### Why "lexend"?

The one keyword almost no competitor uses. Lexend is a Google-built
font researched for reading fluency. Users who search "lexend" are
either font-aware designers (niche but genuine) or ADHD users who've
heard about Lexend from a therapist/OT. Every such searcher is a
near-perfect match for Retraq. Zero competition and ~0 install cost
for the keyword slot.

### Why NOT "adhd app" or "therapy"?

These are high-intent terms for clinical apps. Retraq's tagline
"not a medical device" and the brand's anti-obligation voice are
actively incompatible with the search intent. A user searching
"therapy" is looking for Talkspace or BetterHelp — they'll install
Retraq, be disappointed, uninstall, and leave a 1-star review.

## Competitor keyword posture (manual snapshot)

Based on App Store listings viewed 2026-04-16:

| Competitor | Subtitle / keyword posture | Gap for Retraq |
|---|---|---|
| Daylio | "Micro Diary · Mood Tracker" | Owns "mood tracker" head. Gap: ADHD-specific, Lexend |
| Day One | "Journal · Diary · Notes" | Owns "journal" head. Gap: ADHD, private-offline explicitness |
| Journey | "Diary, Journal" | Similar to Day One but less saturated |
| Reflectly | "AI Journal" | Owns "AI journal" combo. Gap: non-AI / offline-first |
| Finch | "Self-Care Pet" | Different category (gamified wellness). Not a keyword competitor |
| Stoic | "Journal, Guided, Habits" | Owns "stoic" + "philosophy" niche. Gap: ADHD |
| How We Feel | "Mood Journal" | Owns "emotion" terminology. Gap: ADHD-specific workflow |
| Apple Journal | Default iOS | Unwinnable on "journal" within iOS; compete on offline-only |
| Rosebud | "AI Journal" | Overlaps with Reflectly. Gap: free tier |
| Mindsera | "Guided Journal" | Premium positioning. Gap: entry-level price |

## Long-description indexing (Play Console)

Play Console indexes the full description (not just a keyword field).
The current listing body already seeds: adhd, memory, journal, mood,
private, offline, recap, tracker, notes, brain. Tune by adding one
mention per target head-term every 300 chars or so, without keyword-
stuffing (Play has spam detection for that).

## iTunes Search Ads follow-up (v1.1+)

After launch, monitor which keywords actually convert installs via
App Store Connect analytics. Keywords that drive installs should
move up the pecking order in the 100-char field. Keywords with zero
conversion should be dropped in favour of winnable long-tail ones.

If a paid ASO tool is set up (B-18), re-run this analysis quarterly
with live data and adjust the 100-char field per release.

## Next steps

1. Commit this strategy to `app/docs/store-listing/aso-keyword-strategy.md` ✓
2. B-18 — subscribe (trial) to MobileAction or AppTweak to get real
   volume data.
3. Run a real-data refinement pass pre-submission — swap any keyword
   that shows < 10 monthly searches for a higher-volume alternative
   that passes the competition × intent test.
4. Keyword-field A/B after launch (Apple supports A/B tests on
   product pages, not the keyword field directly — but you can ship
   a minor version bump with different keywords to test).

## See also

- `app/docs/store-listing/ios.md` — full iOS listing copy
- `app/docs/store-listing/android.md` — Play listing copy
- `app/docs/external-blockers.md#b-18` — ASO tool subscription
- `app/docs/plans/epic-09-app-store.md#task-9-3` — source task
