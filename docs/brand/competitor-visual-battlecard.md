# Competitor visual-positioning battlecard

**Status:** Reference · **Task:** 13.18 · **Last updated:** 2026-04-16

Visual + tonal comparison of Retraq against the journaling and
mood-app category's known players. Use this card as reference
for designers reviewing mockups, marketing picking screenshot
overlays, and future competitor-analysis refreshes.

**Companion to** the Epic 5 GTM battlecards (`../gtm/battlecards/`)
which handle positioning + pricing + acquisition scenarios.
This doc is the **visual** half of the same competitive picture.

## The competitors

### Day One

- **Icon + wordmark:** Inkwell-adjacent serif "1" or a
  stylized notepad. Premium-skewed visual weight.
- **Primary palette:** Deep blue (`#3B80D6`-ish) + off-white.
- **Photography:** Heavy. Day One is photo-first in marketing
  screenshots; the app's social proof leans on "your photos
  next to your entry."
- **Typography:** Serif body for entries (feels diary-like).
- **Voice:** Literary, contemplative. "Your life's story, one
  entry at a time."
- **Market position:** Premium journaling. $34.99/yr Plus,
  $74.99/yr Gold.

### Daylio

- **Icon + wordmark:** Orange mood-emoji face inside a rounded
  square. Instantly recognizable.
- **Primary palette:** Warm orange `#F78B45`-ish + white +
  multi-color mood grid.
- **Photography:** None meaningful; UI is icon-driven.
- **Typography:** Sans-serif, friendly, system fonts.
- **Voice:** Gamified, direct. "Track your mood and activities
  in under 30 seconds."
- **Market position:** Mood-micro-entry king. 20M+ installs,
  $2.99/mo Premium.

### Journey

- **Icon + wordmark:** Earth-pin icon suggesting "journey"
  + travel metaphor.
- **Primary palette:** Blue-green `#2E86B0` + teal.
- **Photography:** Moderate; travel-journal vibe.
- **Typography:** Sans-serif, slightly formal.
- **Voice:** Neutral, feature-forward. "Multi-platform
  journaling app."
- **Market position:** Cross-platform journaling. Solid middle
  tier.

### Finch

- **Icon + wordmark:** Cute chick character in soft pink on
  purple gradient.
- **Primary palette:** Pink `#F19FCB` + lavender + pastel
  accents.
- **Photography:** None — character-driven UI.
- **Typography:** Rounded sans-serif, cartoon-adjacent.
- **Voice:** Sweet, parasocial. "Help your self-care pet grow
  by taking care of yourself."
- **Market position:** Gamified self-care. Heavy on streak +
  pet-care mechanics. $29.99/yr Premium.

### How We Feel

- **Icon + wordmark:** Abstract wave / feeling-chart mark.
- **Primary palette:** Teal `#00A8A4`-ish + neutral.
- **Photography:** Minimal.
- **Typography:** Modern sans-serif, spacious.
- **Voice:** Emotion-literacy-focused. "Name your feelings
  with precision."
- **Market position:** Free nonprofit. Granular emotion
  vocabulary. Closest comp to Retraq's on-device posture.

### Apple Journal

- **Icon + wordmark:** Apple's minimalist notebook-page icon,
  iOS system tone.
- **Primary palette:** Apple system blue + system white/black.
- **Photography:** Heavy — Apple Intelligence suggests photos
  + moments.
- **Typography:** SF Pro / San Francisco system fonts.
- **Voice:** Apple-neutral. "Reflect on your day."
- **Market position:** iOS-bundled free. Default-trust
  journaling on iPhone.

### Reflectly

- **Icon + wordmark:** Purple-pink gradient starburst /
  reflection mark.
- **Primary palette:** Purple `#5B2D86` + pink accent.
- **Photography:** Moderate.
- **Typography:** Sans-serif, modern.
- **Voice:** Self-help-adjacent. "Your personal AI-driven
  journal for self-care."
- **Market position:** AI-guided, subscription-heavy. Once
  popular on ADHDTok; losing ground to Rosebud.

### Moodnotes

- **Icon + wordmark:** Three-dot speech-bubble mood icon.
- **Primary palette:** Yellow-orange `#F4B65A`-ish + warm
  neutrals.
- **Photography:** None.
- **Typography:** Sans-serif, warm.
- **Voice:** Clinical-adjacent (CBT background). "Capture
  and analyze your mood with CBT techniques."
- **Market position:** Paid premium, CBT-leaning.

### Rosebud

- **Icon + wordmark:** Rose-bud outline in teal or dark green.
- **Primary palette:** Deep teal `#1F4940`-ish + warm white
  + rose-pink accent.
- **Photography:** None — chat-driven.
- **Typography:** Modern sans-serif, conversational-friendly.
- **Voice:** AI-coach framing. "Your AI-guided journal for
  self-reflection."
- **Market position:** AI-conversation journal, $8.99/mo.
  See `../gtm/battlecards/rosebud-mindsera.md`.

### Retraq (v1)

- **Icon + wordmark:** Q-as-pin/speech-bubble motif (pending
  Task 13.1 designer polish — B-12 blocker).
