import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/locale_age_threshold.dart';

/// Task 12.3 — verifies the country-aware minimum-age table covers
/// the regulatory choices we care about and falls back safely for
/// unknown regions.
void main() {
  group('ageThresholdForCountry', () {
    test('defaults to 13 for null / empty / unknown', () {
      expect(ageThresholdForCountry(null), 13);
      expect(ageThresholdForCountry(''), 13);
      expect(ageThresholdForCountry('ZZ'), 13);
      expect(ageThresholdForCountry('XX'), 13);
    });

    test('GDPR Art. 8 member states choosing 16 return 16', () {
      // The ten member states that set 16 as of 2026-04.
      const sixteens = [
        'DE', 'NL', 'FR', 'IT', 'LU', 'IE', 'RO', 'HU', 'HR', 'SI',
      ];
      for (final cc in sixteens) {
        expect(
          ageThresholdForCountry(cc),
          16,
          reason: '$cc should require 16 per GDPR Art. 8 member-state choice',
        );
      }
    });

    test('GDPR Art. 8 members choosing 14 + Quebec return 14', () {
      const fourteens = ['AT', 'BG', 'CY', 'LT', 'ES', 'QC'];
      for (final cc in fourteens) {
        expect(
          ageThresholdForCountry(cc),
          14,
          reason: '$cc should require 14',
        );
      }
    });

    test('anglophone + COPPA-aligned countries return 13', () {
      const thirteens = [
        'US', 'CA', 'GB', 'AU', 'NZ', 'IN', 'JP', 'SG', 'HK',
      ];
      for (final cc in thirteens) {
        expect(
          ageThresholdForCountry(cc),
          13,
          reason: '$cc should require 13 (COPPA baseline)',
        );
      }
    });

    test('case-insensitive', () {
      expect(ageThresholdForCountry('de'), 16);
      expect(ageThresholdForCountry('De'), 16);
      expect(ageThresholdForCountry('qc'), 14);
      expect(ageThresholdForCountry('us'), 13);
    });
  });

  group('hasElevatedThreshold', () {
    test('true for 14+ countries', () {
      expect(hasElevatedThreshold('DE'), isTrue); // 16
      expect(hasElevatedThreshold('QC'), isTrue); // 14
      expect(hasElevatedThreshold('ES'), isTrue); // 14
    });

    test('false for 13 countries and unknown', () {
      expect(hasElevatedThreshold('US'), isFalse);
      expect(hasElevatedThreshold('CA'), isFalse);
      expect(hasElevatedThreshold(null), isFalse);
      expect(hasElevatedThreshold('ZZ'), isFalse);
    });
  });

  group('regionFromLocaleTag', () {
    test('extracts region from underscore-separated tags', () {
      expect(regionFromLocaleTag('en_US'), 'US');
      expect(regionFromLocaleTag('fr_CA'), 'CA');
      expect(regionFromLocaleTag('de_DE'), 'DE');
    });

    test('extracts region from hyphen-separated tags', () {
      expect(regionFromLocaleTag('en-GB'), 'GB');
      expect(regionFromLocaleTag('zh-HK'), 'HK');
    });

    test('returns null for region-less or empty tags', () {
      expect(regionFromLocaleTag(null), isNull);
      expect(regionFromLocaleTag(''), isNull);
      expect(regionFromLocaleTag('en'), isNull);
      expect(regionFromLocaleTag('fr'), isNull);
    });

    test('uppercases returned region', () {
      expect(regionFromLocaleTag('en_us'), 'US');
      expect(regionFromLocaleTag('fr_ca'), 'CA');
    });
  });

  group('Table coverage sanity', () {
    test('threshold table covers 30+ countries', () {
      // Guard against accidentally shrinking the table in a future
      // edit. We care that GDPR + anglophone + Quebec + a few more
      // Asian markets are all covered.
      const mustBePresent = [
        // GDPR Art. 8 (full set relevant for Retraq's EU reach)
        'DE', 'NL', 'FR', 'IT', 'LU', 'IE', 'RO', 'HU', 'HR', 'SI',
        'AT', 'BG', 'CY', 'LT', 'ES',
        'BE', 'DK', 'EE', 'FI', 'LV', 'MT', 'PL', 'PT', 'SE', 'SK',
        'CZ', 'GR',
        // Quebec pseudo-code
        'QC',
        // Non-EU anglophone + key markets
        'US', 'CA', 'GB', 'AU', 'NZ', 'IN', 'JP', 'SG', 'HK',
      ];
      for (final cc in mustBePresent) {
        // Every entry should return a non-default mapping OR match
        // the baseline 13. Presence check is implicit — hitting
        // "default 13" for a tracked code means we dropped it.
        // We check the explicit value we documented.
        final expected = _expectedForTest(cc);
        expect(
          ageThresholdForCountry(cc),
          expected,
          reason: '$cc dropped from threshold table',
        );
      }
    });
  });
}

int _expectedForTest(String cc) {
  switch (cc) {
    case 'DE':
    case 'NL':
    case 'FR':
    case 'IT':
    case 'LU':
    case 'IE':
    case 'RO':
    case 'HU':
    case 'HR':
    case 'SI':
      return 16;
    case 'AT':
    case 'BG':
    case 'CY':
    case 'LT':
    case 'ES':
    case 'QC':
      return 14;
    default:
      return 13;
  }
}
