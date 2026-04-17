# Share card visual brief — Hook A (v1.2)

**Status:** Design brief — pending Epic 13 brand designer (B-12) ·
**Task:** 5.9 companion · **Last updated:** 2026-04-16

Companion to `engagement-hook-spec.md`. Hook A is the shareable
"week-in-moods" card deprioritized to v1.2. This brief exists so
the Epic 13 icon/brand designer (B-12) can iterate on the visual
motif in parallel with the Hook B implementation; when the
visual lands, Hook A can ship without re-briefing.

## What the card is

A single image, exported as PNG via the OS share sheet, showing
one week of Retraq activity in a format that's voluntarily
screenshot-able by the user and recognizable as "Retraq" to a
stranger who sees it in their feed.

## Dimensions

| Target | Size | Aspect |
|---|---|---|
| Instagram Story | 1080 × 1920 | 9:16 |
| Instagram Feed | 1080 × 1350 | 4:5 |
| TikTok Story | 1080 × 1920 | 9:16 |
| Generic square (Twitter/X, Discord) | 1080 × 1080 | 1:1 |

The canvas system generates all four from a single layout spec;
the designer produces one template and the engineer adapts it.

## Content — the card MUST have

1. **The week range** — "Week of 6–12 May 2026" or equivalent
   localized format. Uses the user's `weekStartDay` setting.
2. **7 mood blobs across the week** — one per day. Days with
   no mood show a neutral de-emphasized dot. No user-entered
   text.
3. **The tally** — "4 traqs logged" (neutral count), NOT
   "broke your streak" or "missed 3 days."
4. **Retraq logotype + "Lost traq? Retraq."** — bottom-right
   corner. Small enough to not dominate, large enough to read
   in a feed scroll.
5. **The teal mood gradient** — aligns to the mood palette
   (Epic 13 Task 13.2). This is the visual motif that makes
   the card recognizably Retraq vs. Daylio's pie charts.

## Content — the card MUST NOT have

- **No raw entry text** (default). Entry excerpts are an explicit
  per-share opt-in in v1.2+ and even then redacted to ≤ 60 chars.
- **No user-identifying text by default.** No display name, no
  email, no photo, no identifier. Users can opt in to showing
  their chosen first name or initial.
- **No loss framing.** No "3 days missed," no "broken streak,"
  no "catch up tomorrow!" — see `engagement-copy-review.md`.
- **No ads or promotional text.** The Retraq wordmark is the
  only brand reference; no "Try premium!" CTA.
- **No dates with time-of-day.** Week range only; no "Monday
  2:47 PM" style data that reveals granular schedule.
- **No streak number.** If the user has an 80-day streak, the
  card says "4 traqs this week" not "streak: 80 days." Streak
  celebration lives in-app, not on shared surfaces.

## Typography

- Headline: Lexend 600 (matches app body)
- Body: Manrope 500 (matches app labels)
- Wordmark: Retraq brand logotype per `docs/brand/retraq-branding-guide.md`

See Epic 13 Task 13.10 for the Lexend + Manrope pairing rationale
(preserved as-is in that reference entry).

## Colour system

- Background: `#F8FAF8` (surface, light) / `#121412` (surface, dark)
- Mood blobs: teal gradient `#80CBC4` → `#00796B` (Task 13.2
  will retune this — use whatever Task 13.2 lands at the time
  of implementation).
- Text: `#2D3432` on light, `#DDE4E1` on dark.
- Wordmark: `#33694B` primary.

Respect light/dark-mode preference of the generating device so
users who write in dark mode share a dark-mode card.

## Brand motif — the open design question

The Hook B monthly-callback card can ship without a unique motif
because the *content* (the resurfaced memory) is the hook. Hook A
has no such content hook — without a distinctive visual, the card
is just a mood grid and doesn't justify the share.

**Designer brief (Epic 13, B-12):**
> Find the Retraq visual motif that makes this card recognizable
> in a feed without reading the wordmark. The "Q as pin/speech
> bubble" motif (Task 13.1) is the leading candidate — could the
> card use the Q as a frame around the week? Or a progression
> from empty Q to filled Q as the traqs fill in?
>
> Constraint: the motif must work at 1080px square and still read
> at 320px when re-scaled in Twitter timeline. It must be
> distinct from Daylio's mood grid (circle icons on a
> calendar) and from Apple Journal's photo-heavy cards.

## Privacy architecture reminder

Same posture as Task 3.9 plaintext-export warning:

1. Card generation happens fully on-device. Nothing leaves the
   phone.
2. "Share" invokes the OS share sheet. User picks the destination.
3. A confirmation dialog fires before the share sheet if the user
   has opted into any excerpt inclusion, stating that the
   destination app will receive the PNG in readable form.
4. The generated PNG is a temp file deleted after the share
   intent resolves (same lifecycle as current export flow).
5. `no_network_invariant_test.dart` still passes — no new HTTP
   dependency introduced by this feature.

## Implementation notes (for engineering when Hook A activates)

- Use Flutter's `RepaintBoundary` → `boundary.toImage()` →
  `ImageByteFormat.png` pipeline. Same approach as Flutter's
  "golden test" screenshot path so rendering parity is
  well-understood.
- Build the card from `CustomPaint` canvas primitives — do NOT
  embed platform widgets (ScrollView, InkWell) that might render
  differently under `toImage`.
- Cache the generated image for 60 s so a "Share to IG" and
  "Share to Twitter" within the same gesture don't regenerate.
- Honor `reduceMotion` (Epic 7) — any animated card preview in-
  app freezes at the default frame when motion is reduced.

## Sibling artifacts

- [`engagement-hook-spec.md`](./engagement-hook-spec.md)
- [`engagement-copy-review.md`](./engagement-copy-review.md)
- [`../plans/epic-13-brand.md`](../plans/epic-13-brand.md) —
  Tasks 13.1 (icon), 13.2 (mood palette), 13.3 (accent).
- [`../../external-blockers.md`](../../external-blockers.md) —
  B-12 icon designer engagement gates the motif resolution.
