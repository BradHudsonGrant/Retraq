# Epic 12 — Legal & Compliance

Source: review-2026-04-16.md §Agent 12
Total tasks: 16

Developer is Canada-based (PIPEDA jurisdiction). App is currently local-only with planned expansion to cloud AI recaps, RevenueCat subscriptions, and caregiver/Retraq Care tier (per April 2026 feature decisions: Retraq Care is dropped from v1 but retained in v2 scope per user instruction). Every Ontario choice-of-law clause must accommodate non-Canadian consumers. All tasks below include explicit guidance on which items self-attestation covers vs. which require outside privacy counsel.

---

### Task 12.1 — Preserve no-network posture with a CI integration guard

**Source:** A12 finding "No network calls; data truly local; SQLCipher/AES-256 with FLAG_SECURE and PrivacyInfo.xcprivacy present" · **Rating:** Compliant
**Regulations:** GDPR Art. 5(1)(f) integrity & confidentiality, PIPEDA Principle 7 Safeguards
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
The app's strongest legal defense is "no data leaves the device." This is currently a code property, not a tested invariant — a future dependency upgrade could silently pull in an analytics SDK that pings home.

#### Root cause
No automated test asserts the absence of HTTP/socket calls during app cold-start, save flow, or export. Static lint alone cannot detect all forms of outbound traffic (e.g., a dependency's transitive HTTP call).

#### Files touched
- `integration_test/no_network_test.dart` (new)
- `.github/workflows/ci.yml` — add `integration_test/no_network_test.dart` to the integration test matrix
- `pubspec.yaml` (dev_dependencies) — no new deps; use Flutter's `HttpOverrides`

#### Implementation approach
1. Install a global `HttpOverrides` in the integration test that throws if any HTTP client is constructed:
   ```dart
   class ThrowingHttpOverrides extends HttpOverrides {
     @override
     HttpClient createHttpClient(SecurityContext? context) =>
       throw StateError('Unexpected HTTP client construction during no-network test');
   }
   ```
2. In the test body, drive the full onboarding → first entry → export round-trip. Any HTTP client creation crashes the test.
3. Document the test as a compliance artifact in `docs/legal/no-network-attestation.md` for privacy-policy footnote link.

#### Counsel coordination
- Self-attestable. No counsel needed.

#### Acceptance criteria
- [ ] `integration_test/no_network_test.dart` runs in CI
- [ ] Test exercises cold-start, write entry, read recap, export to share sheet — all without HTTP
- [ ] `docs/legal/no-network-attestation.md` published
- [ ] Commit pushed to `BradHudsonGrant/Retraq` with `legal: CI guard enforcing no-network invariant (Task 12.1)`

#### Dependencies
- Blocks: Task 12.2 (privacy policy text can now cite the test)
- Blocked by: none
- External: none

---

### Task 12.2 — Rewrite privacy policy controller disclosure + supervisory authority contacts

**Source:** A12 finding "Privacy policy matches the code... Last Updated 2026-03-29; covers Access/Delete/Portability" · **Rating:** Compliant (but disclosure completeness can be improved)
**Regulations:** GDPR Arts. 13-15, PIPEDA Principle 8 Openness, CCPA §1798.130, Quebec Law 25 s. 8.1
**Priority:** P1 · **Effort:** M · **Tier:** v1 launch

#### Problem
Privacy policy text is good but lists "Independent developer" as the controller — GDPR Art. 13(1)(a) requires an identifiable entity and contact. Supervisory-authority complaint routes (CNIL, ICO, OPC, CAI Quebec, California AG) are not listed.

#### Root cause
Policy was drafted before a formal Canadian business entity was registered.

#### Files touched
- `lib/legal/privacy_policy.dart` — rewrite §§Controller, §Contact, §Your Rights
- `lib/l10n/app_en.arb` — localize new strings
- `docs/legal/privacy-policy-source.md` — authoritative text with revision history
- `lib/services/consent_version.dart` (or equivalent) — bump consent version to trigger re-consent for existing users

#### Implementation approach
1. Register or identify a Canadian controller entity (sole prop / incorporated). User is in Canada — recommend CIPO business registration or sole-prop assumed name. Work with the user's accountant/lawyer; does not block code.
2. Update policy with:
   - Controller: `<Entity Name>, <mailing address>, email: privacy@retraq.app`
   - DPO / privacy officer: `<name or role-inbox>`
   - Complaint authorities with links: OPC (Canada), CAI (Quebec), CNIL (France/EU fallback), ICO (UK), California AG (CCPA)
3. Add paragraph describing the no-network CI test (Task 12.1) as a compliance artifact.
4. Bump `ConsentVersion` so `lib/main.dart:136-217` reconsent flow fires.
5. Translate new strings (EN-first; localize queue for future languages).

#### Counsel coordination
- Self-attestable if using public templates. Recommend one-pass review by Canadian privacy counsel before global launch (est. $500-1500 CAD one-time).

#### Acceptance criteria
- [ ] Controller entity, DPO, mailing address, and supervisory authorities listed
- [ ] Re-consent flow triggers for existing users on next launch
- [ ] Screenshots of new policy in `docs/legal/policy-screenshots/` for store-review artifact
- [ ] Commit pushed with `legal: controller disclosure + supervisory authorities in privacy policy (Task 12.2)`

#### Dependencies
- Blocks: Task 12.11 (Canadian mailing address also needed for CASL)
- Blocked by: Task 12.1 (CI attestation)
- External: Canadian business entity registration (user action)

---

### Task 12.3 — Country-aware age gate (13/14/16 thresholds)

**Source:** A12 finding "Age gate is binary (13+) but not COPPA-hardened" · **Rating:** At Risk
**Regulations:** COPPA 16 CFR 312, Quebec Law 25 (age 14), GDPR Art. 8 (13-16 depending on member state), FTC Feb 2026 COPPA policy statement
**Priority:** P0 · **Effort:** M · **Tier:** v1 launch

#### Problem
`lib/screens/onboarding/age_gate_page.dart` asks "Are you 13 or older?" globally. This under-protects users in Quebec (14), Germany/Netherlands/France/Italy (16 under GDPR Art. 8 national choices), and misses parental-consent triggers for ADHD users under the local minimum.

#### Root cause
A single hardcoded threshold. No locale-aware logic; no parental-consent flow.

#### Files touched
- `lib/screens/onboarding/age_gate_page.dart` — country-aware threshold
- `lib/services/locale_age_threshold.dart` (new) — decision table + helper
- `lib/l10n/app_en.arb` — new copy for age-gate prompt per threshold
- `lib/screens/onboarding/parental_consent_page.dart` (new) — shown if user self-attests under local minimum but over 13
- `test/screens/onboarding/locale_age_threshold_test.dart` (new)

#### Implementation approach
1. Decision table (locale → min self-attest age):
   ```dart
   const _thresholds = {
     'QC': 14,     // Quebec Law 25
     'DE': 16, 'NL': 16, 'FR': 16, 'IT': 16,
     'LU': 16, 'IE': 16, 'RO': 16, 'HU': 16,
     'AT': 14, 'BG': 14, 'CY': 14, 'LT': 14, 'ES': 14,
     'BE': 13, 'DK': 13, 'EE': 13, 'FI': 13, 'LV': 13, 'MT': 13, 'PL': 13, 'PT': 13, 'SE': 13, 'SK': 13, 'CZ': 13,
     'US': 13, 'CA': 13, 'GB': 13, 'AU': 13, 'NZ': 13,
   };
   int ageThresholdFor(Locale locale, String? region) =>
     _thresholds[region ?? locale.countryCode ?? 'US'] ?? 13;
   ```
2. Age gate reads `WidgetsBinding.instance.platformDispatcher.locale` and passes to helper. For Quebec specifically, detect `fr_CA` or IP-hint (manual user "I'm in Quebec" toggle acceptable).
3. If user self-attests under threshold but ≥13, route to `ParentalConsentPage` with a blocking checklist (parent email required before unlock). Store evidence in `users.parentalConsentAt`.
4. If user self-attests under 13, show the existing age-deny screen; persist denial flag to secure storage (already implemented).
5. Do NOT IP-geolocate — use device locale + optional "I'm in Quebec" self-declaration. Less accurate, but avoids geo-IP compliance overhead.

#### Counsel coordination
- Recommend counsel review of parental-consent flow copy. Threshold table is public-domain regulatory fact.

#### Acceptance criteria
- [ ] Threshold decision table tested for 30+ country codes
- [ ] Parental-consent flow blocks entry-to-first-journal for under-threshold-but-over-13 users
- [ ] No under-13 user can pass age gate
- [ ] Commit pushed with `legal(age-gate): country-aware thresholds + parental consent (Task 12.3)`

#### Dependencies
- Blocks: Task 12.10 (subscription disclosure won't ship until age gate hardens), Task 12.12 (caregiver tier)
- Blocked by: none
- External: Counsel review of parental-consent copy (est. $500 one-time)

---

### Task 12.4 — Explicit Art. 9 consent gate before cloud AI ships

**Source:** A12 finding "Free-text entries almost certainly contain Article 9 health data" · **Rating:** At Risk
**Regulations:** GDPR Art. 9(2)(a) explicit consent, PIPEDA sensitive PI standard, HIPAA (not applicable — we are not a covered entity)
**Priority:** P1 · **Effort:** M · **Tier:** v1.1

#### Problem
Journal entries may contain health data (meds, mood scores, symptoms, therapy notes). For local-only processing, Art. 9(2)(e) (data made public by the data subject to themselves — a stretch but defensible) plus Art. 9(2)(h) (health care by patient) cover today. The moment cloud AI ships, explicit Art. 9(2)(a) consent becomes mandatory, distinct from general ToS.

#### Root cause
Today's consent flow is general-purpose "Terms, Privacy, Health Disclaimer" — not Art. 9-specific.

#### Files touched
- `lib/screens/onboarding/consent_page.dart` — add 4th checkbox when cloud AI tier is available
- `lib/l10n/app_en.arb` — new explicit-consent copy
- `lib/services/user_repository.dart` — persist `art9ConsentAt` and `art9ConsentVersion`
- `lib/services/subscription_service.dart` (from Epic 4) — gate cloud-AI feature unlock on Art. 9 consent flag
- `docs/legal/art9-consent-rationale.md` (new)

#### Implementation approach
1. When cloud AI tier becomes available, add a 4th consent row: "I understand my journal entries may contain health-related information, and I explicitly consent to them being processed by Anthropic/Google/OpenAI (whichever model backs the premium tier) solely to generate my weekly recap."
2. Consent is **revocable** — provide a toggle in Settings → Data. Revoking disables cloud AI and deletes any cached server-side state (documented as 0-retention via backend DPA).
3. Log explicit consent in a dedicated audit record with timestamp + consent text hash.
4. Do NOT ship this checkbox in v1 — it should appear only when the subscription flips on.

#### Counsel coordination
- Mandatory counsel review before cloud AI ships. Art. 9 boundary work is not self-attestable. Budget: $2000-5000 CAD.

#### Acceptance criteria
- [ ] Explicit consent row appears ONLY when cloud-AI tier is in scope
- [ ] Consent record stored with version + timestamp
- [ ] Revocation disables cloud AI and purges server-side caches
- [ ] Commit pushed with `legal(gdpr): Art. 9 explicit consent gate for cloud AI (Task 12.4)`

#### Dependencies
- Blocks: Task 4.7 (Tier 2/3 AI recap feature unlock)
- Blocked by: subscription infrastructure (Epic 4)

---

### Task 12.5 — [No-op reference] Health claims copy already conservative

**Source:** A12 finding "Health claims are conservatively worded; explicit 'not a medical device' in three places; 988 Lifeline referenced" · **Rating:** Compliant
**Regulations:** Apple 1.4.1/5.1.1(ix), Google Play Health Content (Jan 2026 enforcement)
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Already compliant. Preserve posture.

#### Implementation approach
1. Add a permanent lint / grep guard in CI: forbid the strings "cures", "treats", "diagnoses", "FDA-approved", "HIPAA-compliant", "clinically proven" in `lib/` and `docs/`:
   ```bash
   rg -i 'cures|treats|diagnoses|FDA[- ]?approved|HIPAA[- ]?compliant|clinically proven' lib/ docs/ && exit 1 || exit 0
   ```
2. Document the list in `docs/legal/forbidden-claims.md` so future copy changes respect the boundary. Tighten during Alzheimer's/dementia market exploration (v2).

#### Acceptance criteria
- [ ] CI grep guard in place
- [ ] `docs/legal/forbidden-claims.md` published
- [ ] Commit pushed with `legal(claims): forbidden-claims lint guard (Task 12.5)`

#### Dependencies
- None

---

### Task 12.6 — Add mandatory-local-consumer-law carve-out to Terms

**Source:** A12 finding "Terms of Service governed by Ontario law; includes limitation of liability and data-loss disclaimer" · **Rating:** At Risk
**Regulations:** Quebec C.c.Q. Art. 1437, EU Unfair Terms Directive 93/13/EEC, UK Consumer Rights Act 2015, California Civ. Code §1668, Rome I Art. 6
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
Ontario choice-of-law in `lib/legal/terms_of_service.dart:47-49` is not enforceable against Quebec, EU, UK, or California consumers. Limitation-of-liability clauses have limited effect under EU Unfair Terms Directive.

#### Files touched
- `lib/legal/terms_of_service.dart:47-49` — add carve-out
- `lib/l10n/app_en.arb` — localize amendment
- `docs/legal/tos-source.md` — authoritative text

#### Implementation approach
1. Insert after the Ontario-law clause:
   > "The foregoing choice of law and limitation of liability do not derogate from any mandatory consumer protection law applicable to you in your country or province of residence. Where such mandatory protections are more favorable to you, they prevail."
2. Add jurisdiction-specific paragraph for Quebec: "Residents of Quebec retain rights under the Consumer Protection Act (C.P.A.) and the Civil Code of Quebec."
3. Bump consent version.

#### Counsel coordination
- Recommended counsel pass to ensure the carve-out is bulletproof. $500-1000.

#### Acceptance criteria
- [ ] Carve-out paragraph present
- [ ] Consent version bumped
- [ ] Commit pushed with `legal(tos): mandatory local consumer law carve-out (Task 12.6)`

#### Dependencies
- Blocked by: Task 12.2 (consent-version bump flow)

---

### Task 12.7 — [No-op reference] Consent records with version bumps already implemented

**Source:** A12 finding "Consent records tracked with version bumps and re-consent flow on legal-doc change" · **Rating:** Compliant
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Excellent pattern. Preserve.

#### Implementation approach
1. Extend the schema (in a future migration) to support per-consent-type granularity if not already supported: separate flags/timestamps for `privacyConsent`, `termsConsent`, `healthConsent`, future `art9Consent` (Task 12.4), future `crashReportingConsent` (Task 1.2).
2. Verify existing schema supports this — current `user_repository.dart:13-16` appears to. If so, documented as intentional.

#### Acceptance criteria
- [ ] Per-consent-type granularity documented in `docs/legal/consent-schema.md`
- [ ] Commit pushed with `docs(legal): document consent-version schema (Task 12.7)`

---

### Task 12.8 — [No-op reference] Data-export satisfies GDPR Art. 20

**Source:** A12 finding "Data export produces JSON and plain text, includes entries+settings+consent history" · **Rating:** Compliant
**Regulations:** GDPR Art. 20, Law 25 data-mobility right (Sept 2024)
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Compliant. Preserve.

#### Implementation approach
1. Publish the export JSON schema at `docs/legal/export-schema-v1.md` — required by Law 25 portability spirit and gives users/competitors an importer target.
2. Commit the schema alongside the code.

#### Acceptance criteria
- [ ] `docs/legal/export-schema-v1.md` published
- [ ] Commit pushed with `docs(legal): publish GDPR-portability export schema (Task 12.8)`

---

### Task 12.9 — Verify Delete-All-Data is irrecoverable

**Source:** A12 finding "'Delete All Data' option present and covers consent records" · **Rating:** Compliant
**Regulations:** GDPR Art. 17, PIPEDA retention limitation
**Priority:** P2 · **Effort:** S · **Tier:** v1 launch

#### Problem
Compliant today. Add a regression test proving irrecoverability so future refactors don't silently break it.

#### Files touched
- `test/services/delete_all_data_test.dart` (new)
- `docs/legal/right-to-be-forgotten.md` (new)

#### Implementation approach
1. Integration test: onboard a user, write entries, trigger Delete All Data, then attempt to read raw SQLCipher file bytes — assert entries not recoverable (post-delete the file should be absent or overwritten).
2. Verify `allowBackup=false` is honored and the file cannot be recovered from Android auto-backup.
3. Document the delete flow in `docs/legal/right-to-be-forgotten.md` for user-facing transparency.

#### Acceptance criteria
- [ ] Integration test asserts post-delete file absence
- [ ] Manifest `allowBackup=false` verified in CI
- [ ] `docs/legal/right-to-be-forgotten.md` published
- [ ] Commit pushed with `legal(deletion): verify delete-all-data irrecoverability (Task 12.9)`

#### Dependencies
- Blocks: none

---

### Task 12.10 — Subscription disclosure UI (Apple 3.1.2(a), Google Play, Cal. ARL, EU CRD, Quebec C.P.A.)

**Source:** A12 finding "No subscription disclosure UI; no auto-renewal text; no price period statement" · **Rating:** Non-Compliant (blocker before paid tiers)
**Regulations:** Apple 3.1.2(a), Google Play Subscriptions Policy, Cal. Automatic Renewal Law §17602, EU Consumer Rights Directive 2011/83 (14-day cooling-off), Quebec C.P.A. ss. 230-231
**Priority:** P0 · **Effort:** M · **Tier:** v1.1 (when paid tiers ship)

#### Problem
No paywall exists yet; before shipping RevenueCat/IAP, every jurisdiction's subscription disclosure must be present at the point of purchase.

#### Files touched
- `lib/screens/paywall_screen.dart` (new, from Epic 4)
- `lib/l10n/app_en.arb` — required disclosure strings
- `lib/legal/terms_of_service.dart` — subscription section
- `docs/legal/paywall-disclosure-matrix.md` (new) — jurisdiction → required text

#### Implementation approach
1. Paywall must show, adjacent to the subscribe button:
   - Subscription title, length, price (e.g., "Retraq Premium — monthly, $2.99 CAD")
   - "Subscription auto-renews unless cancelled 24 hours before period ends"
   - "Payment is charged to your App Store / Google Play account on confirmation"
   - Link to Terms + Privacy Policy
   - "Manage or cancel in your App Store subscriptions / Google Play subscriptions"
   - For California users: one-tap cancellation link
   - For EU users: 14-day cooling-off acknowledgement with waiver option
   - If offering a free trial: "After trial, subscription begins at [price]. Cancel at least 24h before trial ends to avoid charges."
2. RevenueCat paywall templates cover most of this — verify each region-specific string is present.
3. Jurisdiction-specific copy lives in `app_en.arb` with fallbacks.
4. Full matrix in `docs/legal/paywall-disclosure-matrix.md`:
   | Jurisdiction | Required text | Source |
   |---|---|---|
   | Apple (global) | auto-renew clause, manage link | App Store Review 3.1.2(a) |
   | Google Play | auto-renew + cancel | Google Play Subscriptions Policy |
   | California | one-tap cancel | Cal. ARL §17602 |
   | EU | 14-day cooling-off | EU Consumer Rights Directive |
   | Quebec | retenue du consommateur rights | Quebec C.P.A. 230-231 |

#### Counsel coordination
- Counsel review mandatory before first paid submission. Budget: $1000-2500. After initial review, subsequent tier additions are lightweight updates.

#### Acceptance criteria
- [ ] Paywall passes Apple review mock (1.4.1, 3.1.2) checklist
- [ ] Paywall passes Google Play subscription policy checklist
- [ ] California one-tap cancel present
- [ ] EU 14-day acknowledgement present
- [ ] Screenshots of paywall archived in `docs/legal/paywall-screenshots/`
- [ ] Commit pushed with `legal(paywall): subscription disclosure UI for 5 jurisdictions (Task 12.10)`

#### Dependencies
- Blocks: RevenueCat rollout (Epic 4)
- Blocked by: Task 12.3 (age gate must be hardened before paid), Task 4.15 (RevenueCat wiring)
- External: Counsel review; Apple App Store Connect subscription setup; Google Play Console subscription setup

---

### Task 12.11 — Disclose Canadian business entity + physical mailing address

**Source:** A12 finding "No Ontario/Canada business entity or P.O. box disclosed in policy" · **Rating:** At Risk
**Regulations:** PIPEDA s. 5(3) accountability, Quebec Law 25 accountability, CASL s. 6 (physical address in commercial electronic messages)
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
"contact@retraq.app" alone is insufficient. CASL requires a physical mailing address in all commercial electronic messages — including in-app review nudges and reconsent flow emails if any.

#### Files touched
- `lib/legal/privacy_policy.dart` (covered by Task 12.2)
- `lib/legal/terms_of_service.dart`
- Email footers (if any; currently none — verify)
- `docs/legal/entity-disclosure.md` (new)

#### Implementation approach
1. Register a sole-proprietorship or incorporate at CIPO. User can use home address or a virtual office (iPostal1, Earth Class Mail, etc.).
2. Publish `<Entity Name>, <Address>, <Postal Code>, Canada` in both legal docs.
3. Add footer to any future commercial email templates.

#### Counsel coordination
- Not needed for basic entity registration. Use CIPO forms or a registered-agent service.

#### Acceptance criteria
- [ ] Entity + address present in Privacy Policy and ToS
- [ ] Commit pushed with `legal(entity): disclose Canadian entity + address (Task 12.11)`

#### Dependencies
- Blocked by: business registration (user action)
- External: CIPO or provincial registration

---

### Task 12.12 — Caregiver / Retraq Care tier pre-build legal framework (v2)

**Source:** A12 finding "No DPA/controller analysis for Retraq Care caregiver tier; capacity/substitute-decision not addressed" · **Rating:** Non-Compliant (for planned feature)
**Regulations:** GDPR Arts. 26-28 (joint controllers / processors), PIPEDA s. 7(1) consent, Ontario SDA 1992 (Substitute Decisions Act), Quebec Curatelle (new Tutelle regime 2022), US state elder-abuse mandatory-reporting laws (varies by state)
**Priority:** P0 (for v2 feature gate) · **Effort:** XL · **Tier:** v2

#### Problem
Sharing entries with family members of users with early Alzheimer's / dementia triggers capacity/consent questions, possible mandatory elder-abuse reporting obligations, and turns the single-user app into a multi-party data-sharing platform. **Cannot ship any caregiver code until these are resolved.**

#### Files touched
- `docs/legal/caregiver-pre-build-checklist.md` (new, authoritative)
- `docs/legal/caregiver-dpa-template.md` (new)
- `docs/legal/caregiver-controllership-model.md` (new)

#### Implementation approach
Pre-build legal checklist (all items must be satisfied before writing any caregiver-feature code):

1. **Controllership decision** — is the caregiver a joint controller under GDPR Art. 26, a processor under Art. 28, or an "authorized representative" acting under substitute-decision authority? Document the chosen model in writing. Recommend: **"user remains data subject; caregiver is a delegated recipient granted read-only access via user-initiated invite,"** which avoids joint-controller DPA but still requires explicit user consent at time of invite and re-consent at version bumps.

2. **Capacity attestation flow** — for users with declining capacity, how does the app handle cases where the user cannot meaningfully consent? Options:
   - Require user capacity at setup time; once access granted, ongoing revocation via caregiver-bypass panic button (user-initiated only).
   - Require POA upload or clinician sign-off for users flagged as "reduced capacity." **Hard problem.** Simpler: ship only to capacitated users; do not target clinically-diagnosed dementia in v2 launch.

3. **Medical device disclaimer** — explicitly state app is NOT a telehealth, medical-monitoring, aging-in-place, or clinical-decision-support device. Required under Apple 1.4.1, Google Play Health Content, and FDA (US) / Health Canada.

4. **Caregiver Terms of Service** — separate ToS for caregiver accounts. Include hold-harmless for data accuracy ("the user may choose not to journal or may journal inaccurately; the caregiver accepts this"). Limit liability. Choice-of-law with carve-outs (see Task 12.6).

5. **Mandatory elder-abuse reporting** — review jurisdiction-by-jurisdiction. In some US states, a platform that receives credible reports of elder abuse may become a "mandatory reporter." This is a hard problem. Likely conclusion: **app is not a reporter; caregiver is responsible for their own reporting obligations; app surfaces no automated alerts that could trigger reporter status.**

6. **Cross-border data flow** — caregivers in different jurisdictions than the user. GDPR Ch. V applies for EU users with non-EU caregivers. Law 25 requires PIA for cross-border transfer of Quebec PI.

7. **Data Processing Agreement (DPA)** — template in `docs/legal/caregiver-dpa-template.md`. If joint-controller model chosen, DPA is mandatory under GDPR Art. 26.

8. **Children / incapacitated adults** — explicit exclusion. No caregiver monitoring of children without full parental consent flow and documentation.

#### Counsel coordination
- **Mandatory** privacy/health-law counsel engagement before writing any caregiver code. Budget: $5000-15000 CAD for initial framework. Counsel must sign off on: controllership model, capacity flow, mandatory-reporter analysis, DPA template.

#### Acceptance criteria
- [ ] `docs/legal/caregiver-pre-build-checklist.md` signed off by counsel
- [ ] Controllership model decision documented
- [ ] Capacity flow decision documented
- [ ] Mandatory-reporter analysis documented
- [ ] DPA template reviewed by counsel
- [ ] Gate in planning: **no caregiver feature branch opened until checklist is complete**
- [ ] Commit pushed with `legal(caregiver): pre-build legal framework v2 (Task 12.12)`

#### Dependencies
- Blocks: **ALL** caregiver / Retraq Care code work
- Blocked by: Task 12.2 (entity disclosure), Task 12.4 (Art. 9 explicit consent as template)
- External: Mandatory outside counsel. Caregiver-feature development cannot begin without counsel sign-off.

---

### Task 12.13 — AI transparency disclosures for cloud AI recaps

**Source:** A12 finding "No AI-specific transparency when cloud AI tier ships" · **Rating:** At Risk (future)
**Regulations:** EU AI Act Art. 50 transparency (general-purpose AI provisions effective Aug 2026), CNIL AI guidance, OPC AI guidance, FTC Act §5 (deceptive AI claims)
**Priority:** P1 · **Effort:** M · **Tier:** v1.1 (ships with cloud AI)

#### Problem
When cloud AI recap tier ships, EU AI Act Art. 50 requires transparency: model provider disclosure, output labelling as AI-generated, data-transfer disclosure. Canada's AIDA died January 2025 so no federal Canadian law; Quebec Law 25 still requires PIA for cross-border PI.

#### Files touched
- `lib/screens/recap_screen.dart` — AI-generated badge on Tier 2/3 recaps
- `lib/services/recap_service.dart` — include model attribution metadata
- `docs/legal/ai-transparency.md` (new)
- `docs/legal/pia-quebec-cloud-ai.md` (new) — Privacy Impact Assessment

#### Implementation approach
1. Any AI-generated recap (Tier 2 Gemini Nano on-device AND Tier 3 cloud) displays:
   - "✨ AI summary — may contain inaccuracies. [What's this?]"
   - Tap "What's this?" opens a modal with: model provider (Google / Anthropic / OpenAI), whether processing is on-device or cloud, what data is sent (for cloud: user's entries for the week, nothing more), retention policy (0-retention via DPA with provider).
2. For Tier 3 cloud specifically:
   - Pre-send confirmation: "Your entries for the past 7 days will be sent to [provider] to generate your recap. Data is not retained beyond processing. [Cancel] [Generate recap]"
   - Consent stored per-recap (not just once).
3. Complete a PIA for Quebec Law 25 compliance (cross-border transfer of Quebec PI). Template in `docs/legal/pia-quebec-cloud-ai.md`. PIA is mandatory before cloud AI ships to Quebec users.
4. Tier 2 on-device (Gemini Nano) has no transfer; still labelled as AI but no cloud-transfer disclosure.

#### Counsel coordination
- Counsel review mandatory. Budget: $1500-3000. PIA template may be reused for future AI features.

#### Acceptance criteria
- [ ] AI badge on every AI-generated recap
- [ ] Pre-send confirmation for Tier 3
- [ ] PIA completed and filed
- [ ] Commit pushed with `legal(ai): AI Act Art. 50 transparency + Quebec PIA (Task 12.13)`

#### Dependencies
- Blocks: Tier 3 cloud AI launch (Epic 4 Task 4.7 future)
- Blocked by: Task 12.4 (Art. 9 consent infrastructure)
- External: Counsel review; DPA with chosen AI provider (Anthropic / Google / OpenAI)

---

### Task 12.14 — Commission independent WCAG 2.2 AA audit before EU release

**Source:** A12 finding "Accessibility claim in README not independently audited" · **Rating:** At Risk
**Regulations:** European Accessibility Act (EAA) in effect since 28 June 2025 (via EN 301 549, which references WCAG 2.1/2.2 AA), ADA Title III (US), ACA (Canada Accessibility Act), AODA (Ontario Accessibility for Ontarians with Disabilities Act)
**Priority:** P1 · **Effort:** L · **Tier:** v1 launch (before EU store availability)

#### Problem
Retraq markets to disabled users (ADHD, eventually Alzheimer's). README claims WCAG compliance but no independent audit exists. EAA penalties up to €100K or 4% revenue.

#### Files touched
- `docs/legal/accessibility-conformance-report.md` (new) — to be populated by auditor
- `lib/screens/settings_screen.dart` — add "Accessibility" section link to conformance report URL
- `docs/legal/accessibility-feedback-contact.md`

#### Implementation approach
1. Complete Epic 7 (internal a11y fixes) first. Then engage an independent WCAG auditor — recommend Deque, TPG, Accessible Web, or a Canadian firm like Inclusive Design Research Centre.
2. Scope: WCAG 2.2 AA + EN 301 549 + mobile-specific (touch targets, screen reader nav).
3. Receive audit report. Address findings (new tasks land in Epic 7).
4. Publish conformance report publicly; link from Settings.
5. Add "Accessibility feedback" contact: `accessibility@retraq.app` with SLA (48h ack, 2 weeks fix for reproducible WCAG failures).

#### Counsel coordination
- Not needed for audit itself; needed if a conformance dispute arises. Budget for audit: $3000-10000 CAD.

#### Acceptance criteria
- [ ] WCAG 2.2 AA audit completed and report published
- [ ] All reported failures addressed or documented with timeline
- [ ] Accessibility feedback contact live with SLA
- [ ] Commit pushed with `legal(a11y): publish independent WCAG 2.2 AA conformance (Task 12.14)`

#### Dependencies
- Blocks: EU store availability
- Blocked by: Epic 7 (internal a11y fixes complete)
- External: Audit vendor engagement

---

### Task 12.15 — [No-op reference] US export compliance flag correct

**Source:** A12 finding "US export compliance flag set correctly for standard encryption" · **Rating:** Compliant
**Regulations:** EAR 740.17(b)
**Priority:** P3 · **Effort:** XS · **Tier:** no-op

#### Problem
Correct. Preserve.

#### Implementation approach
1. Document the basis for the exemption claim at `docs/legal/ear-encryption-exemption.md` — brief note that SQLCipher AES-256 is standard cryptographic functionality under EAR 740.17(b) and no re-review is needed when TLS or RevenueCat is added (TLS + commercial crypto stay exempt).
2. Revisit only if custom cryptographic protocols are introduced.

#### Acceptance criteria
- [ ] `docs/legal/ear-encryption-exemption.md` documented
- [ ] Commit pushed with `docs(legal): document EAR 740.17(b) encryption exemption basis (Task 12.15)`

---

### Task 12.16 — Localize crisis contact numbers per locale

**Source:** A12 finding "No crisis language validation outside English locale" · **Rating:** At Risk
**Regulations:** None directly mandatory; liability exposure and user safety
**Priority:** P1 · **Effort:** S · **Tier:** v1 launch

#### Problem
`lib/l10n/app_en.arb:183` hardcodes 988 as the crisis line. 988 is US/Canada (since Nov 2023) but meaningless in UK, EU, AU, NZ, etc.

#### Files touched
- `lib/l10n/app_en.arb` — extract crisis-line contact to a locale-keyed map
- `lib/services/crisis_contacts.dart` (new)
- Future locale ARB files when added (`app_es.arb`, `app_fr.arb`, etc.)

#### Implementation approach
1. Decision table (locale/region → crisis contact):
   ```dart
   const crisisByRegion = {
     'US': {'number': '988', 'text': '988', 'name': '988 Suicide and Crisis Lifeline'},
     'CA': {'number': '988', 'text': '988', 'name': '988 Suicide Crisis Helpline (Canada)'},
     'GB': {'number': '116 123', 'text': null, 'name': 'Samaritans'},
     'AU': {'number': '13 11 14', 'text': '0477 13 11 14', 'name': 'Lifeline Australia'},
     'NZ': {'number': '1737', 'text': '1737', 'name': '1737 Need to Talk?'},
     'IE': {'number': '116 123', 'text': '50808', 'name': 'Samaritans / Text 50808'},
     'DE': {'number': '0800 111 0 111', 'text': null, 'name': 'Telefonseelsorge'},
     'FR': {'number': '3114', 'text': null, 'name': 'Numéro national de prévention du suicide'},
     'EU_FALLBACK': {'number': '112', 'text': null, 'name': 'European Emergency Number'},
     'INTL_FALLBACK': {'url': 'https://findahelpline.com', 'name': 'Find a helpline'},
   };
   ```
2. Replace the hardcoded 988 reference. Display the detected locale's contact; fall back to 'INTL_FALLBACK' with a clickable findahelpline.com link.
3. Test: locale DE → displays Telefonseelsorge; locale FR → 3114; locale XX → findahelpline URL.

#### Counsel coordination
- Not needed. Factual regulatory data.

#### Acceptance criteria
- [ ] Crisis-line table covers 20+ locales + international fallback
- [ ] Test asserts correct number per locale
- [ ] Commit pushed with `legal(crisis): localize crisis contact numbers (Task 12.16)`

#### Dependencies
- Blocked by: none
- External: none

---

## Epic 12 summary

| Priority | Count |
|---|---|
| P0 | 2 |
| P1 | 7 |
| P2 | 1 |
| P3 | 6 |
| **Total** | **16** |

| Tier | Count |
|---|---|
| v1 launch | 7 |
| v1.1 | 3 |
| v2 | 1 |
| backlog | 0 |
| no-op | 5 |

Commit prefixes for this epic: `legal:` for substantive legal changes, `docs(legal):` for legal documentation only. All commits reference Task 12.N.

Counsel budget estimate (one-time): ~$8000-22000 CAD across 12.2 ($500-1500), 12.4 ($2000-5000), 12.6 ($500-1000), 12.10 ($1000-2500), 12.12 ($5000-15000 for caregiver framework).
