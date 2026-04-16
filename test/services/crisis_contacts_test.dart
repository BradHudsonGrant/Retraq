// ignore_for_file: prefer_single_quotes

import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/crisis_contacts.dart';

/// Task 12.16 — Locale → crisis-contact resolution must cover every
/// mapped region, fall back to EU 112 for unmapped EU regions, and
/// fall back to findahelpline.com for everyone else.
void main() {
  group('CrisisContacts.forLocale', () {
    test('US → 988 Suicide & Crisis Lifeline', () {
      final c = CrisisContacts.forLocale(const Locale('en', 'US'));
      expect(c.phone, '988');
      expect(c.name, contains('988'));
    });

    test('CA → 988 Suicide Crisis Helpline (Canada)', () {
      final c = CrisisContacts.forLocale(const Locale('en', 'CA'));
      expect(c.phone, '988');
      expect(c.name, contains('Canada'));
    });

    test('GB → Samaritans 116 123', () {
      final c = CrisisContacts.forLocale(const Locale('en', 'GB'));
      expect(c.phone, '116 123');
      expect(c.name, equals('Samaritans'));
    });

    test('FR → 3114 (national suicide prevention)', () {
      final c = CrisisContacts.forLocale(const Locale('fr', 'FR'));
      expect(c.phone, '3114');
      expect(c.name, contains('prévention'));
    });

    test('DE → Telefonseelsorge', () {
      final c = CrisisContacts.forLocale(const Locale('de', 'DE'));
      expect(c.phone, '0800 111 0 111');
      expect(c.name, equals('Telefonseelsorge'));
    });

    test('AU → Lifeline Australia 13 11 14', () {
      final c = CrisisContacts.forLocale(const Locale('en', 'AU'));
      expect(c.phone, '13 11 14');
      expect(c.text, '0477 13 11 14');
    });

    test('NZ → 1737', () {
      final c = CrisisContacts.forLocale(const Locale('en', 'NZ'));
      expect(c.phone, '1737');
      expect(c.text, '1737');
    });

    test('IE → Samaritans Ireland + text 50808', () {
      final c = CrisisContacts.forLocale(const Locale('en', 'IE'));
      expect(c.phone, '116 123');
      expect(c.text, '50808');
    });

    test('unmapped EU region (Hungary) → EU 112 fallback', () {
      final c = CrisisContacts.forLocale(const Locale('hu', 'HU'));
      expect(c.phone, '112');
      expect(c.name, contains('European'));
    });

    test('unmapped non-EU region (Brazil) → findahelpline.com fallback', () {
      final c = CrisisContacts.forLocale(const Locale('pt', 'BR'));
      expect(c.phone, isNull);
      expect(c.url, equals('https://findahelpline.com'));
      expect(c.name, contains('Find a Helpline'));
    });

    test('locale with no region → findahelpline.com fallback', () {
      final c = CrisisContacts.forLocale(const Locale('xx'));
      expect(c.url, equals('https://findahelpline.com'));
    });

    test('lowercase country code still resolves (forgiveness)', () {
      final c = CrisisContacts.forLocale(const Locale('en', 'us'));
      expect(c.phone, '988');
    });
  });

  group('CrisisContacts.formatInline', () {
    test('phone + name', () {
      final formatted = CrisisContacts.formatInline(
        CrisisContacts.forLocale(const Locale('en', 'US')),
      );
      expect(formatted, contains('988'));
      expect(formatted, contains('Lifeline'));
    });

    test('url fallback', () {
      final formatted = CrisisContacts.formatInline(
        CrisisContacts.forLocale(const Locale('xx')),
      );
      expect(formatted, contains('findahelpline.com'));
    });
  });
}
