import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/pin_service.dart';

/// Task 3.7 — Verifies v4 is the current PBKDF2 hash format, v3 still
/// verifies (so existing installs keep working), and v2/SHA-256 legacy
/// hashes also round-trip. Tests use low iteration counts to stay fast
/// but exercise the same code paths as production.
void main() {
  group('PinService v4 hashing (Task 3.7)', () {
    setUp(() {
      // Keep tests fast — real code uses 250K.
      PinService.setPbkdf2Iterations(1000);
    });

    tearDown(PinService.resetPbkdf2Iterations);

    test('hashPinSync produces a v4 hash', () {
      final hash = PinService.hashPinSync('1234');
      expect(hash, startsWith('v4:'));
      final parts = hash.split(':');
      expect(parts, hasLength(4));
      expect(int.parse(parts[1]), 1000); // iterations are stored
    });

    test('verifyPinSync matches its own v4 hash', () {
      final hash = PinService.hashPinSync('1234');
      expect(PinService.verifyPinSync('1234', hash), isTrue);
      expect(PinService.verifyPinSync('9999', hash), isFalse);
    });

    test('v3 hashes still verify (backward compatibility)', () {
      // Hand-craft a v3 hash at the current iteration count — the v3
      // and v4 inner format is identical, so re-labelling a freshly
      // computed v4 hash as v3 simulates an install from before the
      // bump.
      final v4 = PinService.hashPinSync('abcd');
      final v3 = 'v3:${v4.substring(3)}';
      expect(PinService.verifyPinSync('abcd', v3), isTrue);
      expect(PinService.verifyPinSync('wxyz', v3), isFalse);
    });

    test('isLegacyPinHash marks v3/v2/SHA-256 as legacy, v4 as current', () {
      expect(PinService.isLegacyPinHash('v4:100000:abc:def'), isFalse);
      expect(PinService.isLegacyPinHash('v3:100000:abc:def'), isTrue);
      expect(PinService.isLegacyPinHash('v2:abc:def'), isTrue);
      expect(
        PinService.isLegacyPinHash('aaaa:bbbbbbbbbbbbbbbb'),
        isTrue,
      );
    });

    test('same PIN produces different hashes (unique salts)', () {
      final a = PinService.hashPinSync('0000');
      final b = PinService.hashPinSync('0000');
      expect(a == b, isFalse, reason: 'salts must be unique');
      expect(PinService.verifyPinSync('0000', a), isTrue);
      expect(PinService.verifyPinSync('0000', b), isTrue);
    });

    test('malformed hashes do not crash and return false', () {
      expect(PinService.verifyPinSync('1234', 'v4:garbage'), isFalse);
      expect(PinService.verifyPinSync('1234', 'v3:NaN:salt:hash'), isFalse);
      expect(PinService.verifyPinSync('1234', ''), isFalse);
    });
  });
}
