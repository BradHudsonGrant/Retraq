# Analytics architecture — what Retraq measures (and what it deliberately does not)

> **Prime directive, restated:** Retraq's privacy policy promises "no
> analytics, no telemetry, no tracking of any kind"
> (see `lib/legal/privacy_policy.dart`). That promise is load-bearing.
> This document enumerates the one opt-in exit door and names the
> categories we have explicitly chosen **not** to measure.

## Default posture

- **Nothing leaves the device.** The app has no network client for
  analytics. The `no_network_invariant_test.dart` CI guard (Task 12.1)
  fails any build that adds an analytics HTTP dependency.
- Epic 11 plans local-only counters (`app_sessions`, `feature_counters`,
  `recap_feedback`) that stay in the encrypted SQLite database and are
  never emitted unless the user explicitly triggers the "Help improve
  Retraq" share sheet.

## The one exit door — opt-in "Help improve Retraq"

When the user taps **Settings → Help improve Retraq → Share
anonymized stats**, the app:

1. Runs `exportAnonymizedStats()` (Task 11.11) through the existing
   `ExportService` plumbing.
2. Scrubs every PII-adjacent field before serialization — entry text,
   titles, tags, labels, free-text settings, raw install timestamp,
   PIN hash, install UUID, file paths, photo attachments. See the
   shared spec in `docs/plans/epic-11-analytics.md` for the exact
   payload.
3. Hands a plain-JSON file to the OS share sheet. The app never
   opens a socket. The user picks the destination — email to
   themselves, drop in a Discord thread, or cancel.
4. Plaintext-export dialog (Task 3.9) requires a second confirm
   before the share-sheet is invoked.

## Not measured: caregiver (Task 11.9)

The Retraq Care / caregiver tier was deprioritized out of v1 (see
`memory/project_feature_decisions.md` and `implementation_plan.md`
Part III). Any metric designed for it would be dead code plus a
legal-surface risk — Agent 12's audit flagged substitute
decision-making and capacity attestation as unresolved dependencies
for that tier.

**Architectural commitment:**

- **No caregiver-specific counters.** No `caregiver_*` feature
  counters. No "dashboard opens", "invite sent", "viewer signed in"
  events. Nothing.
- **No shared-state timers.** No "time-between-subject-and-viewer-
  viewing" math. No cross-account read indicators.
- **Revisit only when:** Epic 12 Task 12.12 has delivered a signed
  DPA, the capacity-attestation UX is implemented, and the
  controllership model has been blessed by outside privacy counsel.
- **If a future PR attempts to add a `caregiver_*` counter**, reviewers
  should reject it referring to this document. A `tool/` lint rule
  that greps for the prefix is tracked as a tiny follow-up.

## Not measured: advertising / attribution

Retraq has zero ad SDKs, zero attribution libraries (no AppsFlyer /
Adjust / Branch), and zero install-source identifiers. The Play
Console "Advertising ID" permission is deliberately not requested.
iOS SKAdNetwork is not integrated. This posture is load-bearing for
the privacy positioning and is NOT up for negotiation without an
explicit roadmap change.

## Not measured: location, contacts, biometrics content

- Location: never read. No `ACCESS_FINE_LOCATION` / `LOCATION_WHEN_IN_USE`.
- Contacts: never read. No `READ_CONTACTS`.
- Biometric outcomes: the app uses `local_auth` to gate unlock but
  never stores or counts success/failure beyond the in-memory
  lockout controller's session state, which is written to secure
  storage and never exported.

## Not measured: "On This Day" via dedicated columns (Task 11.14)

Task 11.14 is a no-op by design. The engagement surface already
emerges from `entries.createdAt` — when the walker running for the
Stats → On This Day card finds an entry whose `(month, day)`
matches today minus N years, it surfaces. No dedicated
`on_this_day_viewed_at` column, no precomputed anniversary table,
no per-entry "surfaced_count" field.

**Architectural commitment (for future PR reviewers):**

- **Do NOT add `on_this_day_*` columns** to `entries`, `users`, or
  any new table. The data is derivable.
- **Do NOT add a schema-level anniversary precompute.** The
  existing on-demand query against `entries.date` plus
  `DateTime.subtract` is cheap enough — under 5ms on a 5-year DB.
- **Measurement**, when wired, lives on `FeatureCounterKey
  .onThisDayOpened` (Task 11.4's local `feature_counters` KV
  table). That single integer is enough to reason about
  engagement retention at the 12-month / 24-month install
  anniversary without any dedicated surface.
- **Rationale:** the simplest architectural commitment here is "we
  already have the data." Over-engineering this surface would
  either (a) duplicate `entries` for indexing gains we don't need,
  or (b) encode a product bet (the existence of On-This-Day as a
  top-level feature) that's still subject to the A5 competitive
  re-check (see [retraq-pro-bundle doc](./plans/v1.1-retraq-pro-bundle.md)).

This entry belongs alongside the caregiver commitment above: both
are "resist the instinct to add schema for a feature-we-don't-yet-
have" reminders.

## Not measured: cloud-AI prompts (v1 — deferred to v2)

Cloud AI Tier 3 is Part III scope (blocked on Art. 9 explicit consent,
AI Act transparency, Quebec PIA, and provider DPA — see Epic 12.4,
12.13). Until that lands, no prompts, tokens, or generated summaries
are sent anywhere. The v2 design must layer on top of the exit-door
share-sheet pattern, not replace it.

## Related documents

- `docs/plans/epic-11-analytics.md` — the 14-task analytics plan and
  "anonymized_stats_v1" JSON shape.
- `docs/plans/epic-12-legal.md` — consent + compliance tasks.
- `lib/legal/privacy_policy.dart` — user-facing promise this
  document guards.
- `CONTRIBUTING.md` — lists the no-network invariant alongside other
  PR rules.
