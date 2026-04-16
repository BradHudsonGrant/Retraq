# Epic 4 — Product & Features Alignment

Source: review-2026-04-16.md §Agent 4

This epic aligns Retraq's planning documents, settings surface, and v1.1 monetization story with the April 2026 feature decisions and the current v1-ships-free posture. Every row of the Agent 4 Detailed Findings Table has a corresponding task below — Ship It rows are preserved as brief "no-op" reference entries so nothing is accidentally refactored out of v1.

Activation-metric note: several tasks reference a "4-weeks post-ship" review of toggle usage. That review depends on Epic 11's local stats export (anonymous telemetry / opt-in stats export). Until Epic 11 ships, the activation check is manual (10-user moderated sessions + TestFlight feedback) rather than data-driven. Each task calls this out explicitly.

---

### Task 4.1 — Rewrite implementation_plan.md monetization section

**Source:** A4 finding "Monetization section describes dead strategy (subs, Premium, Care, cloud AI)" · **Rating:** Rethink
**Priority:** P0 · **Effort:** M · **Tier:** v1

#### Problem
`implementation_plan.md` lines 244-266 still describe a $2–3/mo subscription, a "Retraq Premium" tier, a "Retraq Care" caregiver tier, and cloud AI — all four have been explicitly dropped per `memory/project_feature_decisions.md` lines 41-79. Any stakeholder, investor, or contractor reading the plan today gets a false roadmap and a fabricated business model.

#### Root cause
The implementation plan was authored during the SinceThen → Retraq rebrand (2026-04-05) before the Run 7 survey decisions (RevenueCat one-time IAP, mood-as-single-switch, no cloud AI in v1). The plan was never updated when feature_decisions.md was written.

#### Files touched
- `implementation_plan.md:244-266` — Section 8 "Monetization" full rewrite
- `implementation_plan.md:5,30` — top-level feature summary lines that reference subscription language
- `memory/project_feature_decisions.md` — no change; source of truth being realigned to
- `memory/project_ai_recap_plan.md` — no change; referenced for AI tiering language
- `C:\Users\bradd\.claude\projects\D--Documents-Projects-Lately\memory\MEMORY.md` — add pointer to rewritten plan section once landed

#### Implementation approach
1. Replace Section 8 heading from "Monetization & Subscriptions" to "Monetization (v1 free; v1.1+ one-time IAP)".
2. Before/after outline:
   - BEFORE §8.1 "Subscription tiers": Free / Retraq Premium ($2.99/mo) / Retraq Care ($4.99/mo family).
   - AFTER §8.1 "v1 pricing": Ships free on Play Store and App Store; no paywall; no login required; no subscription SDK bundled.
   - BEFORE §8.2 "Premium features": cloud AI recap, unlimited export, family sharing, caregiver dashboard.
   - AFTER §8.2 "v1.1 paid surface (planned)": a single one-time in-app purchase ("Retraq Pro") unlocks: (a) Gemini Nano weekly recap (on-device; Pixel 8+), (b) advanced themes, (c) CSV export + yearly recap. Exact price TBD after 4-week v1 activation review. RevenueCat will be the billing layer to keep cross-platform parity.
   - BEFORE §8.3 "Trial": 7-day free trial of Retraq Premium.
   - AFTER §8.3 "Trial": N/A — one-time IAP model has no trial; consider 7-day refund window via platform stores.
   - BEFORE §8.4 "Retraq Care family tier": caregiver pays $4.99/mo for shared dashboards.
   - AFTER §8.4 (delete entire sub-section; move to Task 4.3 backlog reference).
3. Cross-reference the rewritten section from README.md so both docs agree (README task tracked separately in 4.6).
4. Update `memory/MEMORY.md` auto-memory index entry for `project_feature_decisions.md` to note "supersedes implementation_plan.md §8".

