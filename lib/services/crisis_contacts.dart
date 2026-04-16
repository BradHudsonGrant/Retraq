import 'dart:ui' show Locale, PlatformDispatcher;

/// Task 12.16 — Crisis line lookup per locale/region.
///
/// Hardcoding a single US/Canada number (988) in the health disclaimer
/// is a liability for non-North-American users — if a distressed user
/// sees a number that doesn't work in their country, the app has done
/// actively harm at the worst possible moment. This service resolves
/// the correct crisis contact based on the device locale.
///
/// Data source: national suicide-prevention helplines as published by
/// the International Association for Suicide Prevention and the
/// respective national providers. Numbers verified 2026-04-16.
///
/// The service returns a [CrisisContact] struct the caller uses to
/// render text like:
///   "If you are in crisis, call `<number>` (`<name>`)."
/// plus an optional text-line and web fallback.
///
/// For locales not explicitly mapped, the EU fallback (112) or
/// findahelpline.com is returned so users always see *something*
/// actionable rather than a dead US-only number.
class CrisisContact {
  const CrisisContact({
    required this.name,
    this.phone,
    this.text,
    this.url,
  });

  /// Human-readable name of the service (e.g. "988 Suicide Crisis
  /// Helpline (Canada)", "Samaritans").
  final String name;

  /// Dial-able number as a plain string. Null for URL-only fallbacks.
  final String? phone;

  /// SMS short-code for text-based support. Null when not available.
  final String? text;

  /// Fallback URL when no national number is mapped.
  final String? url;
}

class CrisisContacts {
  CrisisContacts._();

  /// Indexed by ISO 3166-1 alpha-2 region code (uppercase).
  static const Map<String, CrisisContact> _byRegion = {
    // North America (988 launched in Canada Nov 2023; in US since 2022).
    'US': CrisisContact(
      name: '988 Suicide & Crisis Lifeline',
      phone: '988',
      text: '988',
    ),
    'CA': CrisisContact(
      name: '988 Suicide Crisis Helpline (Canada)',
      phone: '988',
      text: '988',
    ),

    // UK / Ireland.
    'GB': CrisisContact(
      name: 'Samaritans',
      phone: '116 123',
    ),
    'IE': CrisisContact(
      name: 'Samaritans Ireland',
      phone: '116 123',
      text: '50808',
    ),

    // Oceania.
    'AU': CrisisContact(
      name: 'Lifeline Australia',
      phone: '13 11 14',
      text: '0477 13 11 14',
    ),
    'NZ': CrisisContact(
      name: '1737 Need to Talk?',
      phone: '1737',
      text: '1737',
    ),

    // Western Europe.
    'DE': CrisisContact(
      name: 'Telefonseelsorge',
      phone: '0800 111 0 111',
    ),
    'FR': CrisisContact(
      name: 'Numéro national de prévention du suicide',
      phone: '3114',
    ),
    'IT': CrisisContact(
      name: 'Telefono Amico',
      phone: '02 2327 2327',
    ),
    'ES': CrisisContact(
      name: 'Teléfono de la Esperanza',
      phone: '717 003 717',
    ),
    'NL': CrisisContact(
      name: '113 Zelfmoordpreventie',
      phone: '113',
    ),
    'BE': CrisisContact(
      name: 'Centre de Prévention du Suicide',
      phone: '1813',
    ),
    'PT': CrisisContact(
      name: 'SOS Voz Amiga',
      phone: '213 544 545',
    ),
    'AT': CrisisContact(
      name: 'Telefonseelsorge Österreich',
      phone: '142',
    ),
    'CH': CrisisContact(
      name: 'Die Dargebotene Hand',
      phone: '143',
    ),

    // Northern Europe.
    'SE': CrisisContact(
      name: 'Mind Självmordslinjen',
      phone: '901 01',
    ),
    'NO': CrisisContact(
      name: 'Mental Helse Hjelpetelefonen',
      phone: '116 123',
    ),
    'DK': CrisisContact(
      name: 'Livslinien',
      phone: '70 201 201',
    ),
    'FI': CrisisContact(
      name: 'MIELI Kriisipuhelin',
      phone: '09 2525 0111',
    ),
    'IS': CrisisContact(
      name: 'Hjálparsími Rauða krossins',
      phone: '1717',
    ),

    // Asia-Pacific.
    'JP': CrisisContact(
      name: 'TELL Lifeline Japan',
      phone: '03-5774-0992',
    ),
    'IN': CrisisContact(
      name: 'iCall',
      phone: '9152987821',
    ),
    'SG': CrisisContact(
      name: 'Samaritans of Singapore',
      phone: '1-767',
    ),
    'HK': CrisisContact(
      name: 'The Samaritan Befrienders Hong Kong',
      phone: '2389 2222',
    ),
  };

  /// Resolve the crisis contact for the given [locale].
  ///
  /// Resolution order:
  /// 1. If locale has a region, try exact match.
  /// 2. If no match and locale belongs to the EU, return the EU
  ///    emergency number (112) as a practical fallback.
  /// 3. Otherwise return the international findahelpline.com fallback.
  static CrisisContact forLocale(Locale locale) {
    final region = (locale.countryCode ?? '').toUpperCase();
    if (region.isNotEmpty && _byRegion.containsKey(region)) {
      return _byRegion[region]!;
    }
    if (_euRegions.contains(region)) {
      return const CrisisContact(
        name: 'European Emergency Number',
        phone: '112',
      );
    }
    return const CrisisContact(
      name: 'Find a Helpline (international)',
      url: 'https://findahelpline.com',
    );
  }

  /// Resolve the crisis contact using the platform's current locale.
  /// Convenience wrapper for use cases outside a BuildContext.
  static CrisisContact current() =>
      forLocale(PlatformDispatcher.instance.locale);

  /// Formatted inline string suitable for inlining into a localized
  /// sentence like "… please contact a mental health professional or
  /// call `<this>`.".
  ///
  /// Never throws; always returns a user-actionable string (falling
  /// back to the findahelpline.com URL if no national number exists).
  static String formatInline(CrisisContact c) {
    if (c.phone != null && c.text != null && c.phone == c.text) {
      return '${c.phone} (${c.name})';
    }
    if (c.phone != null) {
      return '${c.phone} (${c.name})';
    }
    if (c.url != null) {
      return '${c.url} (${c.name})';
    }
    return c.name;
  }

  static const Set<String> _euRegions = {
    'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE',
    'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT',
    'RO', 'SK', 'SI', 'ES', 'SE',
  };
}
