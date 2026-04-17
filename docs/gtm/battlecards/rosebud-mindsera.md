# Rosebud + Mindsera battlecard — "we are not this"

**Status:** Ship-ready · **Task:** 5.10 · **Last updated:** 2026-04-16

> **TL;DR:** Rosebud ($8.99/mo) and Mindsera ($129/yr) are AI-
> conversation journaling apps targeting AI power users. Retraq is
> a memory-backup journal that *uses* AI for summary, not
> conversation. **Do NOT try to out-AI them.** Position as
> different category.

Pair with the AI non-claims list (`../ai-non-claims.md`) and the
anti-clinical writing rules from the positioning one-pager.
Retraq's cloud AI tier is v1.1 / opt-in / summary-only; it ships
behind consent gates (Task 12.4 Art. 9, Task 12.13 AI Act).

## The competitors at a glance

| Field | Rosebud | Mindsera |
|---|---|---|
| Install base | 1M+ | <500K |
| Price | $8.99/mo or $89/yr | $12.99/mo or $129/yr |
| Core pitch | "AI-guided journaling" / "your AI thought partner" | "Premium AI journaling with Socratic questioning" |
| AI model | OpenAI (GPT-4 tier) | Multi-model (OpenAI + Anthropic) |
| Cloud sync | Required | Required |
| Moat | AI-conversation UX familiarity + prompt library |

## Strengths — do not try to out-compete on these

- **AI-conversation quality.** Both apps call OpenAI / Anthropic at
  the frontier tier. We can't out-model them at any price (and
  shouldn't try — see cost argument below).
- **AI power-user familiarity.** Their users arrived *because* they
  wanted AI journaling. Trying to win those users means
  commoditizing to them.
- **Prompt libraries.** Years of curated question bank for AI-
  guided reflection. Deep content moat.

## Why "out-AI them" fails before it starts

- **Cost:** Rosebud at $8.99/mo is breakeven at scale because
  frontier LLM calls are their largest variable cost. Retraq's
  promised v1.1 AI tier at ~$2-3/mo (Tier 3 cloud AI per
  `implementation_plan.md`) would be unprofitable at conversation
  volume.
- **Moat:** Rosebud has 2+ years of prompt-library iteration. We'd
  be shipping a v1 AI surface against their v7.
- **Positioning:** "Another AI journal" is the most commoditized
  frame we could adopt. The entire 2024-2026 wave of journaling
  apps converged on it.
- **Privacy:** Rosebud / Mindsera users *want* cloud AI, so they've
  accepted cloud sync + LLM calls. Retraq's privacy wedge (Task 5.4)
  is meaningless to them.

## The wedge — different category

The one-line answer to "why not just use Rosebud?":

> "Rosebud is your AI thought partner. Retraq is your memory backup.
> Rosebud uses AI as the reason to open the app — the conversation
> IS the product. Retraq uses AI (in v1.1, opt-in) to summarize a
> week you wrote yourself. The journal is the product; AI is a
> filter on top."

## Retraq's AI posture — v1.1

**Default:** The free tier is fully on-device, no cloud AI, no
conversation interface. Ever.

**Opt-in paid tier (v1.1):** Your weekly recap gets a cloud-AI
summary layer. The summary is a paragraph synthesizing your week
from the entries you already wrote. It's NOT:

- An AI chat interface.
- A Socratic question-asking experience.
- A CBT or therapy aid.
- A replacement for the on-device rule-based recap (which stays
  and is the default — the AI summary is additive).

See `../ai-tier-messaging.md` for the exact copy framing.

## When Retraq wins — two scenarios

### Scenario A — "I want to journal without the AI gimmick"

- User has tried Rosebud, found the AI conversation distracting,
  just wants to write and be left alone.
- **Creator DM copy:** "Retraq doesn't ask you questions. It
  doesn't follow up. It doesn't try to be your therapist. It's
  a journal that shows you last week when you open it."

### Scenario B — "I like AI summaries but Rosebud's price is too much"

- User wants the summarized-week feature but balks at $8.99+/mo
  for a cloud-dependent product.
- **Creator DM copy (post v1.1 ship):** "Retraq Pro includes
  weekly AI summaries at a fraction of Rosebud's price, and the
  base journal stays on-device and free. AI is the icing, not
  the cake."

## Objection handling

### "Retraq's AI is worse than Rosebud's"

> Almost certainly, if you mean conversation quality. But we're not
> trying to be a conversation app. Retraq's AI does one thing —
> summarize a week you already wrote into a paragraph worth re-
> reading. Different tool, different price.

### "Why not just use Rosebud + an on-device journal?"

> You can. Retraq doesn't need to be a full replacement — plenty of
> users keep Rosebud for thought partnership and Retraq for the
> memory backup because the jobs are different.

### "Is Retraq's AI private?"

> Free tier: fully on-device, never calls out. Paid cloud-AI tier
> (v1.1): covered by explicit opt-in consent, Art. 9 disclosure
> (because week summaries can incidentally reveal health
> information), and a zero-retention provider contract. You can
> turn it off and the app falls back to the on-device rule-based
> recap.

## What creators / the team should NOT do

- Do NOT claim Retraq's AI summaries are "better" than Rosebud's
  conversations. Different category.
- Do NOT lead any store-listing copy or ad with "AI-powered." Lead
  with memory / recap / recall — AI is an implementation detail,
  not a feature category.
- Do NOT make therapy claims on the AI tier. No "AI coach," no "AI
  therapist," no "AI CBT guide" (see sibling `ai-non-claims.md`).
- Do NOT position Retraq as "the affordable Rosebud." That's
  accepting Rosebud's frame.

## Sibling artifacts

- [`../positioning-one-pager.md`](../positioning-one-pager.md) —
  'no clinical language' writing rules.
- [`../privacy-narrative.md`](../privacy-narrative.md) — the
  privacy wedge Rosebud/Mindsera users don't care about but every
  other target does.
- [`../ai-non-claims.md`](../ai-non-claims.md) — explicit list of
  AI claims Retraq will not make.
- [`../../../memory/project_ai_recap_plan.md`](../../../memory/project_ai_recap_plan.md)
  — the internal AI feature plan (template for free, Gemini Nano
  on Pixel for free, cloud AI for premium).

## Follow-up artifacts to generate

One companion doc Task 5.10 also asks for, to ship in a follow-up
commit when AI-tier copy is being actively wordsmithed:

- `../ai-tier-messaging.md` — the 'your week, summarized' vs 'ask
  AI about your day' framing for the v1.1 paywall page.
