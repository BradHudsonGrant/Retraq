/// Task 12.3 — Country-aware minimum self-attestation age for the
/// onboarding age gate.
///
/// Regulatory basis:
///
/// - **COPPA 16 CFR 312** (US) — under-13 requires verified parental
///   consent. Retraq's posture: refuse under-13 at the age gate; no
///   parental-consent flow in v1 (would require counsel-reviewed
///   verified-parental-consent UX per FTC 2026 policy statement).
/// - **Quebec Law 25** — 14 is the age of consent for personal-info
///   processing; under-14 needs holder-of-parental-authority consent.
/// - **GDPR Art. 8** — default 16 for information-society services
///   offered to children, but member states may lower to 13. The
///   table below reflects the member-state choices as of 2026-04.
/// - **UK GDPR + Age-Appropriate Design Code** — 13, plus "high
///   standards" for children's services (Retraq's zero-network
///   posture satisfies).
/// - **Australia / New Zealand / Canada (ex-Quebec) / US** — 13
///   per COPPA-aligned practice.
///
/// Design choice: use the device locale's region code, NOT IP
/// geolocation. Less accurate but avoids geo-IP compliance overhead
/// and keeps the zero-network-call promise. Users can self-declare
/// a region (e.g., a "I'm in Quebec" toggle for `fr_FR` vs `fr_CA`
/// disambiguation) — that's a v1.1 enhancement; v1 uses locale only.
///
/// Retraq's v1 behavior at the gate:
///
/// - **User self-attests ≥ threshold**: proceed to consent flow.
/// - **User self-attests < threshold**: show the denial screen.
///   No parental-consent flow in v1 — requires counsel-reviewed
///   verified-consent UX (Task 12.12 follow-up). Denial persists
///   via secure storage (existing `ageDeniedSecureKey` path).
///
/// When the counsel-reviewed parental-consent page lands (v1.1+),
/// the decision layer becomes: < threshold AND ≥ 13 → parental
/// consent; < 13 → denial. The helper below already exposes the
/// numeric threshold so callers can build that ternary without
/// further changes here.
library;

/// Returns the minimum self-attestation age for the given ISO 3166-1
/// alpha-2 [countryCode]. Defaults to 13 for unknown regions — the
/// COPPA baseline, which also matches the most permissive GDPR
/// Art. 8 member-state choice.
///
/// [countryCode] should be uppercase (e.g. `'US'`, `'DE'`, `'QC'`).
/// The special pseudo-code `'QC'` is accepted for Quebec-specific
/// routing; callers that detect a Quebec user via locale `fr_CA` +
/// an explicit "I'm in Quebec" declaration can pass `'QC'` and get
/// 14.
int ageThresholdForCountry(String? countryCode) {
  if (countryCode == null || countryCode.isEmpty) return 13;
  final code = countryCode.toUpperCase();
  return _thresholds[code] ?? 13;
}

/// Whether [countryCode] is one of the GDPR Art. 8 member-state
/// choices Retraq explicitly handles above the 13 baseline.
/// Useful for caller-side copy ("You must be 16+ in Germany..."
/// style nuance; v1 currently omits this but the helper is here
/// for when we re-address copy).
bool hasElevatedThreshold(String? countryCode) {
  final age = ageThresholdForCountry(countryCode);
  return age > 13;
}

/// Extracts a normalized region code from a locale. Accepts Dart
/// `Locale.toString()` output (`'en_US'`, `'fr_CA'`, `'de'`) and
/// returns the uppercase 2-letter region, or null if absent.
String? regionFromLocaleTag(String? localeTag) {
  if (localeTag == null || localeTag.isEmpty) return null;
  // Handle both `_` and `-` separators.
  final parts = localeTag.replaceAll('-', '_').split('_');
  if (parts.length < 2) return null;
  final region = parts[1];
  if (region.isEmpty || region.length < 2) return null;
  return region.substring(0, 2).toUpperCase();
}

// GDPR Art. 8 member-state choices as of 2026-04:
// 16: DE, NL, FR, IT, LU, IE, RO, HU, HR, SI
// 14: AT, BG, CY, LT, ES, QC (Quebec Law 25)
// 13: BE, DK, EE, FI, LV, MT, PL, PT, SE, SK, CZ, GR
//
// Non-EU / non-Quebec baseline: 13 (COPPA + COPPA-aligned).
const Map<String, int> _thresholds = {
  // GDPR Art. 8 — member states choosing 16
  'DE': 16, // Germany — BDSG §25
  'NL': 16, // Netherlands — UAVG
  'FR': 16, // France — Loi Informatique et Libertés
  'IT': 16, // Italy — Codice Privacy
  'LU': 16, // Luxembourg
  'IE': 16, // Ireland — Data Protection Act 2018
  'RO': 16, // Romania
  'HU': 16, // Hungary
  'HR': 16, // Croatia
  'SI': 16, // Slovenia

  // GDPR Art. 8 — member states choosing 14 (+ Quebec)
  'AT': 14, // Austria
  'BG': 14, // Bulgaria
  'CY': 14, // Cyprus
  'LT': 14, // Lithuania
  'ES': 14, // Spain — LOPDGDD
  'QC': 14, // Quebec Law 25 (pseudo-code; not ISO)

  // GDPR Art. 8 — member states choosing 13 (baseline, listed for clarity)
  'BE': 13, // Belgium
  'DK': 13, // Denmark
  'EE': 13, // Estonia
  'FI': 13, // Finland
  'LV': 13, // Latvia
  'MT': 13, // Malta
  'PL': 13, // Poland
  'PT': 13, // Portugal
  'SE': 13, // Sweden
  'SK': 13, // Slovakia
  'CZ': 13, // Czechia
  'GR': 13, // Greece

  // Non-EU anglophone / COPPA-aligned
  'US': 13,
  'CA': 13, // Canada (ex-Quebec; Quebec callers should pass 'QC')
  'GB': 13, // United Kingdom
  'AU': 13, // Australia
  'NZ': 13, // New Zealand
  'IN': 13, // India
  'JP': 13, // Japan
  'SG': 13, // Singapore
  'HK': 13, // Hong Kong

  // Everything else falls back to 13 via ageThresholdForCountry.
};
