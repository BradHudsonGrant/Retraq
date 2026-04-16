# Epic 5 — Market Positioning & Go-to-Market

Source: review-2026-04-16.md §Agent 5

This epic translates the 14 rows of the Agent 5 Detailed Findings Table into concrete go-to-market artifacts: positioning docs, battlecards, screenshot overlay copy, creator outreach kits, pricing A/B plans, and store-listing narrative. Tasks are ordered by priority (P0 launch-blockers first), then grouped by tier.

---

### Task 5.1 — Write v1 launch narrative hook + differentiation one-pager

**Source:** A5 finding "ADHD-focused simplicity positioning is crowded, not distinctive" / Bottom Line "biggest strategic risk is launching without a distinctive narrative hook" · **Rating:** Gap
**Priority:** P0 · **Effort:** M · **Tier:** v1 launch

#### Problem
Retraq sits in one of the most crowded corners of the App Store. "ADHD-focused simplicity" is claimed by Daylio, Day One, Apple Journal, Stoic, Finch, Journey, Reflectly, Rosebud, Mindsera, Inflow. Without a distinctive narrative, ASO + creator seeding will underperform and the app will be treated as "another ADHD journal."

#### Root cause (market dynamic that drives this)
Every incumbent has already planted a flag on simplicity/ADHD/mood; users searching for journaling apps pattern-match to Daylio and Apple Journal by default. Differentiation must come from a vertical wedge (caregiver), a trust story (on-device privacy), or a memory-recall job-to-be-done — not from UX polish alone.

#### Deliverables
- `docs/gtm/positioning-one-pager.md` — single-page narrative: target persona, core job-to-be-done ("retrieve a week/month you wouldn't otherwise remember"), the three proof points (on-device, caregiver-aware, recap-first), and the "why now" line.
- `docs/gtm/taglines-ab.md` — 5 tagline candidates incl. current "Lost traq? Retraq." and 4 alternates (e.g. "Your memories never leave your phone.", "Retraq your week before it disappears.") with A/B testing rationale.
- `docs/gtm/narrative-hook.md` — the 1-sentence hook used across App Store subtitle, Play short-description, press, and creator DMs.

#### Implementation approach
1. Workshop the 3 candidate wedges (caregiver, privacy, recap) against Daylio/Apple Journal/Rosebud positioning grid.
2. Pick one primary wedge; the other two become supporting proof points.
3. Draft the one-pager in the voice from `docs/retraq-branding-guide.md`.
4. Commit 5 tagline variants with predicted ASO impact and recall test plan.

#### Success criteria
- External reviewer can restate Retraq's unique value in one sentence without using the word "simple."
- Narrative hook passes the "would a Daylio user switch?" test.
- Taglines fit App Store subtitle (30 chars) AND Play short-description (80 chars).

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.1