#### Test plan
- Doc-only change; no feature tests required.
- Peer review: read both `implementation_plan.md` §8 and `memory/project_feature_decisions.md` end-to-end — no contradictions.
- Grep the repo for strings: `Retraq Premium`, `Retraq Care`, `$2.99`, `$4.99`, `subscription` in plan/README. Zero hits outside historical notes.
- Activation metric (manual): post-ship check at 4 weeks — do stakeholders referencing the plan still ask "when does the subscription turn on?" If yes, rewrite failed.

#### Acceptance criteria
- [ ] `implementation_plan.md` §8 contains only v1-free + v1.1 one-time IAP narrative
- [ ] No remaining references to "Premium", "Care", "$2-3/mo" in `implementation_plan.md` outside an explicit "2026-04 decision log" appendix
- [ ] Settings decision documented (toggle activation reviewed at 4 weeks post-ship) — N/A for doc-only task; note added to plan instead
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.1

#### Dependencies
- Blocks: Tasks 4.2, 4.3, 4.6 (they edit other parts of the same plan doc)
- External: none

---

### Task 4.2 — Rewrite implementation_plan.md Epic 6 (cloud AI Tier 3 removal)

**Source:** A4 finding "Epic 6 plan includes dropped Tier 3 Cloud AI" · **Rating:** Rethink
**Priority:** P0 · **Effort:** S · **Tier:** v1

#### Problem
`implementation_plan.md` lines 80-87 and 219-240 describe a three-tier AI recap strategy ending in Tier 3 cloud inference (OpenAI/Gemini API). Per `memory/project_ai_recap_plan.md` the cloud tier is dropped; v1 ships Tier 1 template only, v1.1 adds Tier 2 Gemini Nano on-device. Tier 3 is not on the roadmap.

#### Root cause
Same as 4.1 — plan predates the feature-decisions memory and was never reconciled.

#### Files touched
- `implementation_plan.md:80-87` — Epic 6 summary block
- `implementation_plan.md:219-240` — Epic 6 detailed tiering section
- `memory/project_ai_recap_plan.md` — no change; source of truth

#### Implementation approach
1. Before/after outline for Epic 6 summary (lines 80-87):
   - BEFORE: "Tier 1 (template, free), Tier 2 (Gemini Nano, premium on-device), Tier 3 (cloud AI, premium subscription)."
   - AFTER: "Tier 1 (template recap, free in v1). Tier 2 (Gemini Nano on-device recap, planned v1.1 behind one-time Pro IAP). No cloud-inference tier planned; privacy-first on-device stance is a deliberate competitive differentiator."
2. Before/after outline for detailed Epic 6 section (lines 219-240):
   - BEFORE: sub-sections for Tier 1, Tier 2, Tier 3 + cost model + fallback diagram.
   - AFTER: delete Tier 3 sub-section; expand Tier 2 to cover Pixel 8+ / AICore / on-device model download UX; add "Why no cloud tier" paragraph citing privacy-first positioning (A5 competitive note).
3. Add a one-line "2026-04 decision log" entry at bottom: "Cloud AI tier removed — see memory/project_feature_decisions.md and project_ai_recap_plan.md."

#### Test plan
- Doc-only change; no feature tests.
- Grep: `cloud AI`, `Tier 3`, `OpenAI API`, `Gemini API` → zero hits outside decision log.

#### Acceptance criteria
- [ ] Epic 6 describes exactly two tiers (template + Gemini Nano)
- [ ] No "Tier 3" language remains in plan
- [ ] Settings decision documented — N/A for doc-only task
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.2

#### Dependencies
- Blocked by: Task 4.1 (same file, sequence to avoid merge conflict)
- External: none

---

### Task 4.3 — Move caregiver/Alzheimer features from Phase 7 to v2 exploration

**Source:** A4 finding "Caregiver/Alzheimer features still in plan Phase 7 despite being dropped" · **Rating:** Rethink
**Priority:** P0 · **Effort:** S · **Tier:** v2

