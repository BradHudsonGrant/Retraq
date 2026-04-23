# iOS App Store listing — Retraq

**Status:** Draft for v1 submission · **Task:** 9.2 · **Last updated:** 2026-04-16

This is the authoritative listing copy for iOS App Store Connect. A/B
variants and ASO alternatives live at the bottom. **Before submission**,
review against [`app/docs/external-blockers.md#b-17`](../external-blockers.md)
for required screenshots and [`app/docs/plans/epic-12-legal.md#task-12-8`](../plans/epic-12-legal.md)
for health-claim review.

## Name (30 chars)

Primary: **`Retraq — Remember Your Week`** (27 chars)

## Subtitle (30 chars)

Primary: **`Lost traq? Retraq.`** (18 chars) — brand pun; matches
App Store's brevity-is-memorable heuristic.

Alternative (for ASO if pun under-converts): **`Private memory journal`** (22 chars)

## Promotional Text (170 chars, updatable without review)

> Draw a blank when someone asks what you've been up to? Retraq is a
> tiny daily journal that remembers for you. Quick. Private. No accounts,
> no cloud, no tracking.

## Description (4000 chars max)

```
Retraq is a quick daily journal for people who want to remember their
week. Open. Write. Done.

--- Why Retraq ---

Most journal apps want your life story. Retraq just wants a sentence.

• Open the app — see a rotating question like "What's the TL;DR of
  today?" or "Any small win?"
• Type what comes to mind. Even one word is fine.
• Save. That's it. Your traq is kept safe on your phone.

No streaks to guilt you. No obligation to write every day. No
"7-day challenge." Miss a Tuesday? The app doesn't care. Drop a traq
when you can.

--- Remember your week ---

When your partner, friend, or therapist asks what you've been up to,
open Recap — your last week, highlighted and grouped by day, with a
search bar for specific words. Tap "On this day last year" to see
what past-you was doing on today's date.

--- For busy brains ---

Retraq is built for people with too many tabs open. Every design
choice asks: does this reduce cognitive load?

• Lexend font for reading fluency (research-backed).
• Bionic reading mode (optional).
• Typed-"DELETE" confirmation to prevent accidental wipe.
• Undo button after every save.
• 48dp touch targets. Reduce-motion respected. Large font support.
• Dark mode that really works.

--- Private by default ---

• All your traqs live on your phone — in an AES-256 encrypted
  database. Retraq makes zero network calls.
• No accounts. No analytics. No telemetry. No ads. Ever.
• Optional PIN lock + Face ID unlock with brute-force protection.
• Export your data anytime to JSON or plain text (GDPR-compliant
  portability).

--- What's in Retraq ---

• AM / PM or all-day quick entry
• Optional mood tracking (5-level scale, opt-in)
• Week / Month recap with full-text search
• "On this day last year" memory surfacing
• Stats: streaks, weekly trends, active weekday, mood trends
• Tablet two-pane layout
• Home screen widget (Android)
• iOS + Android (separate purchases)

--- Coming soon ---

• AI-powered weekly recap (opt-in; on-device by default)
• More themes
• Voice entry

--- Pricing ---

Retraq is free. A future update will add Retraq Pro — a one-time
in-app purchase for themes, advanced stats, and AI recap. No
subscription. No hidden fees.

--- Support ---

Website: retraq.app
Privacy: every journal entry stays on your device.
Contact: hello@retraq.app
```

## Keywords (100 chars, comma-separated)

```
journal,diary,memory,mood,daily,log,private,offline,lexend,simple,recap,habit,notes,brain,jot
```

Rationale:
- `journal`, `diary`, `memory`, `mood` — highest-intent category terms per Agent 5 market research.
- `lexend` — brand differentiator (research-backed readable font).
- `private`, `offline` — captures the growing privacy-first search intent.
- `recap`, `habit`, `notes`, `brain`, `jot` — related terms for discoverability.
- Intentionally dropped: `tracker` (too generic), `AI` (paid tier only), `depression`/`anxiety` (health-claim territory — Task 9.8).

## Category

- **Primary:** Lifestyle
- **Secondary:** Health & Fitness

Rationale: Lifestyle avoids Google Play Health Apps Declaration and
Apple 1.4.1 triggers. Agent 9 consensus.

## Age rating

- **4+** (Everyone) — no objectionable content, no user-generated visible content, no social features.
- **When caregiver (v2) ships**, re-rate to 12+ / Teen minimum with explicit data-sharing disclosure.

## Privacy nutrition label

**Data Not Collected** — defensible because:
- No network calls (enforced by Task 12.1 CI guard).
- All data stored locally on-device in SQLCipher-encrypted DB.
- User-initiated export to OS share sheet is not "data collection" under
  Apple's definitions (share intent is user action, not app transmission).

**When cloud AI recap ships (v1.1)**, rewrite label to declare:
- Data used to track you: none.
- Data linked to you: Purchases (RevenueCat — anonymized subscription tier);
  User Content (transient AI recap input — not retained).
- Data not linked to you: Diagnostics (opt-in crash logs; subject to
  Task 1.2 Sentry opt-in toggle).

## Support URL

`https://retraq.app/support` — to be live before submission (B-17 adjacent).

## Privacy policy URL

`https://retraq.app/privacy` — to be live before submission. Content
lives at `lib/legal/privacy_policy.dart` + tracked mirror at
`app/docs/legal/privacy-policy-source.md` once Task 12.2 ships.

## Marketing URL

`https://retraq.app` — domain reserved, landing page pending.

## Export compliance

`ITSAppUsesNonExemptEncryption = false` (declared in Info.plist:58).
Claim basis: SQLCipher AES-256 is standard cryptographic functionality
under EAR 740.17(b). See `app/docs/legal/ear-encryption-exemption.md`
(to be created in Task 12.15).

## Submission checklist

- [ ] Screenshots produced per `docs/external-blockers.md#b-17`
- [ ] New app icon landed per Task 13.1 (B-12)
- [ ] PrivacyInfo.xcprivacy complete (Task 9.5 — SHIPPED in `8e45c1b`)
- [ ] Privacy policy + Terms mirrors committed (Task 12.2 / 12.6)
- [ ] Subscription disclosure UI NOT needed for v1 (free)
- [ ] Support URL live
- [ ] Privacy URL live
- [ ] Age rating form completed (4+ / Everyone)
- [ ] Build signed + uploaded via TestFlight (B-3 / Task 10.2)
- [ ] Listing review pass through `app/docs/plans/epic-12-legal.md#task-12-5`
      forbidden-claims list

## A/B variants to test (v1.1+)

| Element | Variant A | Variant B | Measure |
|---|---|---|---|
| Subtitle | `Lost traq? Retraq.` | `Your memory backup.` | Install conversion from store view |
| Name | `Retraq — Remember Your Week` | `Retraq: Memory Journal` | Install conversion |
| First screenshot caption | `How've you been?` | `Lost traq? Retraq.` | Install conversion |

Run A/B via Apple's App Store product pages (up to 3 variants at 50/50/50 split).
