@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/screens/lock_screen.dart';
import 'package:retraq/services/database_service.dart';
import 'package:retraq/widgets/molecules/number_pad.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

/// Mock FlutterSecureStorage plugin channel for tests.
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockSecureStorage();
  });

  tearDownAll(() {
    resetTestDatabase();
  });

  /// Helper: set a known PIN in the database.
  Future<void> setPin(String pin) async {
    final hash = PinService.hashPinSync(pin);
    final settings = await DatabaseService.instance.settings.getSettings();
    await DatabaseService.instance.settings.saveSettings(
      settings.copyWith(appLockEnabled: true, pinHash: hash),
    );
  }

  /// Build lock screen and wait for async init to complete.
  Future<void> buildLockScreen(
    WidgetTester tester, {
    VoidCallback? onUnlocked,
  }) async {
    await tester.pumpWidget(
      wrapScreen(LockScreen(onUnlocked: onUnlocked ?? () {})),
    );
    // Let the async _loadSettings() chain resolve:
    // 1. db.getSettings() resolves -> sets _settings
    // 2. SharedPreferences.getInstance() resolves -> reads lockout state
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Tap a digit, then let the compute() isolate run if a verify was triggered.
  Future<void> tapDigit(WidgetTester tester, String digit) async {
    await tester.tap(find.text(digit));
    await tester.pump();
    // Let any pending compute() isolate work complete.
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }

  /// Enter a full PIN sequence, one digit at a time with async settlement.
  Future<void> enterPin(WidgetTester tester, List<String> digits) async {
    for (final d in digits) {
      await tapDigit(tester, d);
    }
  }

  group('LockScreen', () {
    testWidgets('renders PIN entry prompt', (tester) async {
      await setPin('1234');
      await buildLockScreen(tester);
      expect(find.text('Enter your PIN'), findsOneWidget);
    });

    testWidgets('renders 4 PIN dots', (tester) async {
      await setPin('1234');
      await buildLockScreen(tester);

      expect(find.byType(PinDots), findsOneWidget);
      final dots = tester.widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(PinDots),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(dots.length, 4);
    });

    testWidgets('renders number pad with digits 0-9', (tester) async {
      await setPin('1234');
      await buildLockScreen(tester);

      for (var i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('renders delete button', (tester) async {
      await setPin('1234');
      await buildLockScreen(tester);
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('correct 4-digit PIN unlocks', (tester) async {
      await setPin('1234');
      var unlocked = false;
      await buildLockScreen(tester, onUnlocked: () => unlocked = true);

      await enterPin(tester, ['1', '2', '3', '4']);

      expect(unlocked, true);
    });

    testWidgets('wrong 4-digit PIN shows error', (tester) async {
      await setPin('1234');
      await buildLockScreen(tester);

      await enterPin(tester, ['9', '9', '9', '9']);

      expect(find.text('Wrong PIN. 4 attempts remaining.'), findsOneWidget);
    });

    testWidgets('delete button removes last digit', (tester) async {
      await setPin('1234');
      await buildLockScreen(tester);

      // Enter a digit then delete
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      // Enter correct PIN from scratch
      await enterPin(tester, ['1', '2', '3', '4']);
      expect(find.text('Wrong PIN. Try again.'), findsNothing);
    });

    testWidgets('5 failed attempts triggers lockout', (tester) async {
      await setPin('1234');
      await buildLockScreen(tester);

      // 5 wrong 4-digit PINs
      for (var attempt = 0; attempt < 5; attempt++) {
        await enterPin(tester, ['9', '9', '9', '9']);
      }

      expect(find.textContaining('Too many attempts'), findsOneWidget);
    });

    testWidgets('number pad disabled during lockout', (tester) async {
      await setPin('1234');
      await buildLockScreen(tester);

      // Trigger lockout
      for (var attempt = 0; attempt < 5; attempt++) {
        await enterPin(tester, ['9', '9', '9', '9']);
      }

      // NumberPad should be in disabled state (opacity 0.3)
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.3);
    });
  });
}