#### Problem
`implementation_plan.md` lines 178-185 still describe Phase 7 caregiver/dementia features (Retraq Care dashboard, memory-clinic partnerships, shared-family view, GPS safety pings) as an active roadmap phase. Per April 6 decision, personas 2 (elderly memory loss) and 3 (caregiver) are dropped for v1. These features should be marked "potential v2 exploration" not "Phase 7 roadmap."

#### Root cause
Same provenance issue — plan predates persona-narrowing decision.

#### Files touched
- `implementation_plan.md:178-185` — Phase 7 caregiver section
- `implementation_plan.md:153` — Persona summary (if it lists Persona 2/3 as active)
- `memory/project_feature_decisions.md` — no change
- A5 (market research) — caregiver is a real market gap; preserve the finding as v2 opportunity note

#### Implementation approach
1. Rename section heading "Phase 7: Retraq Care (Caregiver)" → "Appendix C: Potential v2 exploration — caregiver & dementia support".
2. Before/after outline:
   - BEFORE Phase 7 contents: dashboard spec, FHIR mention, family sharing, clinical-trial outreach plan.
   - AFTER Appendix C contents: one paragraph noting A5 research showed a $450M market with 15-20% CAGR; feature set TBD pending v1 activation and a separate business-case exercise; not to be confused with v1.1 Pro IAP (which is ADHD-adult–focused).
3. Add note: "A v2 caregiver build would likely require 12+/Teen age rating, separate data-sharing privacy label, and HIPAA-adjacent compliance review (see Agent 9)."

#### Test plan
- Doc-only; no feature tests.
- Grep `Retraq Care` → remaining hits only in A5 market notes and the new Appendix C.

#### Acceptance criteria
- [ ] Caregiver features live under Appendix C / v2 only
- [ ] Plan clearly states v1 targets Persona 1 (ADHD adult) exclusively
- [ ] Settings decision documented — N/A (no settings affected)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.3

#### Dependencies
- Blocked by: Task 4.2 (same file sequencing)
- External: none

---

### Task 4.4 — Hide AM/PM cutoff, bullet-points-on-enter, bionic reading behind Advanced

**Source:** A4 finding "Settings bloat: 5 sections + sub-toggles + Advanced" · **Rating:** Needs Work
**Priority:** P1 · **Effort:** M · **Tier:** v1

#### Problem
`lib/screens/settings_screen.dart` lines 112-179 show five top-level settings sections with sub-toggles that dilute the "radical simplicity" promise. Three toggles in particular — AM/PM cutoff, bullet-points-on-enter, bionic reading — are power-user ergonomics, not v1 core. Surfacing them above the Advanced fold risks first-run overwhelm for the ADHD-adult persona who is the entire v1 target.

#### Root cause
Feature drift: each toggle was added for a good individual reason, but cumulative surface area was never re-audited against the simplicity brief.

#### Files touched
- `lib/screens/settings_screen.dart:112-179` — reorganize sections; move three toggles into `_AdvancedSection`
- `lib/screens/settings/preferences_section.dart` — remove three toggles from default Preferences section
- `lib/screens/settings/advanced_section.dart` (create if missing, else extend) — accept the three toggles
- `lib/l10n/app_en.arb` — no new strings, but verify existing labels still resolve under new parent
- `test/screens/settings_screen_test.dart` — update expectations: three toggles only appear when Advanced is expanded

#### Implementation approach
1. Audit current Preferences section: list all toggles with 1-line rationale per toggle.
2. Move AM/PM cutoff, bullet-points-on-enter, bionic reading into `AdvancedSection` (expandable, collapsed by default).
3. Leave on main Preferences surface only: theme, mood on/off, week-start day, notifications.
4. Ensure settings persistence keys stay identical — no migration needed.
5. Add a small "Show advanced" affordance matching the existing expansion pattern in `advanced_section.dart`.

