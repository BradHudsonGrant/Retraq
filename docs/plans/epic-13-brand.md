# Epic 13 — Brand, Visual Identity & Marketing Appeal

Source: review-2026-04-16.md §Agent 13
Total tasks: 21

This epic covers every row of the Agent 13 Detailed Findings Table. The brand has top-1% microcopy and a distinctive protectable name; the work concentrates on (a) fixing the app icon (single biggest first-impression liability), (b) distinguishing the mood palette from unmodified Material Teals, (c) preserving the strong microcopy and typography assets with documented guardrails, and (d) planning for a caregiver sub-identity in v2.

Commit prefixes: `feat(brand):` for new visual assets, `chore(brand):` for repo-level artifact updates, `docs(brand):` for guideline changes.

---

### Task 13.1 — Redesign the app icon around the "Q as pin/speech bubble" motif

**Source:** A13 finding "Icon: mint R + U-turn arrow on near-black" · **Rating:** Weak
**Priority:** P0 · **Effort:** L · **Tier:** v1 launch

#### Problem
Current icon (`app/assets/images/icon.png`, `icon_foreground.png`) reads as a GPS/retrace/returns utility rather than a journal/memory app. On a home screen next to Instagram, TikTok, Notes, Day One, Daylio, it lacks journal affordance — the mint R + U-turn arrow is the single biggest first-impression liability identified in the audit.

#### Root cause
Initial icon direction leaned into "retrace" semantics from the name without considering the home-screen shelf test against direct competitors. The mark was chosen for name-explanation over category-signalling.

#### Deliverables
- 3 concept directions (Q-pin, Q-speech-bubble, Q-dot-marker) as SVG → PNG at multiple sizes
- Shortlisted direction chosen after home-screen shelf test
- Final `assets/images/icon.png` (1024×1024 for iOS)
- Final `assets/images/icon_foreground.png` + `icon_background.png` (Android adaptive)
- `assets/images/retraq-mark-v2.svg` (new master)
- App Store marketing icon (1024×1024)
- Notification badge icon (ic_notification_24dp monochrome)
- Updated `docs/retraq-branding-guide.md:190-230` — lock the new mark, deprecate the old
- Home-screen shelf-test artifacts: screenshots at 192dp with 6 competitor icons adjacent

#### Implementation approach

**Concept direction A — "Q as dropped pin":**
The Q's tail becomes a pin point. Inside the Q bowl: a small mint `▾` or a single entry line glyph suggesting "a moment pinned."
- Pros: Strongest "saved / pinned memory" affordance; reads as journal-adjacent; proprietary to Retraq (no other journaling app uses a Q-pin).
- Cons: Pin-drop is GPS-coded too; must be clearly a Q first, pin second.

**Concept direction B — "Q as speech bubble":**
The Q is the speech bubble; the tail is the bubble's pointer. Inside: 2-3 short lines suggesting text.
- Pros: Clear "something said / recorded"; aligns with "drop a traq" verb; differentiates from Daylio's emoji, Day One's calendar.
- Cons: Speech bubble trope is heavily used (social, messaging apps); risk of reading as a chat app.

**Concept direction C — "Q as dot-marker with concentric ripple":**
The Q's bowl is a solid dot; the tail is a subtle ripple suggesting "this moment rippling into memory." Minimal, abstract.
- Pros: Most premium / editorial; scales well to 24dp (ripple disappears, dot reads as "journal day"); hardest for competitors to copy.
- Cons: Most abstract — loses "journal" affordance in favor of brand-first recognition. Requires stronger store-listing copy to carry affordance.

**Evaluation criteria** (applied to all 3 concepts):
1. Journal/memory affordance — does someone on the App Store recognize the category in <1 second?
2. Home-screen shelf-test distinctiveness — does it stand out next to Instagram, TikTok, Notes, Day One, Daylio, Apple Journal?
3. Small-size legibility — readable at 24dp (notification), 48dp (tab bar if used), 192dp (app-drawer grid).
4. Premium perception — does it feel like a $3/mo product, not a hobby project?
5. ADHD-culture fit — warm, non-clinical, approachable.
6. Brand extension — does it scale to Retraq Care sub-brand in v2 (Epic 13.21) without a total redesign?

