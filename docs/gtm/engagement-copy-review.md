# Engagement copy review — no-loss-framing checklist

**Status:** Ship-ready · **Task:** 5.9 companion · **Last updated:** 2026-04-16

A per-string review checklist any engagement-adjacent copy in the
app or marketing surfaces has to pass. "Streak shame" is a common
app-review complaint; Retraq's anti-penalty posture is a
positioning claim (one of the three proof points in the
positioning one-pager) so slipping loss-framed language into
the product or listings undermines the wedge.

Pair with `engagement-hook-spec.md` (Hook B is the primary
consumer) and `ai-non-claims.md` (the AI-tier equivalent
blocklist).

## The test

Before any engagement-adjacent string ships — in-app copy,
notification body, share-card text, store-listing blurb, ad
variant — it must pass all five checks:

1. **Encouragement, not loss.** Does the string frame the user's
   *doing* of journaling as a positive they're adding, not a
   streak/metric they're protecting? If it implies consequence
   for not journaling, fail.
2. **Present-tense, user as subject.** "You logged 4 days this
   week" passes. "You've only logged 4 days this week" fails
   (the "only" implies fewer than expected).
3. **No verbs of obligation.** "Should," "need to," "must,"
   "have to," "don't forget to," "keep your," "maintain your"
   all fail.
4. **No metric-protection framing.** "Streak," "flame," "combo,"
   "chain," "record" as standalone achievements that can be
   lost. A freeze-equipped streak displayed in-app is fine; a
   notification warning it's about to break is not.
5. **Tone-match brand voice.** Warm, not clinical; conversational,
   not corporate; specific, not generic. See
   [`../brand/retraq-branding-guide.md`](../brand/retraq-branding-guide.md).

## Examples — pass

- "You logged 4 days this week."
- "A moment from 23 April 2026 — remember this?"
- "You wouldn't have remembered this. Retraq did."
- "Your week, in moods."
- "Thanks for showing up today."
- "Want to add a moment?"
- "A month ago today."
- "You've been at this for 12 weeks — real habit now."

## Examples — fail

| Copy | Why it fails |
|---|---|
| "Don't break your streak!" | Loss framing, obligation verb. |
| "You're 2 days away from losing your flame." | Loss framing, metric protection. |
| "Come back — we miss you." | Parasocial / obligation. |
| "You've missed 3 days this week." | "Missed" implies owed. |
| "Stay consistent or start over." | Loss framing. |
| "Keep your streak alive!" | Loss framing, obligation verb. |
| "Last chance to log today!" | Loss framing, urgency manipulation. |
| "Your consistency score dropped." | Metric protection. |
| "You haven't journaled in 7 days 😔" | Emoji sad-face + temporal implicit accusation. |
| "Protect your 30-day streak." | Literally asking the user to protect a metric. |

## Edge cases — allowed with care

- **Streak display in-app, Stats tab.** Showing the current streak
  number is fine if the surface is user-initiated (user taps Stats)
  and the copy is neutral ("4-day streak") not urgent ("4-day streak
  — keep it up!"). Celebratory framing at milestones (5, 10, 25,
  50, 100) is fine per `docs/brand/taglines.md` milestone table.

- **Freeze-available status.** If the streak uses the freeze (Task
  8.7's 7-day window allowance), surfacing "Freeze used — streak
  still going" is fine because it's reassurance, not accusation.

- **Review prompt timing.** Asking for an App Store review at
  entry #5 is fine (see `ReviewService` — tied to Task 4.8) because
  the framing is "enjoying Retraq? A quick review helps" not
  "rate us to unlock something."

- **Milestone celebrations.** "100 traqs! A proper habit now." is
  fine. "100 traqs! Don't stop now!" is not — the second half
  flips the frame.

## Surfaces this review applies to

- In-app strings in `lib/l10n/app_en.arb` and siblings.
- Notification bodies emitted by `NotificationService`.
- Monthly callback card copy (Hook B).
- Share card text (Hook A, v1.2).
- App Store / Play Store listing bodies + subtitle.
- Landing page engagement-oriented sections.
- Email sequences, if any ship (not in v1 — see Task 5.8
  creator seeding for the only user-facing outreach).
- Any push-notification variant in a future experiment.

## Surfaces this review does NOT apply to

- Technical error messages (stay technical and clear).
- Settings descriptions ("Enable biometric unlock" stays neutral).
- Legal copy (privacy policy, ToS — that has its own voice rules
  per Task 12.2 / 12.6).
- ARB `@description` metadata for translators (internal-facing).

## How to invoke this review

When submitting a PR that adds or modifies engagement-adjacent
copy, include a line in the PR description:

> **Engagement copy review:** Passed — [note any edge-case strings
> that got extra scrutiny].

If any string fails the test, the PR author proposes a rewrite
that passes all five checks. Legal / brand review (Epic 12 / 13)
can override in rare cases but the default is: rewrite.

## Sibling artifacts

- [`engagement-hook-spec.md`](./engagement-hook-spec.md)
- [`share-card-visual-brief.md`](./share-card-visual-brief.md)
- [`ai-non-claims.md`](./ai-non-claims.md) — adjacent blocklist
  for AI-tier copy (distinct from engagement copy but same
  spirit).
- [`../brand/taglines.md`](../brand/taglines.md) — milestone copy
  bank (all pre-approved per this checklist).
- [`../brand/retraq-branding-guide.md`](../brand/retraq-branding-guide.md)
  — brand voice rules.