#### Test plan
- Widget test: default settings screen does NOT surface the three toggles.
- Widget test: expanding Advanced reveals them.
- Widget test: toggling a value in Advanced persists (unchanged behavior).
- Manual verification: fresh-install → Settings → count visible toggles on first screen ≤ 7.
- Activation metric (requires Epic 11 local stats export): at 4 weeks post-ship, if <5% of users have ever opened Advanced AND <1% toggled any of these three, consider removing the toggles entirely in v1.2.

#### Acceptance criteria
- [ ] Three toggles live in Advanced section only
- [ ] Settings persistence keys unchanged; no data migration
- [ ] Widget tests updated and green
- [ ] Settings decision documented (toggle activation reviewed at 4 weeks post-ship via Epic 11 export; manual moderated-session fallback if Epic 11 slips)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `refactor(product):` prefix referencing Task 4.4

#### Dependencies
- Blocked by: none (independent of doc rewrites)
- Blocks: Task 4.5 (both edit settings surface — sequence to avoid conflict)
- External: Epic 11 local stats export for activation metric

---

### Task 4.5 — Ship mood as single switch for v1 (drop sub-toggles)

**Source:** A4 finding "Mood feature has 3 dependent toggles" · **Rating:** Needs Work
**Priority:** P1 · **Effort:** M · **Tier:** v1

#### Problem
`lib/screens/settings/preferences_section.dart` lines 79-135 expose three dependent toggles for the mood feature (main mood on/off + style sub-toggles). Per Run 7 survey, mood is opt-in and must be a single switch for v1. Dependent toggles are cognitive overhead and contradict the blob-emoji-teal-scale spec.

#### Root cause
Mood shipped with multiple styling options during iteration. Run 7 survey then narrowed to a single aesthetic (blob emojis, teal scale) but the extra toggles were not removed.

#### Files touched
- `lib/screens/settings/preferences_section.dart:79-135` — collapse to one switch
- `lib/services/settings_repository.dart` — retain sub-toggle fields in schema but default them to the chosen Run 7 values; do not expose UI
- `lib/widgets/molecules/mood_selector.dart` — always render blob-emoji-teal-scale style
- `test/widgets/mood_selector_test.dart` — verify only blob-emoji-teal renders regardless of sub-settings
- `test/screens/settings_screen_test.dart` — only one mood toggle visible

#### Implementation approach
1. Keep DB columns for mood style sub-toggles (no migration) — write fixed defaults only.
2. UI: replace three toggles with one `SwitchListTile` "Track mood".
3. MoodSelector widget: hardcode the Run 7 style; ignore sub-toggle state.
4. Add a `// TODO(v1.1): re-expose if user demand emerges` comment at the removed UI site.
5. Activation metric: at 4 weeks post-ship, count % of users who have toggled mood ON. If <20%, consider defaulting OFF instead of removing.

#### Test plan
- Widget test: only one mood-related `SwitchListTile` on settings.
- Widget test: MoodSelector always blob-emoji-teal regardless of stored sub-toggle values.
- Manual: toggle mood on, log entries, toggle off — no orphan UI.
- Regression: existing mood widget tests still pass.

#### Acceptance criteria
- [ ] Single mood toggle in Preferences
- [ ] MoodSelector renders consistently (blob emoji + teal scale)
- [ ] Mood sub-toggle DB fields retained, default-written
- [ ] Settings decision documented (toggle activation reviewed at 4 weeks post-ship)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `refactor(product):` prefix referencing Task 4.5

#### Dependencies
- Blocked by: Task 4.4 (sequencing on settings file)
- External: Epic 11 for activation metric

---

### Task 4.6 — Align README.md with current state

**Source:** A4 finding "README claims need aligning with current state" · **Rating:** Needs Work
**Priority:** P1 · **Effort:** S · **Tier:** v1

#### Problem
`app/README.md` lines 11 and 50 carry claims (feature list, monetization language, or persona scope) that diverge from `memory/project_feature_decisions.md` and the April audit. README is often the first doc contractors/stakeholders open, so drift here is high-cost.

