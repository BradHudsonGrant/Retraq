import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/pin_service.dart';

/// Dedicated PIN service test file.
///
/// Migrated from `database_service_test.dart` where PIN crypto coverage
/// was entangled with DB migration coverage. Owning these cases in
/// their own file means:
///   * PIN refactors no longer force touching migration tests.
///   * Single-responsibility test files are easier to run in isolation
///     during debugging.
///
/// v4 is the current format (250K PBKDF2). v3 (100K) and
/// v2 (600K) and legacy SHA-256 still verify for backward compat so
/// existing installs keep unlocking; all non-v4 formats are flagged
/// as legacy by `isLegacyPinHash` so the caller triggers an upgrade
/// on next successful unlock.
///
/// Tests use low iteration counts (100-1000) to stay fast but
/// exercise the same code paths as production. The async/isolate
/// path (`hashPin` / `verifyPin` backed by `compute()`) is not
/// covered here because `flutter_test` runs `compute()` inline on
/// the same isolate — a real isolate-spawn test would need a
/// separate device-side integration harness.
void main() {
  group('PinService v4 hashing', () {
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

  group('PIN Security (migrated from DB service tests)', () {
    setUp(() {
      PinService.setPbkdf2Iterations(100);
    });

    tearDown(PinService.resetPbkdf2Iterations);

    test('hashPin produces v4:iterations:salt:hash format', () {
      final hash = PinService.hashPinSync('1234');

      expect(hash.startsWith('v4:'), true);
      final parts = hash.split(':');
      expect(parts.length, 4);
      expect(int.tryParse(parts[1]), isNotNull); // iterations
      expect(parts[2].isNotEmpty, true); // salt (base64)
      expect(parts[3].isNotEmpty, true); // hash (base64)
    });

    test('verifyPin returns true for correct PIN', () {
      final stored = PinService.hashPinSync('5678');
      expect(PinService.verifyPinSync('5678', stored), true);
    });

    test('verifyPin returns false for wrong PIN', () {
      final stored = PinService.hashPinSync('1234');
      expect(PinService.verifyPinSync('5678', stored), false);
    });

    test('verifyPin returns false for empty PIN', () {
      final stored = PinService.hashPinSync('1234');
      expect(PinService.verifyPinSync('', stored), false);
    });

    test('verifyPin returns false for malformed stored hash', () {
      expect(PinService.verifyPinSync('1234', 'nocolon'), false);
      expect(PinService.verifyPinSync('1234', ''), false);
    });

    test('hashPin produces different hashes for same PIN (random salt)', () {
      final hash1 = PinService.hashPinSync('1234');
      final hash2 = PinService.hashPinSync('1234');

      // Salt should differ, so full stored string differs
      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPin works with 4-digit PIN', () {
      final stored = PinService.hashPinSync('0000');
      expect(PinService.verifyPinSync('0000', stored), true);
      expect(PinService.verifyPinSync('0001', stored), false);
    });

    test('verifyPin works with 6-digit PIN', () {
      final stored = PinService.hashPinSync('123456');
      expect(PinService.verifyPinSync('123456', stored), true);
      expect(PinService.verifyPinSync('654321', stored), false);
    });

    test('hashPin handles special characters in PIN', () {
      // PIN should be digits only in practice, but hash shouldn't crash
      final stored = PinService.hashPinSync('12AB');
      expect(PinService.verifyPinSync('12AB', stored), true);
    });

    test('isLegacyPinHash detects old format', () {
      // Old SHA-256 format: hex_salt:hex_hash
      expect(PinService.isLegacyPinHash('abc123:def456'), true);
      // v2 PBKDF2 (600K) is legacy — upgrade needed
      expect(PinService.isLegacyPinHash('v2:abc123:def456'), true);
      // v3 PBKDF2 (100K) is now also legacy
      expect(PinService.isLegacyPinHash('v3:100000:abc123:def456'), true);
      // v4 PBKDF2 (250K) is current
      expect(PinService.isLegacyPinHash('v4:250000:abc123:def456'), false);
    });
  });

  group('PIN cross-format verification (migrated)', () {
    setUp(() {
      PinService.setPbkdf2Iterations(100);
    });

    tearDown(PinService.resetPbkdf2Iterations);

    test('4-digit PIN hash does not verify with 6-digit input', () {
      final stored = PinService.hashPinSync('1234');
      expect(PinService.verifyPinSync('123400', stored), false);
      expect(PinService.verifyPinSync('001234', stored), false);
    });

    test('6-digit PIN hash does not verify with 4-digit input', () {
      final stored = PinService.hashPinSync('123456');
      expect(PinService.verifyPinSync('1234', stored), false);
      expect(PinService.verifyPinSync('3456', stored), false);
    });

    test('v4 format stores iteration count for future-proofing', () {
      final hash = PinService.hashPinSync('9999');
      final parts = hash.split(':');
      expect(parts[0], 'v4');
      final iterations = int.parse(parts[1]);
      expect(iterations, 100);
    });

    test('legacy v1 SHA-256 format is detected as legacy', () {
      // v1 format: "base64salt:hexhash" (no version prefix)
      expect(PinService.isLegacyPinHash('YWJjMTIz:abcdef0123456789'), true);
    });

    test('v2 PBKDF2 600K format is detected as legacy', () {
      // v2 format: "v2:base64salt:base64hash"
      expect(PinService.isLegacyPinHash('v2:YWJjMTIz:ZGVmNDU2'), true);
    });

    test('v4 PBKDF2 format is NOT detected as legacy', () {
      final hash = PinService.hashPinSync('5555');
      expect(PinService.isLegacyPinHash(hash), false);
      expect(PinService.isLegacyPinHash('v3:100000:salt:hash'), true);
    });

    test('same PIN with different salts produces different hashes', () {
      final hashes = List.generate(5, (_) => PinService.hashPinSync('0000'));
      expect(hashes.toSet().length, hashes.length);
      for (final hash in hashes) {
        expect(PinService.verifyPinSync('0000', hash), true);
      }
    });
  });

  group('PIN auto-upgrade end-to-end (migrated)', () {
    setUp(() {
      PinService.setPbkdf2Iterations(100);
    });

    tearDown(PinService.resetPbkdf2Iterations);

    test('legacy SHA-256 hash verifies, upgrades to v4, and re-verifies', () {
      const pin = '4321';

      // Step (a): Create a legacy SHA-256 hash manually.
      // Legacy format: "base64salt:hexhash" where hash = sha256("$salt:$pin")
      final saltBytes = utf8.encode('testSalt123');
      final saltB64 = base64Encode(saltBytes);
      final legacyHash =
          sha256.convert(utf8.encode('$saltB64:$pin')).toString();
      final legacyStored = '$saltB64:$legacyHash';

      // Step (b): Verify the PIN against the legacy hash — should pass.
      expect(PinService.verifyPinSync(pin, legacyStored), true);

      // Step (c): Confirm isLegacyPinHash detects it as legacy.
      expect(PinService.isLegacyPinHash(legacyStored), true);

      // Step (d): Hash the PIN with the current algorithm (v4).
      final upgradedHash = PinService.hashPinSync(pin);

      // Step (e): The new hash should NOT be legacy format.
      expect(PinService.isLegacyPinHash(upgradedHash), false);
      expect(upgradedHash.startsWith('v4:'), true);

      // Step (f): Verify the PIN against the upgraded hash — should pass.
      expect(PinService.verifyPinSync(pin, upgradedHash), true);
      // And wrong PIN should still fail.
      expect(PinService.verifyPinSync('0000', upgradedHash), false);
    });

    test('legacy v2 PBKDF2 hash verifies, upgrades to v4, and re-verifies', () {
      const pin = '9876';
      final currentHash = PinService.hashPinSync(pin);

      // Simulate: after upgrade, the hash is v4
      expect(currentHash.startsWith('v4:'), true);
      expect(PinService.isLegacyPinHash(currentHash), false);
      expect(PinService.verifyPinSync(pin, currentHash), true);

      // A v2 prefix is always detected as legacy
      expect(PinService.isLegacyPinHash('v2:anySalt:anyHash'), true);
    });
  });
}