- **Primary palette:** Forest green `#33694B` + mint
  `#B5F0C9` + off-white `#F8FAF8` + teal mood gradient
  `#80CBC4 → #00796B`.
- **Photography:** Explicitly minimal. Shareable moments come
  from Hook B callback card (see `../gtm/engagement-hook-spec.md`)
  which uses mood blobs + text, NOT photos.
- **Typography:** Lexend (body, research-backed for cognitive
  accessibility) + Manrope (labels, geometric clarity).
  Locked per Task 13.10.
- **Voice:** ADHD-adjacent warm-casual. "Drop a traq." "Lost
  traq? Retraq." "For people who forget Tuesday by Thursday."
- **Market position:** Free-forever core journal, one-time
  \$5.99 Pro Lifetime OR \$2.99/mo Pro Cloud AI (v1.1).
  On-device-only (load-bearing).

## Positioning chart

Two-axis plot:
- **X: minimalist ↔ gamified** (how much the UI leans on
  game mechanics / pet care / streak theatrics)
- **Y: clinical ↔ playful** (how the tone positions:
  therapeutic / clinical / neutral / warm / playful)

```
 PLAYFUL
    ^
    |                            FINCH (pink/pet/purple)
    |                                  ·
    |                                              DAYLIO (orange/mood)
    |                                                   ·
    |                         RETRAQ v1 (green/teal)
    |                                      ·
    |                   APPLE JOURNAL (blue/system)          REFLECTLY
    |                           ·                            (purple/AI)
    |                                                            ·
    |
    |     HOW WE FEEL (teal/emotion)     JOURNEY
    |              ·                    (blue-green)
    |                                       ·
    |
    |     DAY ONE (blue/serif)                   MOODNOTES (yellow/CBT)
    |            ·                                     ·
    |                                           ROSEBUD (teal/AI-coach)
    |                                                  ·
    v
  CLINICAL
        <---- MINIMALIST                     GAMIFIED ---->
```

**Where Retraq sits:**

- **Minimalist + playful quadrant**, close to Apple Journal
  (minimalist + neutral-leaning-playful) and Daylio
  (slightly-more-gamified + playful).
- **Visually distinct from Apple Journal** because the teal
  mood gradient + green primary + the Q motif don't read as
  "system blue," so in-feed screenshots are recognizable as
  Retraq before you read the wordmark.
- **Tonally distinct from Daylio** because Retraq's voice
  (ADHD-adjacent, "drop a traq") is specific where Daylio's
  is broad.
- **Distinct from Finch / Rosebud** on the gamification +
  AI-as-companion axes — Retraq explicitly isn't either
  (see `../gtm/engagement-hook-spec.md` no-pet-mechanics
  constraint + `../gtm/battlecards/rosebud-mindsera.md`
  no-AI-as-coach rule).

## How Retraq's visual stays recognizable

Three cues that make a Retraq screenshot identifiable in a feed
WITHOUT reading the wordmark:

1. **Teal mood gradient progression** — the 5-blob mood row
   (light teal → deep teal) is the most distinctive
   color-signature element.
2. **Forest-green primary on off-white background** — warmer
   than Apple Journal's system blue, greener than Finch's
   purple-pink, deeper than How We Feel's cool teal.
3. **Q-as-frame motif (pending B-12)** — when the icon
   designer lands the Q-as-pin variant, it becomes the third
   unmistakable cue. Until then the wordmark carries this
   job.

## What to avoid in visual positioning

- **Don't converge on Apple Journal's system blue.** iOS
  users pattern-match that palette to Apple's bundle.
- **Don't adopt Daylio's orange.** It's the most-trafficked
  color in the mood-app category; copying invites
  "another Daylio" comparison.
- **Don't use pink-pastel palettes.** Finch owns that space;
  even adjacent palettes read as "cute self-care app"
  which conflicts with Retraq's ADHD-adult positioning.
- **Don't adopt serif typography.** Day One owns "literary
  journaling"; Retraq's voice is warm-conversational, not
  literary.
- **Don't lean on photography in screenshots.** Day One +
  Apple Journal own photo-first journaling. Retraq's
  screenshots lead with the Recap tab (text + mood +
  recall) per `../gtm/privacy-narrative.md`.

## Sibling artifacts

- [`../gtm/battlecards/`](../gtm/battlecards/) — positioning
  + acquisition + pricing battlecards (Daylio, Apple Journal,
  Inflow, Rosebud/Mindsera, Quick Journal)
- [`../gtm/positioning-one-pager.md`](../gtm/positioning-one-pager.md)
  — the narrative positioning this visual card supports
- [`../gtm/privacy-narrative.md`](../gtm/privacy-narrative.md)
  — screenshot set requirements
- [`../gtm/engagement-hook-spec.md`](../gtm/engagement-hook-spec.md)
  — Hook A / B / C; Hook A's share card visual brief is the
  direct consumer of this battlecard
- [`retraq-branding-guide.md`](./retraq-branding-guide.md) —
  canonical brand (palette + typography + logo rules)
- [`sub-brand-decision-tree.md`](./sub-brand-decision-tree.md)
  — where the v2 caregiver visual divergence is scoped
- [`../plans/epic-13-brand.md`](../plans/epic-13-brand.md) —
  Task 13.18 source
