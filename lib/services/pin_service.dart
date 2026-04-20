// ignore_for_file: prefer_single_quotes

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// All PIN security: PBKDF2 hashing, verification, legacy format support.
/// Stateless — no database dependency.
class PinService {
  PinService._();

  // Raised from 100K (v3) to 250K (v4).
  //
  // Rationale: for a 4-digit PIN (10K keyspace), 100K PBKDF2 iterations
  // cracks in seconds on modern GPUs if the DB hash + salt are ever
  // exfiltrated together. The lockout controller protects online
  // attacks but not this offline-forensic scenario. 250K is the middle
  // ground the Agent-3 security review recommended — still comfortably
  // under the multi-second lag budget that forced the earlier drop
  // from v2's 600K because verification runs in a compute() isolate
  // (see hashPin/verifyPin below) and so never blocks the UI frame.
  //
  // v2 (legacy SHA-256), v3 (100K PBKDF2), and v4 (250K PBKDF2) all
  // verify correctly; v2 and v3 hashes auto-upgrade to v4 on the
  // user's next successful unlock via isLegacyPinHash() below.
  static const _defaultPbkdf2Iterations = 250000;
  static int _pbkdf2Iterations = _defaultPbkdf2Iterations;
  static const _pbkdf2KeyLength = 32; // bytes
  static const _hashVersionV4 = 'v4';

  @visibleForTesting
  static bool useIsolateForPin = true;

  @visibleForTesting
  static void setPbkdf2Iterations(int iterations) {
    _pbkdf2Iterations = iterations;
    useIsolateForPin = false;
  }

  @visibleForTesting
  static void resetPbkdf2Iterations() {
    _pbkdf2Iterations = _defaultPbkdf2Iterations;
    useIsolateForPin = true;
  }

  /// PBKDF2-HMAC-SHA256 key derivation.
  static List<int> _pbkdf2(String pin, List<int> salt, {int? iterations}) {
    iterations ??= _pbkdf2Iterations;
    final hmacSha256 = Hmac(sha256, utf8.encode(pin));
    // PBKDF2 with single block (keyLength <= hash output)
    // U1 = PRF(password, salt || INT_32_BE(1))
    final saltWithBlock = [...salt, 0, 0, 0, 1];
    var u = hmacSha256.convert(saltWithBlock).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmacSha256.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result.sublist(0, _pbkdf2KeyLength);
  }

  // v2 hashes used 600K iterations but didn't store the count.
  static const _v2LegacyIterations = 600000;

  /// Hash a PIN using PBKDF2-HMAC-SHA256.
  /// Stored as "v4:iterations:base64salt:base64hash".
  /// Runs in an isolate via compute() to avoid blocking the UI.
  static Future<String> hashPin(String pin) {
    if (!useIsolateForPin) return Future.value(_hashPinIsolate(pin));
    return compute(_hashPinIsolate, pin);
  }

  /// Synchronous version for use in tests (compute() doesn't work in test).
  @visibleForTesting
  static String hashPinSync(String pin) => _hashPinIsolate(pin);

  static String _hashPinIsolate(String pin) {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final hash = _pbkdf2(pin, salt);
    return '$_hashVersionV4:$_pbkdf2Iterations:${base64Encode(salt)}:${base64Encode(hash)}';
  }

  /// Verify a PIN against a stored hash.
  /// Supports legacy SHA-256, v2 PBKDF2 (600K), v3 PBKDF2 (100K), and
  /// v4 PBKDF2 (250K, current).
  /// Uses constant-time comparison to prevent timing attacks.
  /// Runs in an isolate via compute() to avoid blocking the UI.
  static Future<bool> verifyPin(String pin, String stored) {
    if (!useIsolateForPin) {
      return Future.value(_verifyPinIsolate(_PinVerifyArgs(pin, stored)));
    }
    return compute(_verifyPinIsolate, _PinVerifyArgs(pin, stored));
  }

  /// Synchronous version for use in tests (compute() doesn't work in test).
  @visibleForTesting
  static bool verifyPinSync(String pin, String stored) =>
      _verifyPinIsolate(_PinVerifyArgs(pin, stored));

  static bool _verifyPinIsolate(_PinVerifyArgs args) {
    if (args.stored.startsWith('v4:') || args.stored.startsWith('v3:')) {
      // v3 + v4 share the same format: "vN:iterations:base64salt:base64hash".
      // Only the default iteration count differs; the stored iteration
      // count is the source of truth so existing v3 hashes still verify
      // with their original 100K count until they're upgraded to v4.
      final parts = args.stored.split(':');
      if (parts.length != 4) return false;
      final iterations = int.tryParse(parts[1]);
      if (iterations == null) return false;
      final salt = base64Decode(parts[2]);
      final expectedHash = base64Decode(parts[3]);
      final hash = _pbkdf2(args.pin, salt, iterations: iterations);
      return _constantTimeEqualsBytes(hash, expectedHash);
    } else if (args.stored.startsWith('v2:')) {
      // v2 format: "v2:base64salt:base64hash" (always 600K iterations)
      final parts = args.stored.split(':');
      if (parts.length != 3) return false;
      final salt = base64Decode(parts[1]);
      final expectedHash = base64Decode(parts[2]);
      final hash = _pbkdf2(args.pin, salt, iterations: _v2LegacyIterations);
      return _constantTimeEqualsBytes(hash, expectedHash);
    } else {
      // Legacy SHA-256 format: "base64salt:hexhash"
      final parts = args.stored.split(':');
      if (parts.length != 2) return false;
      final saltStr = parts[0];
      final expectedHash = parts[1];
      final hash =
          sha256.convert(utf8.encode('$saltStr:${args.pin}')).toString();
      return _constantTimeEquals(hash, expectedHash);
    }
  }

  /// Check if a stored hash uses a legacy format. Triggers the caller
  /// to re-hash with [hashPin] on next successful unlock and persist.
  ///
  /// v3 (100K PBKDF2) is now considered legacy alongside
  /// SHA-256 and v2, so existing v3 hashes auto-upgrade to v4 (250K).
  /// Only hashes prefixed with v4: are treated as current.
  static bool isLegacyPinHash(String stored) => !stored.startsWith('v4:');

  /// Constant-time string comparison to prevent timing attacks.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Constant-time byte list comparison.
  static bool _constantTimeEqualsBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// Arguments for PIN verification in isolate.
class _PinVerifyArgs {
  final String pin;
  final String stored;
  const _PinVerifyArgs(this.pin, this.stored);
}
