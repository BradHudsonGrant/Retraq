import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Thin injectable abstraction over `package:local_auth`.
///
/// Task 6.3 — `lock_screen.dart` previously instantiated
/// `LocalAuthentication()` directly, which made every biometric
/// branch (success / user-cancel / notAvailable / notEnrolled /
/// lockedOut) impossible to test without bringing up a real
/// platform-channel mock. The modern local_auth package uses
/// Pigeon-generated BasicMessageChannels, which make direct
/// MethodChannel mocking intractable — so we wrap it in a small
/// interface and inject a fake in tests.
///
/// Production callers receive [PlatformBiometricAuthenticator] as
/// the default; tests construct a [FakeBiometricAuthenticator] or
/// hand-roll their own stub.
///
/// The surface is deliberately narrow: we only need the two paths
/// Retraq actually uses — "is this device capable?" and
/// "authenticate me now." Any future expansion (pre-warming,
/// cancelling in-flight auth) should extend this interface rather
/// than reach for `LocalAuthentication` directly.
abstract class BiometricAuthenticator {
  /// Does the device expose a biometric sensor the user has
  /// enrolled? Returns `false` on unsupported devices and when any
  /// platform exception fires (fail-safe default; UI hides the
  /// biometric affordance in that case).
  Future<bool> isAvailable();

  /// Run the OS biometric prompt. Returns the outcome; the caller
  /// decides UX (auto-retry, show PIN fallback, etc.).
  Future<BiometricOutcome> authenticate({
    required String reason,
    bool persistAcrossBackgrounding = true,
    bool biometricOnly = true,
  });
}

/// Result categories of a biometric authentication attempt.
///
/// Pinning a named enum rather than returning raw `bool` makes
/// test assertions explicit — "the user cancelled" and
/// "the device has no biometric" are semantically different even
/// though `local_auth.authenticate` collapses both to `false`.
enum BiometricOutcome {
  /// The OS prompt succeeded.
  success,

  /// The user explicitly cancelled or dismissed the prompt.
  userCancelled,

  /// The device has no biometric sensor or no enrolled biometric.
  notAvailable,

  /// The device is temporarily locked out (too many failed tries).
  lockedOut,

  /// The user has not enrolled a biometric; deep-link to OS settings.
  notEnrolled,

  /// Unknown / platform exception.
  error,
}

/// Production implementation over `package:local_auth`.
///
/// Translates the raw `authenticate` bool + `PlatformException.code`
/// into a [BiometricOutcome]. All exception translation lives here
/// so callers don't have to know the error-code lexicon.
class PlatformBiometricAuthenticator implements BiometricAuthenticator {
  PlatformBiometricAuthenticator({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e, st) {
      debugPrint('BiometricAuthenticator.isAvailable failed: $e\n$st');
      return false;
    }
  }

  @override
  Future<BiometricOutcome> authenticate({
    required String reason,
    bool persistAcrossBackgrounding = true,
    bool biometricOnly = true,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: persistAcrossBackgrounding,
      );
      return ok ? BiometricOutcome.success : BiometricOutcome.userCancelled;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotAvailable':
          return BiometricOutcome.notAvailable;
        case 'NotEnrolled':
          return BiometricOutcome.notEnrolled;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return BiometricOutcome.lockedOut;
        default:
          debugPrint(
            'BiometricAuthenticator.authenticate unexpected code ${e.code}: $e',
          );
          return BiometricOutcome.error;
      }
    }
  }
}