#### Root cause
README was updated during the Retraq rebrand but not reconciled against Run 7 decisions.

#### Files touched
- `app/README.md:1-3` — tagline / hero line
- `app/README.md:10-14` — feature bullets (home widget, tablet two-pane)
- `app/README.md:11` — specific claim cited by A4
- `app/README.md:50` — second specific claim cited by A4
- `memory/MEMORY.md` — no change; README points to memory files already

#### Implementation approach
1. Read README.md end-to-end; compare every bullet against `memory/project_feature_decisions.md`.
2. Specifically reconcile:
   - Monetization language → "v1 ships free; v1.1 planned one-time Pro IAP."
   - Persona scope → "v1 targets ADHD adults."
   - Home widget + tablet two-pane → keep (real features) and add matching Epic references per Task 4.7.
3. Make sure tagline ("Lost traq? Retraq.") is preserved — it is branded and A5/A9 both flagged it positively.

#### Test plan
- Doc-only; no tests.
- Peer review: scan README in 60s; list every claim; each one traces to a memory file or shipped feature.

#### Acceptance criteria
- [ ] No claim in README contradicts `memory/project_feature_decisions.md`
- [ ] Monetization narrative matches Task 4.1
- [ ] Settings decision documented — N/A
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.6

#### Dependencies
- Blocked by: Task 4.1 (must land new plan language first)
- External: none

---

### Task 4.7 — Add Home widget + tablet two-pane Epic mentions to implementation_plan.md

**Source:** A4 finding "Home widget and tablet two-pane exist in README but not in plan" · **Rating:** Needs Work
**Priority:** P2 · **Effort:** S · **Tier:** v1

#### Problem
README advertises the home widget and tablet two-pane layout (both real, shipped per Run 7 survey decisions), but `implementation_plan.md` lines 25-32 (Epic list) do not mention them. A stakeholder reading the plan doesn't see the scope that's actually built.

#### Root cause
Plan Epic list was written before widgets and tablet layout shipped; never backfilled.

#### Files touched
- `implementation_plan.md:25-32` — Epic list insertion
- `app/README.md:10-14` — cross-link to new Epic entries

#### Implementation approach
1. Add two Epic entries to the plan:
   - "Epic 9: Home-screen widgets (iOS + Android)" — describe `widget_service.dart`, Android AppWidget, iOS WidgetKit, nightly update.
   - "Epic 10: Tablet two-pane layout" — describe responsive breakpoint, entry list + detail side-by-side.
2. Before/after outline of Epic list:
   - BEFORE: Epics 1-8 only.
   - AFTER: Epics 1-10 with the two new ones inserted in shipped order; status "Shipped v1" on both.
3. README cross-link: bullet list mentions "(see plan Epic 9/10)".

#### Test plan
- Doc-only.
- Grep: `Epic 9`, `Epic 10`, `home widget`, `tablet` resolve consistently across README and plan.

#### Acceptance criteria
- [ ] Plan lists Epic 9 (widgets) and Epic 10 (tablet)
- [ ] README cross-links to plan Epics
- [ ] Settings decision documented — N/A
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.7

#### Dependencies
- Blocked by: Task 4.1 (same file)
- External: none

---

### Task 4.8 — Rename "Journal" → "Jot" in implementation_plan.md nav references

**Source:** A4 finding "'Jot' tab naming decided but plan still says 'Journal'" · **Rating:** Needs Work
**Priority:** P2 · **Effort:** XS · **Tier:** v1

#### Problem
`implementation_plan.md` lines 5 and 30 still reference "Journal" tab naming. Per Run 7 decision the primary nav is Jot / Recap / Stats / Settings. Plan drift here confuses new contributors reading the plan first then the code.

#### Root cause
Naming decision postdates plan authorship.

#### Files touched
- `implementation_plan.md:5,30` — two references
- grep `implementation_plan.md` for any remaining "Journal" used as nav label (not "journaling" as a verb)

