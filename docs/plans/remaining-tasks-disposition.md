# Remaining tasks — disposition & unblock paths

**Status:** Active reference · **Last updated:** 2026-04-18
**Snapshot:** 241 of 260 plan tasks closed · 19 remaining

After the 2026-04-18 implementation sweep, every remaining plan
task falls into one of three categories: **external-blocked**,
**v2 explicit scope**, or **backlog polish**. This doc maps each
to its gating condition + what would unblock it.

None of the 19 are blocked on me writing code. They're blocked
on the user engaging a vendor, a v1 scope decision being
revisited, or post-launch bandwidth.

---

## External-blocked (5 tasks)

Each needs a user action on a B-# blocker from
[`docs/external-blockers.md`](../external-blockers.md).

| Task | Blocker | What unblocks it | Cost estimate |
|---|---|---|---|
| **10.7** Play Store internal track deployment | B-4 Play Console + B-12 icon | Enrol in Google Play Console ($25 USD one-time); finish icon so the store record has an icon to display | $25 USD + icon budget |
| **12.10** Subscription disclosure UI (5 jurisdictions) | B-2 RevenueCat account | Create RevenueCat account (free up to $2.5k MTR); create products for `retraq_pro_lifetime` and `retraq_cloud_monthly`; then I can wire the paywall UI with the Apple/Google/Cal.ARL/EU-CRD/Quebec-CPA disclosure copy | Free tier OK; counsel review budget $1000–2500 CAD |
| **12.14** Independent WCAG 2.2 AA audit | B-11 accessibility auditor | Engage Deque / TPG / Accessible Web / IDRC (Canadian). Typical 2-week turnaround | $3000–10000 CAD |
| **13.1** Redesign app icon (Q-motif) | B-7 + B-12 icon designer | Hire icon designer (Fiverr Pro, 99designs, personal network). 3 concepts at 192×192, 4 colour variants, 2 revision rounds. Export matrix for iOS + Android adaptive + monochrome | $500–2500 CAD |
| **13.4** Logo small-size silhouette test | depends on 13.1 | Export the new icon at 24/40/60/96/192 dp; 4×6 grid test against 12 competitor icons; 5–10 friend testers | $0 (volunteer feedback), blocks on 13.1 |

**Total external cost to unblock:** ~$5000–16000 CAD + $25 USD
one-time. Most of that is the WCAG audit + counsel review; icon
+ screenshots + trademarks total ~$2000–7500 on their own.

---

## v2 explicit scope (7 tasks)

Features deliberately deferred out of v1 and v1.1 per the April
2026 feature-decisions memo. Reintroducing any of them pre-launch
would violate the "ship the simplest thing that works" principle.
v2 unlocks them naturally once the v1 activation signal tells us
what to build next.

| Task | What it is | v2 gating condition |
|---|---|---|
| **3.11** Per-entry visibility + role ACLs for family sharing | Schema change adding `entries.visibility` enum + `users.role` column | Requires Task 12.12 caregiver legal framework first (B-10 counsel engagement, $5–15k CAD) |
| **7.13** "Easy-tap" calendar mode (≥48dp cells) | Larger-cell calendar variant for motor-impairment users | Post-launch WCAG audit (Task 12.14) surfaces the actual user-pain threshold |
| **7.17** RTL locale + `EdgeInsets.only` audit | Add Arabic / Hebrew support; sweep for hardcoded `left`/`right` EdgeInsets | Ship English-first v1; v2 once one non-LTR locale is in scope |
| **8.2** userId filtering + `idx_journal_user_date` | Schema change — every query joins on `user_id` | Required for multi-user (caregiver / family) v2. Safe no-op today since single-user. |
| **8.3** `updatedAt`, `deletedAt`, `serverId` UUID columns | Schema change enabling cloud-sync soft-delete + conflict resolution | Required for cloud sync v2. Depends on Task 3.10 zero-knowledge envelope design |
| **8.4** Per-user settings row (drop id=1 singleton) | Schema change — `user_settings` becomes `(user_id, key, value)` | Required for multi-user settings v2 |
| **10.13** Dev / staging / prod product flavors | Flutter flavors with `--flavor dev` / `--flavor prod` configs | Needed when staging TestFlight track + prod App Store coexist; v2 pre-launch stays single-flavor |

**What would change this list:** a specific v2 roadmap decision.
Today v1 + v1.1 fully cover the product; v2 items are only
unblocked by a new product call.

---

## Backlog polish (7 tasks)

Nice-to-have improvements with no launch pressure. Each can be
done post-launch based on real-user signals; doing them pre-
launch trades time for marginal quality.

| Task | What it is | When to revisit |
|---|---|---|
| **6.21** Golden / visual regression tests | Flutter `goldenFileComparator` baseline; captures pixel-perfect snapshots of key screens | When Epic 13 icon redesign + Task 13.2/13.3 palette changes stabilise (the golden baseline becomes useful once the visual language is locked) |
| **6.23** Fuzz / property tests via `glados` | Property-based coverage for serialisers (export/import round-trip, date math) | Post-launch if a real bug surfaces that would have been caught by fuzzing. Current unit coverage is already 630+ tests at 48% filtered. |
| **8.8** Synchronous splash if DB init regresses | Fallback path if `DatabaseService.init()` ever slows past 200ms | If real-user cold-start metrics regress post-launch (Sentry performance transactions) |
| **8.9** Signature-cache monthly watches if hot | Extends the Task 8.15 signature-cache pattern to `watchMonthEntries` | If Recap month-view rebuild thrash shows up in Sentry perf |
| **8.12** Cache SQLCipher-probe result | Tiny perf win — memoize the "is SQLCipher available" check after first call | Cold-start polish; Task 8.8's signal would also cover this |
| **10.10** Port build scripts to Dart / add `.ps1` | Replace bash shell scripts with Dart + PowerShell equivalents | Windows developer friction (user is on Windows — bash-on-git-bash works today but a native Dart port is cleaner) |
| **10.11** `ios-podfile` ecosystem for Dependabot | Dependabot bundler ecosystem watching `ios/Gemfile` once fastlane is wired | Depends on Task 10.2 iOS TestFlight automation (blocked on B-3 Apple Developer) |

---

## What "ship v1" actually needs now

Strip everything else away — the launch-gating surface after
today's work is:

1. **B-3 Apple Developer Program** ($99 USD/yr)
2. **B-4 Google Play Developer** ($25 USD one-time)
3. **B-5 Canadian business entity** ($0–300 CAD; privacy policy
   controller disclosure depends on this)
4. **B-12 Icon designer** ($500–2500 CAD)
5. **B-17 Screenshot vendor / tool** ($0 with Figma + simulators;
   $15–50/mo for AppLaunchpad-style tooling)

That's it. Trademarks (B-15/B-16) and WCAG audit (B-11) are
highly recommended for a polished launch but not strictly gating
— ™ without ® is legal, and WCAG audit can be post-launch if the
automated testing + Task 7.x contrast + a11y sweep work holds up.

All the code work Agent 1–13 recommended pre-launch is done.

---

## Update protocol

When one of these 19 items is actually executed (external
blocker lands, v2 kicks off, backlog item surfaces), update
this doc in the same commit that closes the task. Each row
should grow a "closed by" column rather than disappear — the
history of the disposition is itself valuable planning context.

If a new plan task is added post-2026-04-18 (e.g., v1.1 or v2
scope expansion), append it below the appropriate section with
its own disposition.
