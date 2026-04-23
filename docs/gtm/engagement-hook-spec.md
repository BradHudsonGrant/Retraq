# Engagement hook spec — lightweight pull without streak shame

**Status:** Ship-ready (v1.1 spec) · **Task:** 5.9 · **Last updated:** 2026-04-16

> **Problem:** Finch (pet care) and Stoic (daily quote) own
> journaling-creator share moments. Retraq has no equivalent. But
> Retraq must NOT add streak-penalty mechanics — "streak shame" is
> a common top-of-thread app-review complaint ("why I deleted
> Finch").
>
> **Solution:** three candidate hooks, all share-able, none
> loss-framed. One ships in v1.1 — the monthly retraq callback is
> the recommendation. The other two stay in the backlog.

## The sweet spot

Lightweight engagement works when:

1. **The hook is voluntary** — user chooses to engage, app never
   demands it.
2. **The surface is dopaminergic but not parasocial** — a small
   surprise, a callback, a shareable moment. NOT a pet that's
   sad when you forget it.
3. **The framing is encouragement, not loss** — "you logged 4
   days this week, nice" NOT "you broke your streak."
4. **The artifact is screenshot-ready** — if there's nothing
   visually worth posting, no social lift.
5. **Privacy stays intact** — shareable doesn't mean exposing
   entry text by default.

## Three candidate hooks

### Hook A — Shareable "week-in-moods" card

**What it is:** On Sunday night (or user-chosen day), Recap tab
surfaces a small card summarizing the week as 7 mood blobs across
the week, streak status (warm wording, no loss frame), and a
tally of traqs logged. A "Share" affordance exports the card as
a PNG.

**Visual:** 1080×1920 for Instagram Story, 1080×1350 for feed.
Blob emojis + week dates + Retraq logotype. Optional user
initial / display name (default off).

**What leaves the device:** The PNG file, via the OS share
sheet. Same pattern as Task 3.9 plaintext-export warning —
user-initiated, app never opens a socket. No raw entry text
unless user explicitly includes it (opt-in, v1.2).

**Engineering cost estimate:** M. Requires a new `ShareCardBuilder`
using Flutter's `RepaintBoundary` → PNG pipeline, a visual
template, and a share-sheet invocation. Re-uses `ExportService`
sharing plumbing.

**Penalty-free copy:**
- Good: "You logged 4 days this week. Thanks for showing up."
- Good: "Your week, in moods."
- BAD: "3 days missed — don't let your streak slip!"
- BAD: "Keep your flame alive."

**Risk:** Without a unique visual angle this is just Daylio's
mood grid. The card needs a distinctive Retraq motif (the Q?
the teal blob progression?) to be screenshot-worthy.

### Hook B — Monthly retraq "you wouldn't have remembered this"

**What it is:** Once per month, the app surfaces a card with 1–3
entries from 30+ days ago that scored high on recency salience
(user wrote something specific, used mood, marked as a memorable
moment). The framing: "You wouldn't have remembered this. Retraq
did."

**Visual:** A compact card on Home or Recap — like the "on this
day last year" recurrence but scoped to 30-day callback. Share
affordance exports a stylized card with the date and a short
excerpt (user opts in to include excerpt per share; default
redacts to date + mood).

**What leaves the device:** PNG via share sheet. Excerpt inclusion
is explicit opt-in per share — not per-session.

**Engineering cost estimate:** S–M. Re-uses existing
`getEntriesForDate` + `watchEntriesForDate` paths. Needs a light
"salience score" (e.g. entry length + has-mood + has-title) —
deterministic, on-device, no ML.

**Penalty-free copy:**
- Good: "A month ago today: you wrote about your first day back
  at yoga. Retraq kept it."
- Good: "You wouldn't have remembered this — that's what Retraq
  is for."
- BAD: "See? You should journal every day or you'll forget."

**Why this is the recommendation:**
- Lowest engineering cost of the three.
- Highest share-intent — the "wouldn't have remembered this"
  framing is the positioning-one-pager hook made visible.
- Deepest category differentiation — Daylio / Apple Journal / Finch
  do NOT do callback-to-the-past-you surfaces.
- Built-in virality via screenshots users want to post
  ("look what Retraq reminded me of today").
- Reinforces the memory-backup narrative at every monthly touchpoint.

### Hook C — Random past-entry surprise on app open

**What it is:** Occasionally (1-in-20 opens? Pseudo-random weekly?)
the app's Home header shows "A moment from [date]" with a random
past entry preview. Dismissable. No rhythm — user can't "earn"
or "lose" it.

**Visual:** Inline Home surface, small banner. No share affordance
in v1 (can evolve in v1.2).

**What leaves the device:** Nothing. In-app only.

**Engineering cost estimate:** S. A `RandomPastEntryProvider`
that picks one entry within a date range on app open via a
deterministic seed (so multiple opens same day show same
entry).

**Penalty-free copy:**
- Good: "A moment from 23 April 2026 — remember this?"
- Good: "From your archive."
- BAD: "See what you forgot."

**Why NOT v1.1 priority:**
- Lowest share intent — no export affordance.
- Could feel invasive on the Home surface that's already being
  honed for the v1 memory-backup Home composition.
- Backlog for v1.2+ once Hook B engagement data is in.

## Recommendation — ship Hook B in v1.1

Priorities:

1. **Hook B — Monthly callback** ships with v1.1 (coordinated with
   the cloud AI summary rollout, which is also a monthly Recap
   touchpoint).
2. **Hook A — Share card** slotted for v1.2, deprioritized unless
   a visual-identity breakthrough (custom Q-motif in the card?)
   lands during Epic 13 brand work.
3. **Hook C — Random callback** deferred to v1.2 backlog.

## What this spec does NOT allow

Hard constraints any implementation must honor:

- **No loss framing.** Copy review (see
  `engagement-copy-review.md`) must approve every string.
- **No pet mechanics.** No virtual character that's "sad" when
  you miss days. No gamification that implies neglect cost.
- **No penalty notifications.** Nudges (Task 2.14) already skip
  when the user journaled; callbacks don't fire retaliatorily.
- **No outbound network calls.** Hooks use on-device data only.
  Share-sheet is the only path to the outside world and always
  user-initiated.
- **No raw entry text in default shares.** Date + mood + optional
  one-word summary at most; longer excerpts only on explicit
  per-share opt-in.
- **Respect reduce-motion / accessibility.** Any animated
  celebration on the callback card must honor the Epic 7
  `AppMotion.reduce(context)` contract.

## Success metrics (post-v1.1 landing)

Measured via Epic 11 anonymized opt-in export — default OFF, user
opts in via "Help improve Retraq":

- Monthly callback card **view rate**: % of active users who see
  the card at least once per month. Target ≥ 80%.
- **Share rate**: % of users who tap Share within 7 days of seeing
  the card. Target ≥ 3% (category benchmark is 1-2% for
  share-centered UX).
- **Share re-view**: does a shared card correlate with re-open
  within 14 days? Measured via cohort in local `app_sessions`
  table (Task 11.2).
- **Retention lift**: D28 retention for users who saw vs didn't
  see the callback. Target ≥ 5% lift for seen cohort.
- **Negative signal monitor**: Settings → Data → "Keep usage
  stats" kill switch (Task 11.13) toggle-off rate after callback
  landings. If this spikes, users are perceiving the callback as
  intrusive and the hook needs rework.

## Sibling artifacts

- [`share-card-visual-brief.md`](./share-card-visual-brief.md)
  — Hook A's visual spec (written in the same commit; kept
  separate so Epic 13 brand designer can iterate without
  touching the product spec).
- [`engagement-copy-review.md`](./engagement-copy-review.md)
  — Hook B + future copy audit checklist (same commit).
- [`../positioning-one-pager.md`](../positioning-one-pager.md)
  — 'anti-streak-shaming' proof point.
- [`battlecards/quick-journal.md`](./battlecards/quick-journal.md)
  — 'don't compete on speed' guidance.
- [`../../plans/epic-11-analytics.md`](../../plans/epic-11-analytics.md)
  — Task 11.2 sessions table, 11.13 kill switch.
- [`../../memory/project_feature_decisions.md`](../../memory/project_feature_decisions.md)
  — smart-nudges decision that informs callback cadence.