#### Implementation approach
1. Find all `Journal` references in plan that refer to the tab name.
2. Replace with `Jot`.
3. Do not replace the word "journal" when used as a verb or category noun (e.g., "journaling app").

#### Test plan
- Doc-only.
- Grep: `Journal` references in plan all refer to the product category, not the tab.

#### Acceptance criteria
- [ ] Plan uses "Jot" for the primary tab name
- [ ] Settings decision documented — N/A
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.8

#### Dependencies
- Blocked by: Task 4.1 (same file)
- External: none

---

### Task 4.9 — Plan v1.1 premium feature (fill "nothing to upsell" gap)

**Source:** A4 finding "Nothing gated means nothing to upsell" · **Rating:** Rethink
**Priority:** P2 · **Effort:** L · **Tier:** v1.1

#### Problem
With v1 shipping fully free, there is no gated feature to convert users against when RevenueCat ships in v1.1. A4 identifies four candidates: Gemini Nano recap, themes, advanced analytics/CSV, yearly recap. Selecting and scoping one is a product decision that must happen before v1.1 development starts.

#### Root cause
Deliberate v1 choice (no paywall anywhere) created an intentional gap that now needs filling before RevenueCat integration.

#### Files touched
- `implementation_plan.md` — new §11 "v1.1 Retraq Pro — one-time IAP" (drafted in this task; implemented in a future epic)
- `memory/project_feature_decisions.md` — add line confirming v1.1 Pro feature choice
- No code files touched in this planning task; implementation gets its own epic later

#### Implementation approach
1. Run a short product exercise with the team (or solo product-brainstorm skill): score each candidate on:
   - Development effort (Gemini Nano: L; themes: S; CSV+analytics: M; yearly recap: M)
   - Perceived value per A5 competitive research
   - Privacy-story alignment (Nano scores highest)
   - Activation-gate risk (themes may be too shallow to convert)
2. Recommend bundle: Gemini Nano weekly recap + CSV export + yearly recap, sold as one "Retraq Pro" lifetime unlock. Themes moved to "also included" sweetener.
3. Write bundle spec into plan §11 with acceptance criteria, rough effort (L-XL for all three combined), and a dependency chain showing Nano blocking Pro ship.
4. Flag decision for founder review before v1.1 kickoff.

#### Test plan
- Planning task only; no code tests.
- Validation: after landing plan §11, do a second-pass product brainstorm to stress-test the bundle (use `product-management:product-brainstorming` skill).

#### Acceptance criteria
- [ ] Plan §11 defines the Retraq Pro bundle in detail
- [ ] Dependency chain identified (Epic 6 Tier 2 Nano blocks Pro ship)
- [ ] Pricing left as "TBD post 4-week v1 activation review"
- [ ] Settings decision documented — N/A (no v1 settings change)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.9

#### Dependencies
- Blocked by: Task 4.1 (monetization framing must land first)
- Blocks: any future RevenueCat epic
- External: founder product decision

---

### Task 4.10 — Reference: preserve hero flow "open, write, done"

**Source:** A4 finding "Hero flow delivers 'open, write, done'" · **Rating:** Ship It
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
No problem — this is the core delivered promise.

#### Root cause
N/A — working as designed.

#### Files touched
- `lib/screens/home_screen.dart:204-338` — hands-off; document as protected surface
- `implementation_plan.md` — add a "Protected surfaces" note if not already present

#### Implementation approach
1. Add a brief "Do not regress" note to `implementation_plan.md` Epic 1 (or create a "Protected surfaces" callout) pointing at `home_screen.dart:204-338` and stating: hero prompt, single TextArea, auto-save, haptic overlay are non-negotiable v1 UX.
2. No code changes.

#### Test plan
- None (reference entry).

#### Acceptance criteria
- [ ] Plan protects hero-flow surface explicitly
- [ ] Settings decision documented — N/A
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.10

