# Privacy Impact Assessment — Cloud AI recap tier, Quebec Law 25

**Status:** Template — must be completed + counsel-reviewed
before Tier 3 cloud AI ships to Quebec users ·
**Task:** 12.13 companion · **Last updated:** 2026-04-16

Quebec's *Act respecting the protection of personal information
in the private sector* (Law 25, effective September 2023)
requires a Privacy Impact Assessment (PIA) before any
communication of personal information outside Quebec.
Retraq's Tier 3 cloud AI recap sends journal entries to a
non-Quebec LLM provider — that triggers the PIA requirement.

This document is the **template**. Complete the bracketed
sections at Tier 3 engineering freeze, then have it reviewed
by privacy counsel before the feature ships to any `fr_CA`
Quebec user. The v1 app explicitly does NOT send data outside
Quebec; this PIA only activates for the v1.1 cloud AI tier.

## 1. Identify the activity

**Activity:** Retraq Tier 3 weekly recap generation via cloud
LLM.

**Trigger:** User on Retraq Pro Monthly or Annual explicitly
confirms the per-recap pre-send dialog (see
`ai-transparency.md` UI requirements).

**What happens technically:**

1. User taps "Generate cloud recap" in the Recap tab and
   confirms the pre-send dialog.
2. App collects the user's Retraq journal entries from the
   past 7 days (title, body, mood, timestamp) — nothing else.
3. Payload serialized to JSON, sent via HTTPS to
   `[PROVIDER ENDPOINT]` in `[PROVIDER REGION]`.
4. Provider processes the payload through the audited
   system prompt; returns a synthesized paragraph.
5. Retraq renders the paragraph in the Recap tab with the
   Tier 3 AI label and modals per `ai-transparency.md`.
6. **Retraq does NOT store the returned recap on the provider
   side.** The summary is stored on-device only; re-generation
   requires re-sending the 7-day payload.
7. No user-identifying fields (name, account ID, device ID,
   install UUID) are included in the payload.

## 2. Categorize the personal information involved

| Field | Category | Sensitivity |
|---|---|---|
| Entry title | Personal — user-authored | Medium (can contain names of people / places / events) |
| Entry body | Personal — user-authored | High (can contain health-adjacent, relationship-adjacent content) |
| Mood (1–5) | Personal — inference-adjacent | Low–Medium (5-point scale, not diagnostic) |
| Entry timestamp | Personal — behavior trace | Low |
| User's locale | Personal — passed to route provider region | Low |

**Fields explicitly NOT sent:**

- User name, display name, email, or any other identifier.
- Install UUID or device identifier.
- Full journal archive — only the 7-day window.
- PIN hash or any auth material.
- Location, contacts, photos.
- Biometric data or unlock state.

**Special-category data (Law 25 / Art. 9 GDPR):** journal
entries can incidentally contain health, sexual, political, or
religious content. This is why the `pre-send confirmation is
required per recap` design choice (not one-time opt-in) — users
must affirm knowing what they wrote this week before it leaves
the device.

## 3. Identify the recipient

**Primary recipient:** `[PROVIDER NAME]` (e.g., Anthropic
Inc. / Google LLC / OpenAI LLC — one will be selected before
ship).

**Recipient jurisdiction:** `[JURISDICTION — US / EU depending
on routed region]`.

**Subprocessors:** per the provider's DPA and sub-processor list
as of `[DATE OF DPA SIGNING]`. Must be audited at DPA signing and
annually.

**Data residency option enforced:** `[YES/NO — depends on
provider's EU region availability]`. For Quebec users, Retraq
routes to the provider's North American region (Canada preferred,
US second). For EU users (separate PIA — tracked in the EU
equivalent), routes to EU region.

## 4. Assess risks

### Risk: unauthorized retention or training-data use

- **Likelihood:** Low (DPA forbids both explicitly).
- **Severity:** High (a provider-side leak could expose
  journal entries).
- **Mitigations:**
  - DPA clause: zero-retention, no training use, SOC 2 Type II
    annual audit, breach-notification within 72h.
  - Retraq requests the provider's annual transparency report;
    reviews for deviations.
  - Kill-switch: Retraq can disable Tier 3 remotely via
    Settings UI without an app update (currently backed by a
    RevenueCat entitlement flag).

### Risk: cross-border transfer without equivalent protection

- **Likelihood:** Dependent on provider jurisdiction.
- **Severity:** High (Law 25 violation, up to 4% revenue fine).
- **Mitigations:**
  - Provider chosen only if its DPA offers protection
    equivalent to Law 25: purpose limitation, data
    minimization, breach notification, user access/deletion
    rights.
  - Quebec users routed to the nearest data region with
    equivalent-protection jurisdiction (Canada preferred).
  - If no equivalent-protection region is available, Tier 3
    is NOT offered to Quebec users. The Tier 2 on-device
    alternative is available on Pixel hardware.

### Risk: user misunderstands data flow