#### Dependencies
- Blocks: Task 5.2-5.9 (all competitor battlecards reference the one-pager's wedge).
- Blocks: Epic 9 store listing copy.
- External: requires final brand voice confirmation from `docs/retraq-branding-guide.md`.

---

### Task 5.2 — Build Daylio battlecard + "memory backup / recap" positioning artifact

**Source:** A5 finding "Daylio owns 'mood + micro-entry in 30 seconds'" · **Rating:** Gap
**Priority:** P0 · **Effort:** S · **Tier:** v1 launch

#### Problem
Daylio has 20M+ installs and 4.8 stars from 393K reviews. Competing on speed-of-entry is a losing fight. The Agent 5 recommendation is to flank Daylio via "memory backup / recap your week" which Daylio does weakly.

#### Root cause (market dynamic that drives this)
Daylio's moat is install base + mood-icon familiarity, not recap depth. Users who already keep a Daylio streak are unlikely to switch unless given a different job.

#### Deliverables
- `docs/gtm/battlecards/daylio.md` — 1-page battlecard: Daylio strengths, Daylio weaknesses (shallow recap, no on-device-only story, no caregiver angle), Retraq counter-positioning, objection handling for "but Daylio is free + established."
- `assets/store-listing/screenshot-copy-recap.md` — overlay caption for the Recap/Week screen in store listings: e.g. "The week you forgot. Retraqed."
- `docs/gtm/competitor-keywords-daylio.md` — 10 ASO keywords Daylio ranks on that Retraq can rank adjacent-to (mood tracker, daily journal, micro journal, quick mood log).

#### Implementation approach
1. Pull top 30 Daylio Play Store reviews mentioning "recap", "summary", "forgot", "remember" to mine pain language.
2. Draft battlecard with 3 "when Retraq wins" scenarios.
3. Write screenshot overlay copy for Recap screen (6.7"/6.5"/Pixel 9 Pro XL sizes — coordinate with Epic 9).

#### Success criteria
- Battlecard is usable by creator-seeding DMs without modification.
- Screenshot overlay copy passes readability at phone-thumbnail size (48pt+ weight).

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.2

#### Dependencies
- Blocked by: Task 5.1 (narrative hook).
- Blocks: Epic 9 store screenshots.

---

### Task 5.3 — Build Apple Journal counter-positioning for iOS listing

**Source:** A5 finding "Apple Journal free, iOS-native, AI-prompted" · **Rating:** Gap (iOS)
**Priority:** P0 · **Effort:** S · **Tier:** v1 launch

#### Problem
Apple Journal is bundled in iOS 17.2+, free, AI-prompted, and widely recommended in 2026 roundups. Any iOS user searching "journal" sees Apple Journal recommended first. Retraq must give iOS users a concrete reason to install a third-party app.

#### Root cause (market dynamic that drives this)
OS-bundled apps have zero install friction and default-trust. Third-party apps must beat Apple Journal on either cross-device (Apple Journal is iOS-only), export/portability (Apple Journal locks data in), or a specific audience need (ADHD/memory) that Apple Journal does not address.

#### Deliverables
- `docs/gtm/battlecards/apple-journal.md` — iOS-specific battlecard. Focus on: (a) cross-device (Android parity day 1), (b) full data export, (c) ADHD + caregiver-aware UX, (d) structured recap/stats Apple Journal lacks.
- `docs/gtm/android-first-positioning.md` — rationale for leading the launch on Android where Apple Journal is not a threat; iOS becomes a secondary market sized against specific ADHD/export-wanting segments.
- `assets/store-listing/ios-subtitle-variants.md` — 3 subtitle variants (30 chars) that plant the flag vs Apple Journal without naming it.

#### Implementation approach
1. Research Apple Journal's Mac/iPad support status as of 2026-04 and document gaps.
2. Draft iOS listing subtitle variants explicitly differentiating on export or ADHD.
3. Add a "Why not Apple Journal?" FAQ entry to the press kit.

#### Success criteria
- iOS subtitle passes App Store Connect character limit and addresses the Apple-Journal-default objection.
- Android-first launch order is documented and aligns with Epic 9 launch-timing recommendation.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.3

#### Dependencies
- Blocked by: Task 5.1.
- External: requires final iOS listing assets from Epic 9.

---

### Task 5.4 — Lead with "your memories never leave your phone" privacy narrative

**Source:** A5 finding "Privacy-first on-device rare in category" · **Rating:** Advantage
**Priority:** P0 · **Effort:** S · **Tier:** v1 launch

#### Problem
On-device-only processing is a genuine advantage in this category (How We Feel nonprofit is the closest comp), but currently not amplified in store listings, press, or onboarding copy.

#### Root cause (market dynamic that drives this)
Most competitors (Day One, Rosebud, Mindsera, Inflow) sync to cloud or send text to LLM providers. Users who care about privacy have no clear safe harbor — and post-2024 Apple privacy-label scrutiny, the "Data Not Collected" label is highly credible.

#### Deliverables
- `docs/gtm/privacy-narrative.md` — 3-paragraph narrative: what stays on the phone, what that means operationally (no sync unless user opts in to v1.1+ cloud AI), how this compares to category norms.
- `assets/store-listing/screenshot-copy-privacy.md` — overlay caption for a "Privacy / On-device" screen: e.g. "Your words never leave your phone."
- `docs/gtm/press-kit-privacy-talking-points.md` — 5 soundbites for reviewers/creators to quote.

#### Implementation approach
1. Mine existing `lib/legal/privacy_policy.dart` and README for the precise phrasing; align voice with `docs/retraq-branding-guide.md`.
2. Draft narrative; cross-link to Agent 9 finding that privacy nutrition label will need a rewrite in v1.1 when cloud AI ships.
3. Add a "Privacy" screenshot to the required-screenshots matrix.

#### Success criteria
- Narrative reads as credible, not defensive — no legal-ese in marketing copy.
- "Your memories never leave your phone" (or chosen variant) appears in store long description, onboarding, and at least 2 screenshots.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.4

#### Dependencies
- Blocked by: Task 5.1.
- Blocks: Epic 9 screenshot set.
- External: Epic 4 cloud AI privacy label rewrite plan (v1.1).

---

### Task 5.5 — Design RevenueCat paywall A/B test + price tier decision tree

**Source:** A5 finding "2026 benchmarks: hard paywall + trial 10.7% D35" + key finding "Subscription $2-3/mo is too low for category, viable as differentiator" · **Rating:** Parity
**Priority:** P0 · **Effort:** M · **Tier:** v1 launch (planning), v1.1 (execution)

#### Problem
Retraq's planned $2-3/mo price undercuts category (Daylio $4.99/mo, Day One Silver $49.99/yr + Gold $74.99/yr, Rosebud $8.99/mo, Mindsera $129/yr, Inflow $22.49-47.99/mo). RevenueCat 2026 benchmarks show higher-priced subscriptions convert trial-to-paid better, so "cheap differentiator" may be leaving revenue on the table.

#### Root cause (market dynamic that drives this)
Cheap pricing signals low value to some segments; undercutting Day One Gold is defensible only if Retraq's value prop differs (it does: recap + on-device + caregiver). But trial-to-paid conversion on $2-3 typically skews toward low-intent users.

#### Deliverables
- `docs/gtm/pricing-decision-tree.md` — decision tree with branches: $2.99/mo (original), $3.99/mo (category floor), $4.99/mo (Daylio parity), $5.99/mo (mid), plus annual variants (35-40% discount). Each branch lists predicted D35 conversion, ARPU, and positioning cost.
- `docs/gtm/revenuecat-paywall-variants.md` — 3 paywall designs (hard paywall post-trial, soft gate on recap feature, value-scarcity pre-trial) with copy and trigger rules.
- `docs/gtm/ab-test-plan-pricing.md` — RevenueCat experiment spec: geo splits (CA/AU/NZ soft-launch first), minimum sample size, stop criteria, decision owner, and success metric (D35 paid retention, not just initial conversion).

#### Implementation approach
1. Pull RevenueCat 2026 State-of-Subscription benchmarks for "lifestyle + health" category.
2. Model 4 price points x 3 paywall variants = 12 cells; prioritize 3 cells for soft-launch test.
3. Document the "must-not-change-during-test" variables (trial length, screenshot set, store copy).
4. Align with Epic 4 RevenueCat integration for variant identifiers.

#### Success criteria
- Decision tree is actionable: for any observed conversion, next price test is pre-decided.
- Paywall copy variants pass App Store 3.1.2(b) requirement to disclose price, billing period, auto-renewal.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.5

#### Dependencies
- Blocks: v1.1 paywall launch.
- Blocked by: Epic 4 RevenueCat SDK integration.
- Blocked by: Task 5.11 (trial length) for shared test design.

---

### Task 5.6 — Position vs Inflow as budget ADHD journal alternative

**Source:** A5 finding "Inflow charges $22.49-47.99/mo for ADHD CBT" · **Rating:** Advantage
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
Inflow is 7-16x Retraq's price. This is a concrete ad copy and creator talking point (retaining ADHD users priced out of Inflow) that Retraq has not weaponized.

#### Root cause (market dynamic that drives this)
ADHD CBT apps have drifted into premium pricing. A "free + cheap pro" journal positioned as an Inflow complement (not replacement — Inflow does CBT, Retraq does capture) is a natural acquisition story for r/ADHD and ADHDTok.

#### Deliverables
- `docs/gtm/battlecards/inflow.md` — battlecard emphasizing Retraq as complement to, not replacement for, Inflow: "Capture your day for $2.99/mo. Do the CBT work in Inflow for $22.49+/mo."
- `docs/gtm/creator-talking-points-inflow.md` — 5 lines creators can drop without making clinical claims.
- `docs/gtm/reddit-outreach-snippet.md` — r/ADHD-safe comment template (non-promotional, answers a real "cheap journal?" question).

#### Implementation approach
1. Verify Inflow's current pricing (scrape getinflow.io; pricing may have changed since April 2026).
2. Draft the complement (not replacement) battlecard to avoid triggering r/ADHD anti-promo moderation.
3. Write Reddit-safe snippet with no affiliate codes.

#### Success criteria
- Battlecard can be read by a creator in <60s and restated accurately.
- Reddit snippet passes the "would r/ADHD mods remove this?" test.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.6

#### Dependencies
- Blocked by: Task 5.1.

---

### Task 5.7 — Document Retraq Care caregiver wedge + memory-clinic partnership pipeline

**Source:** A5 finding "Dementia/caregiver apps focus on meds/GPS, not activity reassurance" / "No app bridges caregiver reassurance + ADHD quick-capture" · **Rating:** Advantage
**Priority:** P1 · **Effort:** M · **Tier:** v2

#### Problem
The caregiver/dementia market is ~$450M (2025) at 15-20% CAGR, underserved by journaling-first products. Memair is closest. Retraq Care is the review's single most-recommended differentiator, but no outreach pipeline or market-entry plan exists.

#### Root cause (market dynamic that drives this)
Existing caregiver apps are medical-adjacent (meds, GPS, fall detection) — not activity/memory reassurance. There's a clear gap for a family-friendly memory journal bridging ADHD quick-capture and early-dementia companion use.

#### Deliverables
- `docs/gtm/caregiver-wedge-strategy.md` — market sizing, persona (adult child of parent with early-stage memory loss), use case (shared read-only recap of parent's week), and year-1 go/no-go criteria.
- `docs/gtm/memory-clinic-outreach-list.md` — 15 Canadian + 15 US memory/dementia clinics and 5 early-memory-loss nonprofits, with contact approach (not cold-pitch, but pilot offer).
- `docs/gtm/caregiver-press-kit.md` — separate press kit for caregiver angle (not the main ADHD-journal press kit).

#### Implementation approach
1. Size the Canadian market subset (Alzheimer Society Canada chapters, CIHI data).
2. Build outreach list leaning on existing user-location.md note (Canada + PIPEDA).
3. Draft pilot-offer template: free Premium codes for clinic patient-families, anonymized aggregate feedback loop.
4. Flag age rating and data-sharing implications (Epic 9 finding: caregiver ships requires 12+/Teen rating + explicit data-sharing disclosure).

#### Success criteria
- Outreach list has 30 verified contacts.
- Pilot offer template passes privacy review (no PHI collection; read-only caregiver view requires opt-in from both parties).

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.7

#### Dependencies
- Blocked by: Retraq Care feature build (Epic not yet planned).
- Blocked by: age-rating and data-disclosure work from Epic 9.

---

### Task 5.8 — Seed 20-30 ADHDTok creators + r/ADHD mods + therapists with Premium codes

**Source:** A5 finding "ADHDTok proven viral acquisition channel" · **Rating:** Advantage
**Priority:** P1 · **Effort:** L · **Tier:** v1.1

#### Problem
ADHDTok is a proven viral acquisition channel but Retraq has no creator outreach kit, code-granting process, or seed list.

#### Root cause (market dynamic that drives this)
ADHD TikTok is a trust-first, anti-sponcon community. The only effective outreach is authentic: small creators, no forced scripts, transparent "here's a code, if you like it, say so, if not, don't." Creators flag and avoid heavy-handed brand DMs.

#### Deliverables
- `docs/gtm/creator-seed-list.md` — 30 ADHDTok creators (follower range 10k-500k, English + Canadian priority), 5 r/ADHD mods/flaired contributors, 10 ADHD-adjacent therapists active on Instagram/TikTok. Each row: handle, audience size, content angle, why-they'd-care note.
- `docs/gtm/creator-dm-template.md` — 3 DM variants (short/med/long) + response handling tree (interested / not interested / needs more info / wants paid partnership).
- `docs/gtm/code-granting-process.md` — operational process: how codes are issued via RevenueCat promo offers, how attribution is tracked without analytics (per-creator promo code entitlement), how burnout is avoided (max 2 follow-ups).
- `docs/gtm/therapist-outreach-template.md` — professionally-toned variant for therapist outreach distinct from creator DMs.

#### Implementation approach
1. Mine TikTok + Instagram for 30 creators tagged #ADHDTok #neurodivergent #adhdjournal who have NOT done paid partnerships in the last 3 months.
2. Build the DM tree in plain prose, not corporate voice.
3. Document RevenueCat promo offer setup for per-creator codes.
4. Draft anti-burnout rule: no more than 2 touches, one for launch + one 4 weeks later.

#### Success criteria
- At least 20 ADHDTok creators accept codes and install the app.
- At least 5 r/ADHD mods / therapists accept codes.
- DM template avoids every anti-pattern r/ADHD documents about brand outreach.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.8

#### Dependencies
- Blocked by: Epic 4 RevenueCat integration for promo offers.
- Blocked by: Task 5.1 narrative hook.

---

### Task 5.9 — Design "lightweight engagement hook" spec vs Finch/Stoic (no streak penalties)

**Source:** A5 finding "Finch and Stoic favored on TikTok/Reddit ADHD community" · **Rating:** Gap
**Priority:** P1 · **Effort:** M · **Tier:** v1.1

#### Problem
Finch (pet) and Stoic (quote-of-the-day) have share-ability + low-cost engagement hooks that drive ADHDTok viral moments. Retraq has none, and ADHD users cycle off apps that lack a lightweight pull. But Retraq must NOT add streak-penalty mechanics — streak shame is the top complaint in ADHD app reviews.

#### Root cause (market dynamic that drives this)
ADHD users respond to dopamine hits (cute pet, daily quote, small surprise) but punish apps that punish missed days. The sweet spot is share-ability without shame: something users voluntarily screenshot, not something guilting them.

#### Deliverables
- `docs/gtm/engagement-hook-spec.md` — product spec (handoff to Epic engineering) for 3 candidate hooks: (a) shareable "week-in-moods" card, (b) monthly retraq "you wouldn't have remembered this" callback, (c) random past-entry surprise on app open. Each with penalty-free language.
- `docs/gtm/share-card-visual-brief.md` — visual spec for the shareable card: what's on it, dimensions for IG Story + TikTok, respects privacy (no raw entry text by default; opt-in only).
- `docs/gtm/engagement-copy-review.md` — review of all engagement copy to ensure no loss-aversion ("don't break your streak!") language.

#### Implementation approach
1. Survey Finch + Stoic ADHDTok content for the top 5 share-moments that actually get posted.
2. Pick the hook with lowest engineering cost + highest share-intent.
3. Write copy deliberately in encouragement voice ("you logged 4 days this week, nice") not loss voice ("you broke your streak").
4. Handoff as product-spec to engineering epic.

#### Success criteria
- Hook spec can be built without streak-penalty mechanics.
- Visual brief passes "would a user voluntarily screenshot this?" test.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.9

#### Dependencies
- Blocks: Engineering epic for share-card feature.
- Blocked by: Task 5.1.

---

### Task 5.10 — Position Retraq AI as enhancement (not core) vs Rosebud/Mindsera

**Source:** A5 finding "Rosebud $8.99/mo, Mindsera $129/yr target AI power users" · **Rating:** Parity
**Priority:** P1 · **Effort:** S · **Tier:** v1.1

#### Problem
Rosebud and Mindsera have raised the AI bar. Any attempt to "out-AI" them fails on cost, model access, and positioning. Retraq's AI must be framed as enhancement, not core.

#### Root cause (market dynamic that drives this)
Rosebud/Mindsera users self-select for "AI-powered journaling." They're not Retraq's ICP. Retraq's ICP wants memory + recap, and AI helps summarize — it's not the reason to open the app.

#### Deliverables
- `docs/gtm/battlecards/rosebud-mindsera.md` — "we are not this" battlecard. Explicitly state Retraq's AI is offline-first (Gemini Nano on Pixel) with an opt-in cloud tier; the reason to open the app is your memory, not the AI's prompts.
- `docs/gtm/ai-tier-messaging.md` — copy for the cloud AI tier landing: frames AI as "your week, summarized" not "ask an AI about your day."
- `docs/gtm/ai-non-claims.md` — explicit list of AI claims Retraq will NOT make (no therapy, no coaching, no CBT, no diagnosis).

#### Implementation approach
1. Mine Rosebud + Mindsera pricing and listing copy; identify the AI claims they lean on.
2. Draft Retraq's counter-frame that positions AI as summarization, not conversation.
3. Cross-reference with Agent 9 health-claim posture (memory/ADHD language restricted).

#### Success criteria
- AI tier copy passes the "could this be rejected under Apple 1.4.1 / Play Health Apps?" check.
- Battlecard answers "why not just use Rosebud?" in one sentence.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.10

#### Dependencies
- Blocked by: Task 5.1.
- Blocked by: Epic 4 AI feature plan (`memory/project_ai_recap_plan.md`).

---

### Task 5.11 — Choose + document trial length (7-14 day) A/B plan

**Source:** A5 finding "Trial length: <4 days converts at 25.5% vs 70% better for longer" · **Rating:** n/a
**Priority:** P1 · **Effort:** S · **Tier:** v1.1

#### Problem
Trial length is a high-leverage decision: sub-4-day trials convert 25.5% worse than longer trials per 2026 benchmarks. Currently no documented default.

#### Root cause (market dynamic that drives this)
Longer trials give journaling apps (high-engagement, low-frequency-early) enough time for users to accumulate entries worth keeping. Short trials catch users before they've built enough history to fear losing it.

#### Deliverables
- `docs/gtm/trial-length-decision.md` — recommendation (7 day floor, 14 day default, with 21 day as experimental upper bound) + rationale + exit criteria.
- `docs/gtm/trial-length-ab-plan.md` — 7 vs 14 vs 21 day A/B test spec aligned with Task 5.5 pricing test (must not run simultaneously to avoid variable collision).

#### Implementation approach
1. Pull businessofapps + RevenueCat 2026 benchmarks for journaling/lifestyle category trial-length conversion.
2. Recommend default + the one follow-on test post-launch.
3. Document RevenueCat trial entitlement config implications.

#### Success criteria
- One trial length is picked as v1.1 launch default, with a documented fallback if conversion underperforms.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.11

#### Dependencies
- Blocked by: Epic 4 RevenueCat integration.
- Coordinates with: Task 5.5 pricing A/B test.

---

### Task 5.12 — Write "Quick Journal niche" positioning note (no moat)

**Source:** A5 finding "Minimalist 'Quick Journal' niche exists" · **Rating:** Parity
**Priority:** P2 · **Effort:** XS · **Tier:** backlog

#### Problem
Quick Journal / Journalistic occupy a minimalist niche. Retraq is incrementally better but not differentiated — this should be documented so the team doesn't over-invest in "we're a quick journal" messaging.

#### Root cause (market dynamic that drives this)
Minimalism is table-stakes in 2026 journal apps. The danger is anchoring Retraq's narrative on a commoditized axis.

#### Deliverables
- `docs/gtm/battlecards/quick-journal.md` — short battlecard: acknowledge parity, do NOT lead with speed-of-entry in marketing, route all "fast journal" comparisons back to Task 5.2 Daylio battlecard.

#### Implementation approach
1. Document the parity finding + explicit "do not lead with this" guidance.
2. Cross-link to Task 5.2.

#### Success criteria
- Marketing team has explicit written guidance not to use "fast journal" as a primary claim.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.12

#### Dependencies
- Blocked by: Task 5.1.

---

### Task 5.13 — Frame Day One Gold price comparison for cloud-AI tier listing

**Source:** A5 finding "Day One Gold AI summaries $74.99/yr" · **Rating:** Parity
**Priority:** P2 · **Effort:** XS · **Tier:** v1.1

#### Problem
Day One Gold AI summaries are $74.99/yr. Retraq's planned cloud AI tier at $2-3/mo ($24-36/yr) is a clean undercut, but the comparison is not framed in any listing or landing page.

#### Root cause (market dynamic that drives this)
Category leader sets the anchor price. Day One Gold is the reference point for "journal + AI summary at premium tier." Anchoring to it makes Retraq's price feel like a steal.

#### Deliverables
- `docs/gtm/price-anchoring-day-one.md` — price comparison table + permissible landing-page copy (do not name Day One in ads; name it in blog/press; never in App Store listing).
- `assets/store-listing/screenshot-copy-pricing.md` — price-focused overlay caption for a Pricing screen or subscription page: e.g. "Weekly recap. Monthly memories. $2.99/mo."

#### Implementation approach
1. Document the Day One Gold + Silver stack as the category anchor.
2. Draft permissible comparison copy (Apple and Play both forbid naming competitors in listings).
3. Draft press-kit variant where naming Day One is allowed.

#### Success criteria
- Landing page + press kit both communicate the price undercut without violating store-listing rules.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.13

#### Dependencies
- Blocked by: Task 5.5 final price decision.
- Blocked by: Task 5.1.

---

### Task 5.14 — Position "radical simplicity + one-time Pro" vs subscription-trap complaints

**Source:** A5 finding "ADHD app reviews complain about overwhelm, subscription traps" · **Rating:** Advantage
**Priority:** P2 · **Effort:** S · **Tier:** v1.1

#### Problem
ADHD app reviews (choosingtherapy.com et al) consistently flag overwhelm + subscription-trap patterns. Retraq's planned pricing model (free v1, cheap subscription v1.1) mitigates this, but a one-time "lifetime Pro" SKU could be a differentiator — not yet decided.

#### Root cause (market dynamic that drives this)
Subscription fatigue is real in the ADHD community. A one-time lifetime price ($49-79) reads as "respects your executive function." But it conflicts with the Task 5.5 subscription pricing test.

#### Deliverables
- `docs/gtm/lifetime-sku-decision.md` — decision doc: ship lifetime SKU or not, price ($49 / $69 / $79), positioning (parallel to sub or replacement), and how it interacts with Task 5.5 A/B.
- `docs/gtm/anti-dark-pattern-copy.md` — review of all paywall + cancellation copy to ensure no known subscription-trap patterns (pre-checked boxes, hidden cancel, countdown-timer manipulation).

#### Implementation approach
1. Compare Day One's (no lifetime) vs Journey (offers lifetime) conversion patterns.
2. Recommend: ship lifetime as an "escape hatch" SKU from the paywall, priced at 2-year equivalent.
3. Audit existing paywall design (once built) for dark patterns; produce checklist.

#### Success criteria
- Lifetime SKU decision is documented and defensible.
- Paywall passes ADHD-community anti-pattern audit.

#### Acceptance criteria
- [ ] Artifact written and reviewed
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(gtm):` prefix referencing Task 5.14

#### Dependencies
- Blocked by: Task 5.5 pricing decision.
- Blocked by: Epic 4 RevenueCat integration (lifetime entitlement support).

---

## Summary

| # | Task | Priority | Effort | Tier |
|---|---|---|---|---|
| 5.1 | Launch narrative hook + differentiation one-pager | P0 | M | v1 launch |
| 5.2 | Daylio battlecard + recap positioning | P0 | S | v1 launch |
| 5.3 | Apple Journal counter-positioning | P0 | S | v1 launch |
| 5.4 | Privacy-first narrative | P0 | S | v1 launch |
| 5.5 | RevenueCat paywall A/B + price decision tree | P0 | M | v1 launch → v1.1 |
| 5.6 | Inflow budget-alternative positioning | P1 | S | v1 launch |
| 5.7 | Retraq Care caregiver wedge + clinic pipeline | P1 | M | v2 |
| 5.8 | ADHDTok creator + r/ADHD + therapist seeding | P1 | L | v1.1 |
| 5.9 | Lightweight engagement hook spec vs Finch/Stoic | P1 | M | v1.1 |
| 5.10 | AI-as-enhancement positioning vs Rosebud/Mindsera | P1 | S | v1.1 |
| 5.11 | Trial length decision + A/B plan | P1 | S | v1.1 |
| 5.12 | Quick Journal parity note | P2 | XS | backlog |
| 5.13 | Day One Gold price anchoring | P2 | XS | v1.1 |
| 5.14 | Subscription-trap defense + lifetime SKU decision | P2 | S | v1.1 |
