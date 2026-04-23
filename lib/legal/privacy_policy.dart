const String privacyPolicyText = '''
# Privacy Policy

**Last updated: April 23, 2026**

## The short version

Retraq keeps your traqs on your phone. There are no accounts, no sign-ups, no servers that hold your data, and no analytics or ad trackers. The only thing that can leave your device is an optional crash report, and it's off by default.

## What's stored on your device

Retraq saves the following in a local, encrypted database (SQLCipher-compatible AES-256):

- Your traqs — the text, optional title, date, optional AM/PM label, and optional 1–5 mood rating
- Your settings — theme, notification time, display options
- Optionally, a display name and email if you enter one
- Optionally, a PIN hash if you turn on App Lock (PBKDF2-HMAC-SHA256, 250,000 iterations, salted — we can't reverse it into your PIN)

None of this leaves your device.

## Biometric unlock (Face ID, fingerprint)

If you enable biometric unlock, the match happens on your device through iOS or Android. Retraq never sees your face, fingerprint, or any biometric data — just a yes/no from the operating system.

## What can go over the internet

**By default: nothing.** Retraq doesn't need an internet connection to work.

If you turn on **"Help improve Retraq"** in Settings → Data, the app will send crash reports to Sentry (sentry.io) when something breaks. Those reports include:

- The error type and a code-level stack trace
- The app version and OS version
- The device model category (e.g. "Pixel 10 Pro")
- The rough time the crash happened

We strip the device nickname before anything leaves your phone.

Crash reports **never** include: your traq text, titles, moods, dates, your name or email, your PIN, biometric data, or anything else you've typed into the app.

You can turn this off at any time in Settings → Data. Events already sent are kept for 30 days by Sentry's default retention and then purged. Sentry is operated by Functional Software, Inc. in the US, so if you're in the EU or UK, the HTTPS connection reaches US infrastructure — the scrubbing above means no personal data of yours travels with it. If that's a concern, leave the toggle off; the app works exactly the same.

## Exporting and deleting your data

- **Export**: Settings → Data → Export shares a JSON or plain-text copy through your device's share sheet. We don't keep a copy.
- **Delete one traq**: delete it directly from the entry.
- **Delete everything**: Settings → Data → Delete All Data clears every traq, setting, and consent record from your device.
- **Uninstall**: removes everything. There's no cloud backup to clean up afterwards.

## Permissions we ask for

- **Notifications** — so Retraq can send you a daily reminder. Optional; turn it off in Settings or your OS settings.
- **Biometric / fingerprint** — only if you turn on App Lock.
- **Run after device restart** (Android) — so daily reminders still fire after a reboot.

We don't ask for contacts, location, camera, microphone, photos, or general storage access.

## Children

Retraq is intended for people aged 13 and up. Since the app doesn't collect data at all, there's no mechanism to gather children's data either. If you think a child is using the app and shouldn't be, let us know.

## Your rights (GDPR, PIPEDA, and similar)

Even though we don't hold your data on our servers, you still have rights under laws like GDPR and PIPEDA:

- **Access** — everything is visible in the app and exportable as JSON.
- **Delete** — use Delete All Data, or uninstall.
- **Portability** — the JSON export is a standard, machine-readable format.

Because no data reaches our servers, there's nothing for us to access, change, or delete on our end.

## Who's behind this app

Retraq is built by an independent developer based in Canada. A registered business entity name and mailing address will be added here once registration completes. Until then, privacy questions can go to **contact@retraq.app**.

If you believe your privacy rights have been infringed, you have the right to complain to your local data-protection authority. We'd appreciate the chance to address it first, but that's not required. Some contacts:

- **Canada**: Office of the Privacy Commissioner — https://www.priv.gc.ca/
- **Quebec**: Commission d'accès à l'information du Québec — https://www.cai.gouv.qc.ca/
- **EU**: your national supervisory authority (list: https://edpb.europa.eu/about-edpb/about-edpb/members_en)
- **UK**: Information Commissioner's Office — https://ico.org.uk/
- **California**: California Privacy Protection Agency — https://cppa.ca.gov/
- **Australia**: Office of the Australian Information Commissioner — https://www.oaic.gov.au/

## If we ever add cloud features

If we add something like cloud sync or AI recaps in the future, it will be:

- Opt-in, off by default
- Covered by a separate, clear privacy notice
- Never enabled without you actively turning it on

## Changes to this policy

We'll update this policy from time to time. When something material changes, you'll see an in-app notice the next time you open Retraq and we'll ask you to accept the new version before continuing.

## Contact

contact@retraq.app
''';