**Process:**
1. Brief an icon designer (Dribbble / Fiverr Pro / 99designs, or a friend-of-friend). Budget: $500-2500 CAD for 3 concept rounds + 2 revisions + final files.
2. Designer delivers 3 concepts at 192×192 with 4 color variants (default, dark-bg, monochrome, one-color).
3. Run shelf test: export each at 180×180 and arrange in a 4×6 grid beside 12 competitor icons (Instagram, TikTok, Notes, Day One, Daylio, Apple Journal, How We Feel, Finch, Reflectly, Journey, Moodnotes, Stoic). Rank by category-signal strength with 5-10 friends-and-testers.
4. Pick the winner. Iterate once on palette (test against warmer off-white background than current `#121412` near-black).
5. Export final asset matrix:
   - iOS: 1024 (App Store), 180 (iPhone @3x), 120 (@2x), 87 (Settings @3x), 58 (@2x), 40 (Spotlight), etc. Use `flutter_launcher_icons` to automate.
   - Android: adaptive 108dp with 72dp inner safe zone. Foreground + background layers.
   - Notification monochrome 24dp.
6. Update `lib/widgets/atoms/retraq_logo.dart` (the in-app logo widget) with the new mark and deprecate the old path.
7. Update `docs/retraq-branding-guide.md:190-230` icon section: screenshot the new mark, add usage rules, deprecate the R+U-turn.

#### Design/QA plan
- Mock at 24dp, 40dp, 72dp, 192dp (app drawer size)
- Home-screen shelf test vs 12 competitor icons — document the ranking
- Dark-mode adaptive icon test on Pixel (Material You variants)
- Screen-reader icon description: "Retraq, memory journal app"

#### Acceptance criteria
- [ ] 3 concepts explored; winner chosen via shelf test
- [ ] Final asset matrix generated at all platform sizes
- [ ] In-app logo widget `retraq_logo.dart` references new mark
- [ ] `docs/retraq-branding-guide.md` updated; old mark deprecated with date-stamped note
- [ ] Screenshot of new icon in app-drawer context archived at `docs/brand/icon-shelf-test.png`
- [ ] Commit pushed with `feat(brand): new Q-motif app icon (Task 13.1)`

#### Dependencies
- Blocks: Task 9.5 (app-store screenshots lead with icon), Task 5.1 (marketing positioning), Task 13.21 (sub-brand v2)
- Blocked by: none
- External: icon designer engagement (~$500-2500 CAD); user approval of chosen direction

---

### Task 13.2 — Customize mood-scale hues off unmodified Material Teal 200-700

**Source:** A13 finding "Mood scale uses unmodified Material Teal 200-700" · **Rating:** Weak
**Priority:** P1 · **Effort:** S · **Tier:** v1.1

#### Problem
`lib/theme/app_colors.dart:78-92` uses `#80CBC4`→`#00796B` (Material Teal 200-700) as-is. Not brand-owned; any Flutter tutorial demo uses these exact values. Undermines premium perception.

#### Root cause
Chosen for speed; never revisited.

#### Deliverables
- Updated `lib/theme/app_colors.dart:78-92` with custom mood-scale hex values
- `docs/retraq-branding-guide.md` — mood scale entry with hex + usage
- WCAG contrast computation table for each mood value against surface + on-surface

#### Implementation approach
1. Shift hues 8-12° toward the brand primary (`#33694B`) green to unify with the brand without losing distinctness across 5 mood levels:
   ```dart
   // Before (Material Teal 200-700): #80CBC4, #4DB6AC, #26A69A, #00897B, #00796B
   // After (Retraq mood scale — named):
   static const moodRough    = Color(0xFF7EA08C);  // muted sage, low energy
   static const moodLow      = Color(0xFF6B9484);  // subdued teal-green
   static const moodNeutral  = Color(0xFF4E8A77);  // centered
   static const moodGood     = Color(0xFF3F8072);  // forward, stable
   static const moodAmazing  = Color(0xFF2A7566);  // saturated, deep — the "peak"
   ```
   These are indicative; the final palette should be iterated by hand (or a tool like Leonardo.io) for:
   - Perceptually uniform spacing across 5 steps (CIEDE2000 delta-E ~10-12 between adjacent steps)
   - Dark-mode dual track (each mood value gets a dark-surface variant)
   - WCAG AA contrast when rendered as a filled chip with `onPrimary` text

