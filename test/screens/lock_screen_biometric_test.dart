@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/screens/lock_screen.dart';
import 'package:retraq/services/biometric_auth.dart';
import 'package:retraq/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

/// Task 6.3 (widget layer) — LockScreen biometric flow coverage.
///
/// `biometric_auth_test.dart` exercises the BiometricAuthenticator
/// abstraction in isolation. This file wires a fake authenticator
/// into the actual LockScreen widget and pins:
///
/// 1. `BiometricOutcome.success` invokes the onUnlocked callback.
/// 2. `biometricEnabled=false` suppresses the prompt entirely —
///    users who disabled biometric must not get surprise Face ID
///    prompts.
///
/// The "cancelled" / "notAvailable" branches are covered
/// sufficiently at the abstraction layer (see biometric_auth_test.dart
/// outcome-distinction cases). Repeating them through the full
/// widget harness would add flake risk around async DB + settings
/// reloads without materially improving guarantees — the branches
/// in _tryBiometric are minimal and grep-visible.
///
/// Tagged `integration` so this runs in the dedicated integration
/// lane, not the PR-gate fast lane (real in-memory Drift DB +
/// mocked secure storage isn't cheap).
class _FakeAuthenticator implements BiometricAuthenticator {
  _FakeAuthenticator(this.outcome);

  final BiometricOutcome outcome;
  int authenticateCalls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<BiometricOutcome> authenticate({
    required String reason,
    bool persistAcrossBackgrounding = true,
    bool biometricOnly = true,
  }) async {
    authenticateCalls += 1;
    return outcome;
  }
}

void _mockSecureStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final storage = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'read':
        return storage[call.arguments['key']];
      case 'write':
        storage[call.arguments['key']] = call.arguments['value'] as String;
        return null;
      case 'delete':
        storage.remove(call.arguments['key']);
        return null;
      case 'deleteAll':
        storage.clear();
        return null;
      default:
        return null;
    }
  });
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _mockSecureStorage();
    await initTestDatabase(fastPbkdf2: true);
  });

  tearDownAll(resetTestDatabase);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockSecureStorage();
  });

  tearDown(() async {
    await DatabaseService.instance.userRepo.deleteAllData();
  });

  testWidgets(
    'biometric success invokes onUnlocked without PIN entry',
    (tester) async {
      final hash = PinService.hashPinSync('1234');
      final settings = await DatabaseService.instance.settings.getSettings();
      await DatabaseService.instance.settings.saveSettings(
        settings.copyWith(
          appLockEnabled: true,
          pinHash: hash,
          biometricEnabled: true,
        ),
      );

      var unlockCount = 0;
      final fake = _FakeAuthenticator(BiometricOutcome.success);

      await tester.pumpWidget(wrapScreen(LockScreen(
        onUnlocked: () => unlockCount += 1,
        biometric: fake,
      )));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fake.authenticateCalls, 1,
          reason: 'LockScreen must invoke biometric when enabled');
      expect(unlockCount, 1,
          reason: 'BiometricOutcome.success must unlock the app');
    },
  );

  testWidgets(
    'biometric NOT attempted when biometricEnabled=false',
    (tester) async {
      // Seed PIN WITHOUT biometric enabled.
      final hash = PinService.hashPinSync('1234');
      final settings = await DatabaseService.instance.settings.getSettings();
      await DatabaseService.instance.settings.saveSettings(
        settings.copyWith(
          appLockEnabled: true,
          pinHash: hash,
          biometricEnabled: false,
        ),
      );

      final fake = _FakeAuthenticator(BiometricOutcome.success);
      await tester.pumpWidget(wrapScreen(LockScreen(
        onUnlocked: () {},
        biometric: fake,
      )));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fake.authenticateCalls, 0,
          reason:
              'biometricEnabled=false must suppress the auto-prompt; '
              'otherwise users who disabled biometric get surprise '
              'Face ID prompts.');
    },
  );
}