#### Dependencies
- None

---

### Task 4.11 — Reference: preserve onboarding flow (reduce intros if activation weak)

**Source:** A4 finding "Onboarding: age gate + 3 intro + consent + notification pre-prompt" · **Rating:** Ship It
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
No problem for v1 ship; A4 suggests watching activation and trimming to 2 intros if weak.

#### Root cause
N/A.

#### Files touched
- `lib/screens/onboarding_screen.dart:51-143` — preserved
- `implementation_plan.md` — add activation-watch note

#### Implementation approach
1. Add note to plan: "Monitor D1 activation vs onboarding completion. If drop-off >25% between intro 2 and intro 3, A/B test a 2-intro variant."
2. No code changes in this task; any future A/B test gets its own epic.

#### Test plan
- Activation metric (Epic 11 required): at 4 weeks post-ship, compute % users completing all 3 intros. Manual moderated-session fallback (10 users) if Epic 11 slips.

#### Acceptance criteria
- [ ] Plan carries onboarding activation-watch note
- [ ] Settings decision documented (4-week activation review)
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.11

#### Dependencies
- External: Epic 11 for metric

---

### Task 4.12 — Reference: preserve retention hooks (keep streak visuals soft)

**Source:** A4 finding "Retention hooks: skip-if-journaled nudge, milestones, on-this-day, weekly recap, review at #5" · **Rating:** Ship It
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
No problem; guilt-free retention loop is a v1 strength.

#### Root cause
N/A.

#### Files touched
- `lib/screens/home_screen.dart:776-805` — hands-off
- `implementation_plan.md` — add "soft streak" guardrail note

#### Implementation approach
1. Add a note under Epic 3 (or Retention epic): "Streak UI must remain non-punitive. Never add red/loss visuals, never interrupt with a streak-broken modal. Protected invariant for ADHD audience."
2. No code changes.

#### Test plan
- Visual spot-check in each release: no red streak indicators, no "you lost your streak" copy.

#### Acceptance criteria
- [ ] Plan includes soft-streak invariant
- [ ] Settings decision documented — N/A
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.12

#### Dependencies
- None

---

### Task 4.13 — Reference: preserve "no home-screen edit/delete" (matches write-and-move-on)

**Source:** A4 finding "No entry edit/delete from home screen; undo snackbar covers regret" · **Rating:** Ship It
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None; current behavior matches the ADHD-adult brief.

#### Root cause
N/A.

#### Files touched
- `lib/screens/home_screen.dart` and `lib/screens/recap_screen.dart:251-263` — hands-off
- `implementation_plan.md` — add protected-surface note

#### Implementation approach
1. Add a "Do not add" note to plan: editing/deleting entries from the home screen is a deliberate omission. Undo snackbar + Recap-screen edit covers regret without polluting the capture flow.

#### Test plan
- None.

#### Acceptance criteria
- [ ] Plan carries the "no home edit/delete" guardrail
- [ ] Settings decision documented — N/A
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.13

#### Dependencies
- None

---

### Task 4.14 — Reference: preserve free-tier-compelling posture

**Source:** A4 finding "Free tier compelling (no paywall anywhere)" · **Rating:** Ship It
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None; deliberate v1 strategy.

#### Root cause
N/A.

#### Files touched
- `memory/project_feature_decisions.md:71-74` — already reflects this decision
- `implementation_plan.md` — covered by Task 4.1

#### Implementation approach
1. Covered by Task 4.1 (monetization rewrite). This entry exists only to note the Ship-It rating was preserved.

#### Test plan
- None.

#### Acceptance criteria
- [ ] Covered by Task 4.1
- [ ] Settings decision documented — N/A
- [ ] No separate commit required; folded into Task 4.1 commit

#### Dependencies
- Folded into Task 4.1

---

### Task 4.15 — Reference: preserve distinctive name and tagline (ADHD-lead subtitle note)

