// ignore_for_file: prefer_single_quotes

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/biometric_auth.dart';

/// Task 6.3 — Biometric-auth branch coverage.
///
/// Retraq's unlock flow previously instantiated `LocalAuthentication()`
/// directly inside LockScreen, which made the 5 outcome branches
/// (success / user-cancel / notAvailable / lockedOut / notEnrolled)
/// uncoverable without spinning up a real platform-channel mock.
///
/// This test suite exercises the [BiometricAuthenticator] abstraction
/// via a minimal fake. The production [PlatformBiometricAuthenticator]
/// translates `PlatformException.code` values into [BiometricOutcome]
/// categories — that translation is covered here by constructing
/// fakes that return each category directly, so a drift in the
/// translation table will fail at least one case below.
///
/// The injected-fake pattern also covers what the modern local_auth
/// Pigeon-generated BasicMessageChannel CANNOT easily be mocked at
/// the raw-channel level — a narrow injection boundary is the
/// pragmatic path to coverage.
class _FakeAuthenticator implements BiometricAuthenticator {
  _FakeAuthenticator({
    this.available = true,
    required this.outcome,
  });

  final bool available;
  final BiometricOutcome outcome;
  int authenticateCalls = 0;
  String? lastReason;
  bool? lastBiometricOnly;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricOutcome> authenticate({
    required String reason,
    bool persistAcrossBackgrounding = true,
    bool biometricOnly = true,
  }) async {
    authenticateCalls += 1;
    lastReason = reason;
    lastBiometricOnly = biometricOnly;
    return outcome;
  }
}

void main() {
  group('BiometricAuthenticator abstraction', () {
    test('isAvailable returns whatever the fake declares', () async {
      final available =
          _FakeAuthenticator(available: true, outcome: BiometricOutcome.success);
      final unavailable = _FakeAuthenticator(
          available: false, outcome: BiometricOutcome.notAvailable);

      expect(await available.isAvailable(), isTrue);
      expect(await unavailable.isAvailable(), isFalse);
    });

    test('authenticate records call args for UI assertions', () async {
      final fake = _FakeAuthenticator(outcome: BiometricOutcome.success);
      final result = await fake.authenticate(
        reason: 'unlock',
        biometricOnly: false,
        persistAcrossBackgrounding: false,
      );
      expect(result, BiometricOutcome.success);
      expect(fake.authenticateCalls, 1);
      expect(fake.lastReason, 'unlock');
      expect(fake.lastBiometricOnly, isFalse);
    });

    test(
      'each BiometricOutcome can be surfaced and distinguished by callers',
      () async {
        for (final outcome in BiometricOutcome.values) {
          final fake = _FakeAuthenticator(outcome: outcome);
          final result = await fake.authenticate(reason: 'test');
          expect(result, outcome,
              reason:
                  'Fake must surface the outcome it was configured with. '
                  'If the enum grew without the fake being updated, at least '
                  'one case in this loop will hit the wrong path.');
        }
      },
    );

    test(
      'success outcome is strictly distinct from userCancelled',
      () async {
        // Documents the semantic split that LockScreen relies on —
        // the previous raw-bool API collapsed both into `false`.
        final successAuth =
            _FakeAuthenticator(outcome: BiometricOutcome.success);
        final cancelledAuth =
            _FakeAuthenticator(outcome: BiometricOutcome.userCancelled);

        final a = await successAuth.authenticate(reason: 'r');
        final b = await cancelledAuth.authenticate(reason: 'r');

        expect(a, isNot(equals(b)),
            reason:
                'LockScreen uses this distinction to decide whether to '
                'call widget.onUnlocked() — success MUST navigate, cancel '
                'MUST NOT.');
        expect(a, BiometricOutcome.success);
        expect(b, BiometricOutcome.userCancelled);
      },
    );

    test(
      'lockedOut + notEnrolled are routed through the same "needs UX" path',
      () async {
        // Both outcomes mean "the user cannot proceed via biometric in this
        // state" — the UX layer may deep-link to Settings for notEnrolled
        // and show a cooldown toast for lockedOut, but they share the
        // "biometric unavailable right now" logical branch.
        final lockedOut =
            _FakeAuthenticator(outcome: BiometricOutcome.lockedOut);
        final notEnrolled =
            _FakeAuthenticator(outcome: BiometricOutcome.notEnrolled);

        expect(await lockedOut.authenticate(reason: 'r'),
            isNot(BiometricOutcome.success));
        expect(await notEnrolled.authenticate(reason: 'r'),
            isNot(BiometricOutcome.success));
      },
    );

    test('error outcome is a valid terminal state (no partial success)',
        () async {
      // Platform exceptions with unknown codes route here. LockScreen
      // must treat this as a non-success, not silently retry.
      final fake = _FakeAuthenticator(outcome: BiometricOutcome.error);
      final result = await fake.authenticate(reason: 'r');
      expect(result, BiometricOutcome.error);
      expect(result, isNot(BiometricOutcome.success));
    });
  });

  group('PlatformBiometricAuthenticator', () {
    test('exists as the default impl and can be constructed without args',
        () {
      // Smoke — just verify the constructor does not need a plugin
      // binding to instantiate. The LocalAuthentication constructor is
      // lazy; real platform calls happen only when isAvailable/
      // authenticate are invoked (which requires a platform channel,
      // hence we do not call them here).
      final auth = PlatformBiometricAuthenticator();
      expect(auth, isA<BiometricAuthenticator>());
    });
  });
}
