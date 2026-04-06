const String privacyPolicyText = '''
# Privacy Policy

**Last Updated: March 29, 2026**

## Overview

Retraq ("the App") is a personal daily log application designed to help people with ADHD capture and organize their thoughts. Your privacy is fundamental to how Retraq is built. The App stores all data locally on your device and does not transmit your traqs or personal data over the internet.

## Data Collection

Retraq does **not** collect any personal data. There are no accounts, no sign-ups, no analytics, no telemetry, and no tracking of any kind. Your data never leaves your device.

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

Retraq does not currently use any third-party services, SDKs, analytics platforms, or advertising networks. No data is shared with any third party.

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

Retraq is developed by an independent developer. All data remains on your device under your control. There is no external data controller. Because no personal data is collected or processed on external servers, the concept of a data controller under GDPR and similar frameworks does not apply in the traditional sense. You are the sole custodian of your data.

## Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be communicated through an in-app notice when you open the App after an update. We encourage you to review this policy periodically. Material changes to this policy will require your explicit acceptance before you can continue using the App.

## Contact Us

If you have any questions or concerns about this Privacy Policy, please contact us at:

contact@retraq.app
''';