**Source:** A4 finding "App store positioning: name distinctive; tagline strong" · **Rating:** Ship It
**Priority:** P3 · **Effort:** XS · **Tier:** no-op (feeds Epic 9 App Store work)

#### Problem
None today. A4 suggests the app-store subtitle should lead with an ADHD/busy-brain hook rather than pure brand voice. That decision belongs to Agent 9's App Store readiness epic; Task 4.15 only notes the positioning intent here.

#### Root cause
N/A.

#### Files touched
- `pubspec.yaml:2` — no change in this task
- `app/README.md:1-3` — no change beyond Task 4.6
- `docs/retraq-branding-guide.md` — cross-reference from plan

#### Implementation approach
1. Add a line to plan Epic 9 (App Store): "Subtitle must lead with ADHD/busy-brain hook (A4 + A9 agreement). Brand voice carries in first-screenshot copy instead."

#### Test plan
- None (decision deferred to Epic 9 copywriting).

#### Acceptance criteria
- [ ] Plan Epic 9 carries subtitle-intent note
- [ ] Settings decision documented — N/A
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.15

#### Dependencies
- Feeds: Epic 9 App Store readiness

---

### Task 4.16 — Reference: voice entry as top v1.1 candidate

**Source:** A4 finding "Missing competitor features: no voice, no photo, no tags" · **Rating:** Ship It (v1)
**Priority:** P3 · **Effort:** XS · **Tier:** v1.1 backlog

#### Problem
None for v1 — narrowing scope is deliberate. A4 flags voice entry as the top v1.1 candidate because it's a natural ADHD fit (offload thought without thumb friction).

#### Root cause
N/A.

#### Files touched
- `implementation_plan.md` — add v1.1 backlog entry "Voice entry (top candidate)"
- `memory/project_feature_decisions.md` — optional backfill noting voice as v1.1 candidate

#### Implementation approach
1. Add bullet under v1.1 backlog in plan: "Voice entry — speech-to-text inline in Jot tab; evaluate on-device recognizer (Android SpeechRecognizer, iOS SFSpeechRecognizer) before cloud."
2. Note privacy-first requirement: prefer on-device STT to preserve "your memories never leave your phone" positioning (A5).

#### Test plan
- None (backlog entry).

#### Acceptance criteria
- [ ] Plan v1.1 backlog lists voice entry
- [ ] Privacy constraint captured
- [ ] Settings decision documented — N/A
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.16

#### Dependencies
- Blocked by: Task 4.1 (same file)

---

### Task 4.17 — Reference: preserve 3-checkbox consent flow

**Source:** A4 finding "Consent flow requires 3 checkboxes" · **Rating:** Ship It
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
None. Legally required under PIPEDA (Canada) per `memory/user_location.md` and industry best-practice for Apple 1.3 / FTC neutral age screen (A9 also rates this Ready).

#### Root cause
N/A.

#### Files touched
- `lib/screens/onboarding/consent_page.dart:217-247` — hands-off
- `lib/screens/onboarding_screen.dart:135-178,304-315` — hands-off
- `implementation_plan.md` — add compliance note

#### Implementation approach
1. Add note to plan Onboarding epic: "Three-checkbox consent (privacy, terms, age confirmation) is a compliance surface. Any change requires legal review."

#### Test plan
- None.

#### Acceptance criteria
- [ ] Plan carries consent-surface guardrail
- [ ] Settings decision documented — N/A
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `docs(product):` prefix referencing Task 4.17

#### Dependencies
- None

---

## Rollup

**Total tasks:** 17
**By priority:** P0 = 3 · P1 = 3 · P2 = 3 · P3 = 8
**By tier:** v1 = 7 · v1.1 = 2 · v2 = 1 · backlog = 0 · no-op = 7

Commit convention for this epic: `docs(product):` for plan/README rewrites, `refactor(product):` for settings-surface reorgs. All commits reference `Task 4.<N>` in the body and push to `BradHudsonGrant/Retraq` main.
