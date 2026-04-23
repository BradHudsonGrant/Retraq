# Retraq tagline + social copy catalogue

**Status:** Ship-ready · **Task:** 13.19 · **Last updated:** 2026-04-16

One-liners, headlines, and social copy catalogued with the situation
they fit. Pulled from the brand guide + agent-13 audit + user memory.

## Primary tagline

> **Lost traq? Retraq.**

- **Use in:** iOS App Store subtitle (30-char slot), iOS widget promo,
  Twitter/X bio, sticker, T-shirt.
- **Why it works:** Self-explains the name via a pun on "lost track"
  + "retrace." Passes the 3-second store-listing test.
- **Avoid when:** explicit health / clinical / medical contexts where
  the wordplay may undermine seriousness. In those contexts default
  to "Your memory backup."

## Secondary taglines

| Tagline | Best use |
|---|---|
| Retrace your days, one traq at a time. | Landing page hero, full description in Play Console |
| Traq the moment. Retraq the memory. | TikTok intro clip overlay |
| Don't lose traq. Retraq. | TikTok sticker, second social CTA |
| Your memory backup. | Non-pun fallback — store description body, medical-adjacent contexts |
| For people who forget Tuesday by Thursday. | Reddit post title, TikTok relatable creator caption |
| Journalling apps want your life story. Retraq just wants a sentence. | Twitter/X thread intro, landing page hero-alt |

## Empty-state microcopy (preserve verbatim)

- `No traqs yet. Drop a traq?`
- `Drop your first traq. Even one word counts.`
- `Nothing here yet. How was your Tuesday?`

Keep the lowercase-pun + warm-question pattern. Translators for future
locales must preserve tone, not just literal meaning.

## Milestone copy (preserve verbatim)

| Milestone | Copy |
|---|---|
| 1 | Your first traq. Nice. |
| 5 | Five traqs in. Keep going. |
| 10 | Ten traqs! You're building a thing. |
| 25 | 25 traqs! Look at you go. |
| 50 | 50 traqs! That's genuinely impressive. |
| 100 | 100 traqs! A proper habit now. |
| 250 | 250 traqs! That's a whole season remembered. |
| 500 | 500 traqs! Half a thousand memories. |
| 1000 | 1000 traqs! You've built something real. |

Above 1000 requires co-authoring with a copy review — must maintain the
warm, non-streak-shaming, anti-Duolingo tone.

## App Store listing copy slots

### iOS

| Slot | Limit | Primary content | A/B variant |
|---|---|---|---|
| Name | 30 | `Retraq — Remember Your Week` | `Retraq — Memory Journal` |
| Subtitle | 30 | `Lost traq? Retraq.` | `Your memory backup.` |
| Keywords | 100 | `journal,diary,memory,mood,daily,log,private,offline,lexend,simple,recap,habit,notes,jot` | — |

### Google Play

| Slot | Limit | Primary content |
|---|---|---|
| Short description | 80 | `Jot down your day in seconds. Never draw a blank when someone asks what you've been up to.` |
| Feature graphic text | — | `Lost traq? Retraq.` overlay on app-screenshot collage |

## Vocabulary enforcement

**Use:** drop a traq · your traqs · week retraqd · retraq it · catch up on traqs

**Avoid** (except in legal / accessibility / privacy copy where clarity wins):
generic "entry", "log", "note", "post".

A grep check in CI can flag these — see `forbidden-claims.md` style
guard.

## Anti-patterns (never use)

- `cures` · `treats` · `diagnoses` · `FDA-approved` · `HIPAA-compliant` ·
  `clinically proven` (Task 12.5 forbidden-claims list).
- `streak` framed as penalty (`lost streak`, `streak reset`).
- `guilt` / `failure` / `oops, you missed a day` framings.
- Clinical-medical vocabulary or health-condition targeting in any
  copy (see `forbidden-claims.md` red-list).

## Where to source creator-outreach DMs

See Epic 5 Task 5.8 — the creator seeding playbook. 20-30 free
Premium codes + a creative brief matching the taglines in this file.

## Where to commit new taglines

Open a PR editing THIS file. Include:
1. The new tagline text.
2. The slot it's intended for (iOS subtitle, TikTok overlay, Reddit
   title, etc.).
3. A rationale — what it's trying to achieve.
4. Any contrasts with existing entries (replacement? supplement?).