- **Likelihood:** Medium (users often tap through dialogs).
- **Severity:** Medium (consent quality issue, not a breach).
- **Mitigations:**
  - Per-recap (not one-time) confirmation dialog prevents
    forgetting after initial opt-in.
  - The dialog uses plain language, not legal-ese.
  - `How my data is handled` modal always available from the
    rendered recap for post-hoc review.

### Risk: model output contains or infers health information

- **Likelihood:** Medium (user-authored content can include
  health references).
- **Severity:** Medium (output is stored only on-device; not
  re-sent).
- **Mitigations:**
  - Model prompt explicitly instructs the model to
    synthesize without diagnosing / interpreting /
    advising (enforcing the `ai-non-claims.md` blocklist at
    the system-prompt level).
  - Output stored on-device only (same encryption posture as
    journal entries).

### Risk: user account compromised → adversary generates Tier 3
### recaps

- **Likelihood:** Low (requires device unlock + Retraq
  unlock).
- **Severity:** Medium (adversary learns what user wrote
  this week).
- **Mitigations:**
  - Retraq unlock (PIN + optional biometric) required to open
    the app (Task 3.2). FLAG_SECURE prevents screen capture
    while the app is open (Task 3.4).
  - Tier 3 requires an active RevenueCat paid entitlement.
    Free-tier compromise cannot trigger cloud generation.

## 5. Demonstrate necessity + proportionality

**Why Tier 3 at all?** User demand — Tier 2 (Gemini Nano) is
Pixel-only; users on iPhone / non-Pixel Android who want AI
summaries need a cloud path or the product under-delivers on
the AI-adjacent v1.1 pitch (see
`../gtm/lifetime-sku-decision.md` — Lifetime SKU explicitly
skips AI; paying Monthly / Annual users expect it).

**Why 7 days, not full archive?** Minimum data to generate a
weekly recap. Shorter windows (3 days) produce low-quality
summaries; longer (30 days) would send proportionally more
sensitive data without proportional UX gain.

**Why not on-device for all users?** Gemini Nano requires
Pixel-class Tensor hardware. Cloud path is the only route for
non-Pixel Android + iOS until on-device models catch up (est.
2027+).

**Proportionality verdict:** Cloud processing of the 7-day
window is the minimum necessary for the feature. Zero-
retention + per-recap consent + on-device alternative for
Pixel users keeps the posture defensible.

## 6. Record the decision

| Field | Value |
|---|---|
| PIA completed on | `[DATE]` |
| PIA reviewed by | `[COUNSEL NAME / FIRM]` (B-6 or B-10) |
| Provider selected | `[PROVIDER NAME]` |
| DPA signed | `[DATE]` |
| DPA SHA-256 hash | `[HASH — for audit integrity]` |
| Quebec data region | `[REGION]` |
| Re-review cadence | Annual + at any DPA change + at any provider sub-processor change |

Before Tier 3 ships to Quebec users, every row above must be
filled AND counsel-reviewed.

## 7. Communicate to users

Quebec users see the standard Tier 3 pre-send confirmation
(per `ai-transparency.md`), plus the following additional
disclosure in the `How my data is handled` modal:

> **Quebec users:** Under Quebec's Law 25, you have the right
> to know where your data goes. Your Retraq recap is processed
> by `[PROVIDER NAME]` in `[REGION]`. The provider is
> contractually bound by a Data Processing Agreement that
> matches Quebec Law 25 protections: zero retention, no use
> for AI training, breach notification within 72 hours. A
> full Privacy Impact Assessment is available at
> [docs/legal/pia-quebec-cloud-ai.md](...).
>
> To stop cloud processing at any time: Settings → AI →
> Cloud recaps → off. You can also continue using Retraq's
> on-device recap (Tier 1) at no cost.

## 8. Retention + review

- **This PIA is reviewed annually** by privacy counsel.
- **Re-reviewed immediately** when:
  - Provider changes (new vendor or new sub-processor).
  - DPA terms change.
  - New Quebec Law 25 guidance from the Commission d'accès à
    l'information (CAI) affects cross-border AI processing.
  - Retraq's Tier 3 payload schema changes (e.g. adding a new
    field beyond the 7-day window).
  - EU AI Act / CNIL / OPC / EDPB issues relevant guidance.

## Sibling artifacts

- [`ai-transparency.md`](./ai-transparency.md) — UI / disclosure
  spec this PIA supports
- [`../gtm/ai-non-claims.md`](../gtm/ai-non-claims.md) —
  claim blocklist reinforced by the system-prompt constraint
- [`../../lib/legal/privacy_policy.dart`](../../lib/legal/privacy_policy.dart)
  — will be updated at Tier 3 launch with Quebec-specific
  disclosure (Task 12.2 pattern + Task 9.7 nutrition label
  rewrite)
- [`../plans/epic-12-legal.md`](../plans/epic-12-legal.md) —
  Task 12.13 source, Task 12.4 Art. 9 consent
- [`../external-blockers.md`](../external-blockers.md) — B-6 /
  B-10 (privacy counsel reviews that must sign off)
