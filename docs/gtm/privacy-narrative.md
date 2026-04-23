# "Your memories never leave your phone" — the Retraq privacy narrative

**Status:** Ship-ready · **Task:** 5.4 · **Last updated:** 2026-04-16

The on-device-only architecture is Retraq's single most defensible
advantage in a category where every incumbent syncs to the cloud,
processes text through a third-party LLM, or both. This document is
the source of truth for how we write, say, and show the privacy
story across every external surface.

## The one-line claim

> **Your memories never leave your phone.**

This is the lead. Not "privacy-first." Not "on-device." The
emotional noun (`memories`) + the physical object (`your phone`)
+ the spatial verb (`never leave`) is the combination that lands.

## The three paragraphs

### What stays on the phone

Every entry you write, every mood you log, every recap the app
generates lives exclusively in an encrypted SQLite database on
your device. The database is protected with SQLCipher AES-256;
the encryption key is stored in your platform's secure storage
(Android Keystore / iOS Keychain). When you close the app, nothing
gets uploaded. When you open it again, nothing gets fetched. The
app literally has no network client for your journal data — you
can verify this in our public repo: the
[`no_network_invariant_test.dart`](https://github.com/BradHudsonGrant/Retraq/blob/main/app/test/services/no_network_invariant_test.dart)
fails any build that adds one.

### What this means operationally

- **No cloud sync in v1.** Your entries live on the device you
  wrote them on. If you want them on another device, you export
  a file.
- **No analytics.** No crash reporter sends stack traces. No
  "help us improve" auto-reporting. The one opt-in exit door
  ("Help improve Retraq" anonymized share) routes through the
  OS share sheet — you pick the destination, the app never opens
  a socket.
- **No LLM calls.** The weekly recap is rule-based and runs
  on-device. Cloud AI summaries are v2 scope, behind explicit
  consent, and will never be on by default.
- **Exports are deliberate.** When you tap "Export," the file
  goes to the OS share sheet. The app shows a confirmation
  dialog first (Task 3.9) warning you the file is in readable
  form and the destination app receives a plain copy.

### How this compares to the category

| Competitor | Cloud sync? | LLM calls? | Ad SDKs? |
|---|---|---|---|
| Day One | Yes (default) | No | No |
| Daylio | Yes (via Google Drive/Dropbox) | No | Yes (free tier) |
| Apple Journal | Yes (iCloud by default) | Apple Intelligence (on-device but Apple-mediated) | No |
| Rosebud | Yes (required) | Yes (OpenAI) | No |
| Mindsera | Yes (required) | Yes (OpenAI) | No |
| Finch | Yes (required) | Yes (proprietary pets + cloud analytics) | No |
| **Retraq** | **No** | **No** | **No** |

How We Feel (nonprofit) is the closest comparable on the on-
device posture; they've built a reputation on it. Retraq is the
only consumer-targeted journal app with this architecture at
v1 launch.

## Writing rules

- **"Never leave your phone"** is the anchor phrase. Reuse it
  verbatim in the store description, onboarding splash screen,
  and at least two screenshots.
- **Don't get defensive.** The privacy claim is a capability
  statement, not a reassurance. "We don't have your data because
  we don't collect it" — not "we promise we won't share your
  data."
- **Avoid legal-ese.** No "subject to our privacy policy",
  no "we take your privacy seriously," no "your information is
  safe with us." Those phrases land as boilerplate.
- **Do name the mechanism when space allows.** "SQLCipher AES-256
  encryption" reads credibly; "military-grade encryption" reads
  like a 2010 antivirus ad.
- **Do cite the public test.** The `no_network_invariant_test.dart`
  file is a verifiable artifact. Link to it in press kit and
  technical-audience posts.

## The one-sentence variants by slot

| Slot | Copy |
|---|---|
| Store description — privacy section | **Your memories never leave your phone. Every entry is stored locally, encrypted, and never uploaded. Our repo is open about it — there's no network client for your journal data.** |
| Onboarding slide 3 | `Your words stay on your phone. No cloud, no accounts, no ads.` |
| Screenshot overlay — Privacy screen | `Your words never leave your phone.` |
| Press soundbite — technical audience | `Retraq's repo includes a CI test that fails any build introducing a network dependency for entry data. It's a verifiable architectural promise, not a marketing one.` |
| Creator DM opener | `Retraq stays on your phone. The journal app doesn't have servers — your entries are encrypted on your device, full stop. If you've ever worried what happens to the things you wrote in Day One or Rosebud, this is what we built for.` |

## Coordinated screenshot set

Screenshots that must land when Epic 9 ships (B-17 vendor):

1. **Recap tab** with overlay: *"The week you forgot. Retraqed."*
2. **Home / Jot** with overlay: *"One sentence is enough."*
3. **Privacy screen** with overlay: *"Your words never leave your phone."*
4. **Export dialog** with overlay: *"You choose where it goes. The app never does."*
5. **Stats tab** with overlay: *"Freeze days built in. No streak shaming."*

At least 2 of the 5 carry the privacy narrative (3 + 4).

## Press kit talking points

Five soundbites, each ≤ 1 sentence, pre-approved for reviewers
and creators to quote:

1. *"Retraq is the only consumer journaling app shipping v1
   with a CI-enforced zero-network posture for entry data."*
2. *"The weekly recap runs entirely on-device. There's no LLM
   call, no cloud summary, no 'AI-powered' caveat."*
3. *"We can't turn over your journal because we don't have it —
   it lives encrypted on your phone, and our repo is public
   about that."*
4. *"Cloud AI is v2 scope, behind explicit consent, and never
   on by default. We're building the consent UX first, the
   feature second."*
5. *"The 'Help improve Retraq' opt-in anonymized export is the
   only path data leaves the device, and even then you pick the
   destination — the app never opens a socket."*

## Coordination with v1.1 cloud AI

When cloud AI ships in v1.1 (opt-in Tier 3 per
`implementation_plan.md` Part II), the privacy nutrition label
will need a rewrite (Task 9.7). Until then:

- **v1 privacy nutrition label:** Data Not Collected (defensible).
- **v1.1 privacy nutrition label:** "Data Linked to You" for the
  AI tier ONLY (input prompts + generated summaries, covered by
  explicit opt-in and Art. 9 consent per Task 12.4).
- **Messaging transition:** the free tier stays fully on-device.
  The paid tier's cloud AI is the only surface that changes. This
  distinction MUST be explicit in the v1.1 upgrade flow.

## Sibling artifacts

- [`positioning-one-pager.md`](./positioning-one-pager.md)
- [`narrative-hook.md`](./narrative-hook.md)
- [`battlecards/daylio.md`](./battlecards/daylio.md)
- [`battlecards/apple-journal.md`](./battlecards/apple-journal.md)
- [`../legal/privacy_policy.dart` source](../../lib/legal/privacy_policy.dart)
  *(the canonical text this doc cross-checks against)*
- [`../store-listing/aso-keyword-strategy.md`](../store-listing/aso-keyword-strategy.md)
  — Privacy-adjacent keyword targets.