2. Provide `moodColorFor(int mood, Brightness b)` helper already exists — swap values; add assertions that the dark-mode variant is distinct.
3. Document the scale in the brand guide: "Retraq's mood scale is a 5-step teal-green progression rooted in the primary green, representing felt-state intensity along a single emotional axis."
4. A/B test (via Epic 11's local bucketer Task 11.7) — does the custom scale affect mood-entry activation?

#### Design/QA plan
- Swatch visualization at 192×192 per mood
- Simulated red-green color-blind and achromatic view — do the 5 values remain distinguishable? (Expect failure; mitigate with labels already present in the UI.)
- WCAG contrast ratio table:
  | Mood | Hex | vs onSurface `#2D3432` | vs surface `#F8FAF8` | Pass 4.5:1? |
  |---|---|---|---|---|

#### Acceptance criteria
- [ ] New hex values committed in `app_colors.dart:78-92`
- [ ] WCAG table published in brand guide
- [ ] No visual regression on mood blob at text-scale 2.0
- [ ] Commit pushed with `feat(brand): custom mood-scale palette (Task 13.2)`

#### Dependencies
- Blocks: Task 7.15 (mood selector dim state contrast)
- Blocked by: none (can land anytime post-launch)

---

### Task 13.3 — Introduce a warm accent color for CTAs / Q-motif

**Source:** A13 finding "Primary `#33694B` forest green + `#B5F0C9` mint + `#F8FAF8` off-white" rated Neutral — "Consider a distinctive accent (warm amber/terracotta) for the Q-motif or CTAs to own a second color"
**Priority:** P1 · **Effort:** S · **Tier:** v1.1

#### Problem
Palette is warm and calm but shared with Finch's mint territory and a dozen habit trackers. No distinctive second color for CTAs or the Q-motif means the brand reads as "wellness default."

#### Root cause
Single-hue discipline. Works for minimalism but doesn't own any pixel on the App Store.

#### Deliverables
- New accent token in `lib/theme/app_colors.dart`
- Usage guide in `docs/retraq-branding-guide.md`

#### Implementation approach
1. Candidate accents (test all three visually against the existing green + mint):
   - **Warm amber `#E8A838`** — sunrise-adjacent; evokes "capture the day." Pairs well with green. WCAG 4.5:1 at `onPrimary` on amber (dark text): ~9.1:1 ✓.
   - **Terracotta `#C8664F`** — earthy, warm, non-clinical. Good contrast on off-white. Risk: reads "health / healing" app which is fine.
   - **Coral `#FF7357`** — most energetic. Best for CTA buttons but overpowering at icon scale.
2. Recommended: **warm amber** — highest differentiation without stepping on the green's calm authority. Use sparingly (1 accent per screen max).
3. Apply accent to:
   - Primary CTA button in the paywall (when it lands, Epic 4)
   - Milestone celebration chips
   - New-entry "Save" button (optional, A/B test)
   - Q-motif fill in the app icon (Task 13.1 coordination)

#### Design/QA plan
- Side-by-side screenshots of current home screen vs. amber-accented version
- Color-blind simulation — amber stays distinctive in deutan/protan
- User test (6-8 friends) — "which reads more premium / more distinctive?"

#### Acceptance criteria
- [ ] Accent token added as `AppColors.accentAmber`
- [ ] Used in at least 2 locations
- [ ] WCAG pass verified
- [ ] Commit pushed with `feat(brand): warm amber accent for CTAs (Task 13.3)`

#### Dependencies
- Blocks: Task 13.1 (icon may use the accent in the Q fill), Epic 4 Task 4.15 (paywall CTA)
- Blocked by: none

---

### Task 13.4 — Test logo-mark silhouette at 24dp/40dp/60dp

**Source:** A13 finding "Logo mark uses complex 2094px path (from the raw SVG) — intricate at scale" · **Rating:** Neutral
**Priority:** P2 · **Effort:** S · **Tier:** v1 launch

#### Problem
`retraq-mark-raw.svg` and `logo.svg` are clean but the interior R cavity + arrow may be visually noisy at 48px tab-bar size. Need to verify small-size legibility.

#### Root cause
Logo was designed at display-size first; never audited at functional small sizes used in-app (tab bar, nav icon, notification badge).

#### Files touched
- `lib/widgets/atoms/retraq_logo.dart` — add `size` variants
- `assets/images/retraq-mark-simplified-24dp.svg` (new, if simplification needed)
- `assets/images/retraq-mark-simplified-40dp.svg` (new, if needed)
- `docs/retraq-branding-guide.md` — publish "small-size variant" rules

#### Implementation approach
1. Export the current mark at 24/40/60/96/192dp. Visually inspect.
2. If the 24dp variant is muddy, commission a simplified 1-path or 2-path version (likely just the Q/R outer silhouette with minimal interior detail).
3. `RetraqLogo` atom auto-selects the appropriate mark based on the `size` prop:
   ```dart
   String _pickAsset(double size) {
     if (size <= 32) return 'assets/images/retraq-mark-24.svg';
     if (size <= 56) return 'assets/images/retraq-mark-40.svg';
     return 'assets/images/retraq-mark.svg';
   }
   ```

#### Design/QA plan
- 3×3 grid: sizes 24, 40, 60, 96, 192 — inspect at native screen pixel density (test on Pixel 10 Pro AMOLED)
- Color variants: on light, on dark, on primary green

#### Acceptance criteria
- [ ] Mark is legible at 24dp
- [ ] Atom auto-picks size-appropriate asset
- [ ] Commit pushed with `feat(brand): small-size logo variants (Task 13.4)`

#### Dependencies
- Blocks: Task 13.1 (if new icon requires a matching in-app logo)
- Blocked by: Task 13.1 (new mark)

---

### Task 13.5 — Sub-brand decision tree for caregiver (v2)

**Source:** A13 finding "One brand, three personas" · **Rating:** Weak — "Copy skews heavily young-ADHD... Grandparent persona will not self-identify"
**Priority:** P3 · **Effort:** L · **Tier:** v2

#### Problem
Retraq's voice ("drop a traq", "busy brains", "for people who forget Tuesday by Thursday") is native to ADHD-adult culture. Will alienate Persona 3 (65+ memory concerns) and sit awkwardly with Persona 2 (40-something caregiver). When Retraq Care ships in v2, a sub-brand question must be resolved.

#### Root cause
Brand wasn't designed to stretch across three personas; v1 deliberately narrows to ADHD-adjacent to win one market first.

#### Deliverables
- `docs/brand/sub-brand-decision-tree.md` — the decision framework
- Three concept explorations (copy + visual) if sub-brand chosen

#### Implementation approach
Decision tree:
```
Q1: Does Retraq Care ship standalone or as a Premium feature of the existing app?
├── Standalone app → NEW sub-brand required. Options: "Retraq for Family" / "Retraq Together" / "Retraq Care"
│   Q2: Who is the user of the new app — the person with memory concern or the caregiver?
│   ├── Memory-concern user → UI/copy must shift to clinical-neutral. Lexend stays (research-backed). Voice: "How was your day?" not "Drop a traq." Palette: same green + warmer accent.
│   └── Caregiver → Dashboard-style. Voice: informational, reassuring, not playful. "[User] journaled 3 times this week."
│
├── Premium feature of existing Retraq → NO sub-brand required but a "Family Mode" toggle shifts copy and surfaces caregiver dashboard.
│   Pros: lower marketing cost, one codebase, shared user base.
│   Cons: persona friction; ADHD-young-adult users see "invite your caregiver" in their Settings and feel wrong.
```

Recommendation: **"Retraq for Family" standalone sub-brand** when v2 ships. Shared Lexend + green + logo-motif family. Voice: warm-professional, not ADHD-playful. Targeted store listing, separate ASO.

Concept exploration deliverables:
1. Wordmark variations — "Retraq" + small "for Family" subtext vs. compound name
2. Color pairing — keep primary green, introduce a second warm hue as a family-identifier
3. Voice samples — 5 lines of onboarding copy in the proposed sub-brand voice

#### Design/QA plan
- User test with 3 grandparents + 3 adult-children-caregivers: which name and visual feels right?
- Compare against BodyBrightForMums / Medisafe / Lotsa Helping Hands visual language — known caregiver-market competitors

#### Acceptance criteria
- [ ] Decision tree documented with recommendation
- [ ] If standalone chosen: 3 concept sketches + user-test feedback archived
- [ ] Gate: no v2 caregiver code ships until sub-brand resolved AND Task 12.12 legal framework done
- [ ] Commit pushed with `docs(brand): sub-brand decision tree for v2 caregiver (Task 13.5)`

#### Dependencies
- Blocks: ALL v2 caregiver UX
- Blocked by: Task 12.12 (caregiver legal framework), Task 5.6 (caregiver market analysis from Epic 5)

---

### Task 13.6 — File CIPO + USPTO trademark applications

**Source:** A13 finding "Name 'Retraq' is distinctive and trademarkable... Keep. Lock trademark (CIPO in Canada per memory); unregistered ™ claim already in guide"
**Priority:** P1 · **Effort:** M · **Tier:** v1 launch

#### Problem
Name is distinctive and protectable; failing to file early risks losing priority if a competitor files a similar mark post-launch.

#### Root cause
Trademark filing was listed as intent in the brand guide but not yet executed.

#### Deliverables
- CIPO (Canada) trademark application — Nice Classes 9 (software) and 42 (SaaS)
- USPTO (United States) trademark application — Classes 9 + 42
- (Optional, post-revenue) EUIPO + UKIPO applications
- `docs/legal/trademark-status.md` — tracking document

#### Implementation approach
1. **CIPO** (Canada):
   - File via CIPO online portal (https://ised-isde.canada.ca/site/canadian-intellectual-property-office/en/trademarks). Cost: ~$458 CAD first class + $139/additional.
   - Word mark "RETRAQ" (all caps, no stylization — broadest protection).
   - Optional: figurative mark for the new icon (Task 13.1).
2. **USPTO** (US):
   - File via TEAS Plus ($250/class) if using Acceptable ID manual descriptions. TEAS Standard $350/class otherwise.
   - Same classes 9 + 42.
   - Intent-to-use basis if not yet using in US commerce (Retraq isn't released yet), switch to use-based at launch.
3. Consider engaging a trademark attorney — this is a ~$500-1500 service but catches categorization errors and Office Action responses. Recommend: yes, at least for initial USPTO filing.
4. Maintain trademark status doc tracking filing dates, registration numbers, renewal dates (CIPO 10-year renewal; USPTO 10-year with 5-6 year declaration).

#### Design/QA plan
- Pre-file clearance search: USPTO TESS, CIPO CDNTMS, common-law search for "retraq", "retrack", "retrax", etc. (Already done per Agent 5/9 — confirm no collisions in classes 9 + 42.)

#### Acceptance criteria
- [ ] CIPO application filed
- [ ] USPTO application filed
- [ ] Status doc published and updated
- [ ] Commit pushed with `docs(brand): file CIPO + USPTO trademark applications (Task 13.6)`

#### Dependencies
- Blocks: ability to use ® (can use ™ in the interim)
- Blocked by: Task 12.11 (Canadian entity registration — can file as individual but entity is cleaner)
- External: Government fees ($500-2000 CAD total); attorney fees optional ($500-1500)

---

### Task 13.7 — Publicly commit to "Retraq" and archive old Lately/SinceThen assets

**Source:** A13 finding "Rebrand trail (Lately → SinceThen → Retraq in 6 months)" · **Rating:** Neutral — "Third name in a year signals instability if seen externally. Commit to Retraq publicly; avoid changing again pre-launch."
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
Three names in six months. Externally visible rebrands signal product-market-fit hunting and erode trust. Commit publicly; archive old assets.

#### Root cause
Evolving product-market-fit understanding. That's healthy during hunting; it must stop before customers see it.

#### Files touched
- `README.md` — remove any residual Lately / SinceThen references
- `docs/retraq-branding-guide.md` — version-stamp as "v1.0, 2026-04-05, canonical brand"
- `lib/l10n/app_en.arb` — grep for any stale product-name references (should be zero from recent rebrand)
- Archive: move `docs/archive/brand-history/` with old Lately and SinceThen assets for historical record
- `pubspec.yaml`, `lib/services/database_service.dart` — audit secure-storage keys for stale prefixes (already done per April audit but verify)

#### Implementation approach
1. Grep all of `lib/` and `docs/` for "Lately", "SinceThen", "lately", "sincethen" — expect zero hits in production code, some in migration history / git log.
2. Any residual user-visible strings → fix.
3. Publish a brand-history doc `docs/archive/brand-history.md` — internal-only:
   > "This app was named Lately at inception, rebranded to SinceThen in Feb 2026, rebranded to Retraq 2026-04-05. The Retraq identity is permanent. Any stakeholder seeing inconsistent branding should report via @brad."
4. Consent-version bump not required (name change is UX, not legal; privacy policy already references Retraq).

#### Design/QA plan
- Final brand-guide version-stamp
- Archive folder in place

#### Acceptance criteria
- [ ] Zero residual old-brand strings in shipping code
- [ ] Brand guide version-stamped v1.0
- [ ] Brand history archive exists
- [ ] Commit pushed with `chore(brand): archive Lately/SinceThen assets; lock Retraq v1.0 brand (Task 13.7)`

#### Dependencies
- Blocks: Task 13.6 (trademark filing — requires locked brand)
- Blocked by: none

---

### Task 13.8 — [No-op reference] Name "Retraq" is distinctive and self-explaining

**Source:** A13 finding "Name 'Retraq' is distinctive, memorable, explains itself via tagline 'Lost traq? Retraq.'" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Strong asset. Preserve.

#### Implementation approach
1. Document as a brand pillar in `docs/retraq-branding-guide.md` — "The name and tagline are immutable. Any replacement requires a formal brand review with written rationale."
2. Tagline usage guidance: default to "Lost traq? Retraq." in store-listing subtitle slot (30 chars); use shorter "Your memory backup" in contexts where the pun reads wrong (clinical/healthcare listings, EU markets where the pun may not translate).

#### Acceptance criteria
- [ ] Brand guide pins name + tagline
- [ ] Commit pushed with `docs(brand): pin name + tagline as immutable (Task 13.8)`

#### Dependencies
- Blocked by: Task 13.7

---

### Task 13.9 — [No-op reference] No app-store name conflicts

**Source:** A13 finding "No app-store conflicts in journaling category" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Strong.

#### Implementation approach
1. Re-run app-store name search quarterly. Automated? Possibly — app2top or similar ASO tool. For v1 launch, run manually and log in `docs/legal/trademark-status.md`.

#### Acceptance criteria
- [ ] Quarterly search calendar event created
- [ ] Documented in trademark-status.md

---

### Task 13.10 — [No-op reference] Lexend + Manrope typography pairing

**Source:** A13 finding "Typography: Lexend (headlines) + Manrope (body), variable-weight w475" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Premium, research-backed (Lexend). Preserve.

#### Implementation approach
1. Do NOT change.
2. Add a prominent line in store-listing copy: "Built with Lexend, a font designed to support reading fluency."
3. Lock in brand guide: "Typography stack is immutable without a written rationale."

#### Acceptance criteria
- [ ] Brand guide typography section pinned
- [ ] Store-listing copy includes Lexend callout
- [ ] Commit pushed with `docs(brand): pin Lexend+Manrope typography (Task 13.10)`

#### Dependencies
- Blocks: Task 9.4 (store-listing copy — includes Lexend callout)

---

### Task 13.11 — [No-op reference] Onboarding empathy copy preserved

**Source:** A13 finding "Onboarding copy: 'How've you been? What have you been up to? If those questions make your mind go blank, you're in the right place.'" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Best-in-class ADHD-aware empathy hook.

#### Files touched
- `lib/l10n/app_en.arb:160-165` — do not change
- `docs/retraq-branding-guide.md` — quote verbatim as a "preserved copy" example

#### Implementation approach
1. Mark these ARB strings as "DO NOT CHANGE without brand review" with an inline comment.
2. Preserve in any copy translation — translators must maintain the tone, not just the literal meaning.

#### Acceptance criteria
- [ ] ARB keys marked "preserved"
- [ ] Brand guide quotes the copy
- [ ] Commit pushed with `docs(brand): preserve onboarding empathy copy (Task 13.11)`

---

### Task 13.12 — [No-op reference] Empty state copy preserved

**Source:** A13 finding "Empty states: 'No traqs yet. Drop a traq?' / 'Drop your first traq. Even one word counts.'" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Models behavior it wants. Preserve.

#### Implementation approach
1. Mark ARB keys `noTraqsYet`, `dropFirstTraq`, related as "preserved."
2. Extend pattern to any new empty states (e.g., search-no-results, recap-no-week) — do NOT default to "No results found." Write in-voice copy.

#### Acceptance criteria
- [ ] Preserved ARB keys annotated
- [ ] Brand guide includes empty-state style rules
- [ ] Commit pushed with `docs(brand): preserve empty-state voice (Task 13.12)`

---

### Task 13.13 — [No-op reference] Milestone copy preserved

**Source:** A13 finding "Milestone copy: '25 traqs! Look at you go.' / '50 traqs! That's genuinely impressive.'" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Anti-Duolingo tone. Preserve.

#### Implementation approach
1. Mark milestone ARB keys as preserved.
2. Add a rule: new milestones (if added above 1000) must be co-authored with a copy review to maintain tone.

#### Acceptance criteria
- [ ] ARB keys annotated
- [ ] Brand guide notes milestone tone rule
- [ ] Commit pushed with `docs(brand): preserve milestone celebration voice (Task 13.13)`

---

### Task 13.14 — [No-op reference] Tagline "Lost traq? Retraq." as App Store subtitle

**Source:** A13 finding "Tagline: 'Lost traq? Retraq.'" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Best 3-second explainer. Use as subtitle.

#### Implementation approach
1. iOS App Store subtitle field: "Lost traq? Retraq."
2. Agent 9 Task 9.4 (listing copy) uses this. **Coordinate with Epic 9** — may need to re-evaluate based on ASO learning that the coined verb reduces search-intent matches. Compromise: subtitle in first A/B variant; swap for "ADHD memory journal" in variant B to compare install rates.

#### Acceptance criteria
- [ ] Subtitle captured in `docs/store-listing/ios.md`
- [ ] Task 9.4 cross-referenced
- [ ] Commit (as part of 9.4): `docs(brand): tagline as iOS subtitle (Task 13.14)`

#### Dependencies
- Blocks: Task 9.4
- Blocked by: none

---

### Task 13.15 — [No-op reference] "Traq" verb/noun vocabulary system

**Source:** A13 finding "Verb/noun system: 'drop a traq,' 'week retraqd,' 'your traqs'" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Proprietary vocabulary. Preserve consistently.

#### Implementation approach
1. Publish a "Retraq vocabulary" appendix in the brand guide:
   - ✅ Use: "drop a traq", "your traqs", "week retraqd", "retraq it", "catch up on traqs"
   - ❌ Avoid: generic "entry", "log", "note", "post" (except in legal/privacy contexts where clarity > style)
2. Enforce via a CI copy-lint (optional) that warns if `\b(entry|log|note)\b` appears in ARB strings outside legal context.

#### Acceptance criteria
- [ ] Vocabulary appendix published
- [ ] Optional CI lint added
- [ ] Commit pushed with `docs(brand): Retraq vocabulary appendix (Task 13.15)`

---

### Task 13.16 — [No-op reference] Copy principles forbid clinical language

**Source:** A13 finding "Copy principles explicitly forbid clinical/medical/diagnostic language" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Correct. Preserve. Coordinates with Epic 12 Task 12.5 (forbidden-claims lint).

#### Implementation approach
1. Merge with Task 12.5: the forbidden-claims CI lint also serves brand-protection. Cross-reference in brand guide.
2. Brand guide style rules: "ADHD-friendly" ✓ / "treats ADHD" ✗ ; "memory backup" ✓ / "improves memory" ✗ ; "for busy brains" ✓ / "for people with cognitive impairment" ✗ until Retraq Care launch.

#### Acceptance criteria
- [ ] Brand guide cross-references Task 12.5 CI lint
- [ ] Style rules enumerated
- [ ] Commit pushed with `docs(brand): cross-reference clinical-language rules (Task 13.16)`

#### Dependencies
- Blocked by: Task 12.5

---

### Task 13.17 — [No-op reference] Anti-obligation "want to use" positioning

**Source:** A13 finding "Positioning 'want to use' vs. 'should use' — no streaks, no guilt, no prompts" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Correct ADHD strategy. Preserve.

#### Implementation approach
1. Brand guide: enumerate the anti-obligation principles:
   - No streak penalties (streak shown as a soft stat, not a penalty)
   - No red exclamation marks, no guilt icons
   - Empty days are fine
   - Notifications are skippable / dismissible without friction
2. Enforce via PR-review checklist: any feature adding a guilt mechanic triggers brand review.

#### Acceptance criteria
- [ ] Principles documented
- [ ] PR template updated with checkbox
- [ ] Commit pushed with `docs(brand): anti-obligation principles (Task 13.17)`

---

### Task 13.18 — Competitor visual-positioning battlecard

**Source:** A13 finding "Competitor comparison — Day One (blue, photo-rich, premium journaling), Daylio (orange/mood-emoji, gamified), Journey (multi-platform), Finch (pink/purple, pet-gamified), How We Feel (teal, emotion-granular)" · **Rating:** Neutral
**Priority:** P2 · **Effort:** S · **Tier:** v1 launch

#### Problem
No visual battlecard exists. Need reference for designers, marketing, and any future competitor-analysis updates.

#### Files touched
- `docs/brand/competitor-visual-battlecard.md` (new)

#### Implementation approach
1. Create a battlecard with:
   - Side-by-side icon screenshots (Day One, Daylio, Finch, Journey, How We Feel, Apple Journal, Reflectly, Moodnotes, Rosebud)
   - Primary palette for each
   - Voice/tone summary per competitor
   - Positioning axis chart: minimalist ↔ gamified on X, clinical ↔ playful on Y — plot all competitors and Retraq
2. Verdict: Retraq sits in "minimalist + playful" quadrant alongside Apple Journal (minimalist + neutral) — close but distinct because of voice, not visual.

#### Acceptance criteria
- [ ] Battlecard published with visual comparisons
- [ ] Positioning chart attached
- [ ] Commit pushed with `docs(brand): competitor visual battlecard (Task 13.18)`

#### Dependencies
- Blocks: Task 5.1 (market positioning in Epic 5 cites battlecard)
- Blocked by: none

---

### Task 13.19 — [No-op reference] Social/marketing potential preserved

**Source:** A13 finding "Social/marketing potential — 'For people who forget Tuesday by Thursday,' 'Journalling apps want your life story. Retraq just wants a sentence.'" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
TikTok-ready one-liners in brand guide. Organic marketing potential high.

#### Implementation approach
1. Catalog the existing one-liners in `docs/brand/taglines.md` — with "situation for use" metadata (TikTok caption, Reddit post headline, Twitter bio, App Store promotional text).
2. Cross-reference with Epic 5 Task 5.7 (ADHDTok creator outreach) — these are the lines seeded to creators.

#### Acceptance criteria
- [ ] Tagline catalog published
- [ ] Commit pushed with `docs(brand): social tagline catalog (Task 13.19)`

#### Dependencies
- Blocks: Epic 5 Task 5.7 outreach

---

### Task 13.20 — [No-op reference] Premium perception at $2-3/mo

**Source:** A13 finding "Premium perception at $2-3/mo — Voice and typography reads more polished than most $2-3/mo apps. Reasonable price for perceived quality. Icon weakness is the one drag on premium feel."
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Once Task 13.1 (icon) lands, premium perception is unlocked. Preserve voice + typography assets.

#### Implementation approach
1. No direct action here — icon fix in Task 13.1 is the lever. Document this link in brand guide.
2. Optional: pricing A/B between $2.99, $3.99, and $4.99/mo to test whether higher price raises perceived quality (Epic 5 Task 5.14).

#### Acceptance criteria
- [ ] Link between icon quality and premium perception documented in brand guide
- [ ] Cross-reference Epic 5 Task 5.14 pricing test

#### Dependencies
- Blocks: none (reference)
- Blocked by: Task 13.1

---

### Task 13.21 — [No-op reference] "Retraq™" usage rules preserved

**Source:** A13 finding "'Retraq™' usage rules codified (where to use ™, when not to)" · **Rating:** Strong
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Professional trademark discipline. Preserve.

#### Implementation approach
1. Brand guide `retraq-branding-guide.md:214-230` already defines rules — do not change.
2. Once Task 13.6 (trademark filing) completes and mark is registered, switch ™ to ® in contexts where registration is complete (CIPO for Canada, USPTO for US). This is Task 13.6's follow-on.
3. Document the switch process in brand guide: "When CIPO registration completes (~18 months), add ® for Canadian marketing. When USPTO registration completes, add ® for US marketing. Do not use ® in jurisdictions without registration."

#### Acceptance criteria
- [ ] Brand guide cross-references Task 13.6 for ™ → ® transition
- [ ] Commit pushed with `docs(brand): trademark symbol usage rules (Task 13.21)`

#### Dependencies
- Blocked by: Task 13.6 (for the ® transition event)

---

## Epic 13 summary

| Priority | Count |
|---|---|
| P0 | 1 |
| P1 | 4 |
| P2 | 2 |
| P3 | 14 |
| **Total** | **21** |

| Tier | Count |
|---|---|
| v1 launch | 5 |
| v1.1 | 2 |
| v2 | 1 |
| backlog | 0 |
| no-op | 13 |

**Single biggest lever:** Task 13.1 — new app icon. Everything else in this epic preserves or catalogs existing strong assets.

**Commit prefixes:** `feat(brand):` for new visual assets, `chore(brand):` for asset replacements, `docs(brand):` for guideline changes. All commits reference Task 13.N.

**External budget:** ~$1000-4500 CAD across 13.1 icon design (~$500-2500), 13.6 trademark filings (~$500-2000), 13.6 trademark attorney (optional, $500-1500). Everything else is internal writing work.
