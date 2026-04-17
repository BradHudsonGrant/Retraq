const String privacyPolicyText = '''
# Privacy Policy

**Last Updated: April 16, 2026**

## Overview

Retraq ("the App") is a personal daily log application designed to help people with ADHD capture and organize their thoughts. Your privacy is fundamental to how Retraq is built. The App stores all data locally on your device and does not transmit your traqs or personal data over the internet.

## Data Collection

Retraq does **not** collect any personal data by default. There are no accounts, no sign-ups, no analytics, and no tracking of any kind. Your data never leaves your device unless you explicitly opt in to the single diagnostic feature described in the "Optional Diagnostics" section below.

## Data Stored Locally on Your Device

The App stores the following data exclusively on your device using an encrypted SQLite database (SQLCipher with AES-256 encryption):

- Traqs (text content, titles, and dates)
- User profile (display name and email, if you choose to provide them)
- User preferences and settings (theme, notification time, display options)
- PIN hash (if you enable App Lock)

This data never leaves your device unless you explicitly choose to export it.

## Data That Never Leaves Your Device

All traqs, settings, and security credentials remain on your device at all times. Retraq does not have servers, cloud infrastructure, or any mechanism to access your data remotely.

## Third-Party Services

Retraq does not use any advertising networks, analytics platforms, or general-purpose tracking services. The only third-party service the App can connect to is **Sentry** (sentry.io), and only when you explicitly enable it under the "Optional Diagnostics" section below — which is off by default.

## Optional Diagnostics (Crash Reporting)

Retraq includes a single, **opt-in**, off-by-default diagnostic feature: crash reporting via Sentry.

**What it does:** if you enable "Help improve Retraq" in Settings → Data, the App will send crash stack traces and technical error details to Sentry (sentry.io) when the App encounters a bug. This helps us fix crashes before they affect more users.

**What is sent:** Dart exception type and stack trace, Flutter framework version, Retraq version, operating system version, device model category (e.g. "Pixel 10 Pro"), and the approximate moment the crash occurred. We scrub device-specific PII (for example, iOS auto-generated device names like "Brad's iPhone") before the event leaves your device.

**What is NEVER sent:** traq text, titles, mood selections, dates, timestamps of your entries, biometric data, PIN hash, IP address (Sentry sees the HTTPS connection's IP but we do not attach it to the event), contact info, email, or any field you have typed into the App. Stack traces are code-level only.

**How to opt out:** toggle "Help improve Retraq" to off in Settings → Data at any time. New events stop immediately. Sentry's data retention for already-uploaded events is 30 days on the free tier we use; after that they are purged automatically. You can request earlier deletion by contacting us.

**Who operates Sentry:** Functional Software, Inc. d/b/a Sentry — a US-based company. For EU users, uploaded events cross the border; the scrubbing described above means no personal data of yours is transferred, but the HTTPS connection itself does reach US infrastructure. If this matters to you, leave the toggle off — the App functions identically without it.

**Default state:** off. You must actively toggle it on. We will never enable it without your explicit action.

## Data Export

You may export your traqs at any time using the in-app export feature. Exports are available in JSON and plain text formats. Exporting is entirely user-initiated and uses your device's native share sheet. Retraq does not retain copies of exported data.

## Data Deletion

You can delete individual traqs at any time from within the App. You can also use the "Delete All Data" option in Settings to erase all traqs, settings, and consent records at once. Alternatively, you can uninstall the App to remove all stored data from your device. There is no cloud backup to worry about -- once deleted from your device, your data is gone.

## Children's Privacy

Retraq is intended for users aged 13 and older. The App does not knowingly collect or store data from children under the age of 13. Since Retraq does not collect any data at all, there is no mechanism through which children's data could be gathered. If you believe a child under 13 is using the App inappropriately, please contact us.

## Your Rights (GDPR and Similar Regulations)

Even though Retraq does not collect or transmit your data, we respect your rights under GDPR and similar privacy regulations:

- **Right to Access:** You can view all your data directly in the App and export it at any time using the JSON export feature.
- **Right to Delete:** You can delete individual traqs or uninstall the App to remove all data.
- **Right to Portability:** The JSON export feature allows you to take your data with you in a standard, machine-readable format.

Because no data is transmitted to or stored on our servers, there is no data for us to access, process, or delete on our end.

## Future Cloud Features

We may introduce optional cloud-based features in the future, such as AI-powered weekly recaps or cloud sync. Any such features will:

- Require your explicit, informed consent before activation
- Be covered by a separate, detailed privacy notice
- Never be enabled by default
- Clearly explain what data is transmitted and how it is used

## Data Controller

Retraq is developed by an independent developer based in Canada. All data remains on your device under your control. Because no personal data is collected or processed on external servers, the concept of a data controller under GDPR and similar frameworks does not apply in the traditional sense for ordinary App use.

Nevertheless, for the purposes of GDPR Article 13(1)(a), PIPEDA Principle 1 (Accountability), and Quebec Law 25 accountability provisions, the data controller for any processing that does occur (for example, receipt of a privacy inquiry sent to the contact address below) is the App's developer, reachable at `contact@retraq.app`. A Canadian business entity name and mailing address will be published here alongside the controller contact once entity registration completes; see the repository's `docs/external-blockers.md` (item B-5) for the pending milestone.

A specific privacy officer / data protection officer is not appointed at this size; privacy inquiries may be sent to the same contact address.

## Supervisory Authority Complaint Routes

If you believe your privacy rights have been infringed by the App, you have the right to lodge a complaint with your local data-protection supervisory authority. Without limitation:

- **Canada:** Office of the Privacy Commissioner of Canada — https://www.priv.gc.ca/
- **Quebec:** Commission d'accès à l'information du Québec (CAI) — https://www.cai.gouv.qc.ca/
- **European Union:** your national supervisory authority; a list is maintained by the European Data Protection Board at https://edpb.europa.eu/about-edpb/about-edpb/members_en . If you are unsure, the French CNIL (https://www.cnil.fr/) serves as a common fallback.
- **United Kingdom:** Information Commissioner's Office (ICO) — https://ico.org.uk/
- **United States (California):** California Privacy Protection Agency — https://cppa.ca.gov/ and the California Attorney General — https://oag.ca.gov/privacy
- **Australia:** Office of the Australian Information Commissioner — https://www.oaic.gov.au/
- **Other jurisdictions:** your local data-protection authority or equivalent regulator.

We encourage you to contact us first at `contact@retraq.app` so we have an opportunity to address your concern, but this is not a precondition for exercising your right to complain.

## Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be communicated through an in-app notice when you open the App after an update. We encourage you to review this policy periodically. Material changes to this policy will require your explicit acceptance before you can continue using the App.

## Contact Us

If you have any questions or concerns about this Privacy Policy, please contact us at:

contact@retraq.app
''';
