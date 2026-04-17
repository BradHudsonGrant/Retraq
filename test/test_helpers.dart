// ─────────────────────────────────────────────────────────────────────────
// Test helper reference — preserved per review-2026-04-16 Agent 6 (Task 6.19).
//
// The four patterns defined here are deliberate architectural choices; do
// NOT bypass them without understanding why they exist:
//
//   1. `wrapWidget` / `wrapScreen` / `wrapScrollable` — MaterialApp +
//      l10n delegates + reduce-motion MediaQuery by default. New tests
//      that build their own MaterialApp miss localization + lose the
//      reduce-motion guard, leading to flaky pumpAndSettle runs.
//
//   2. `setUpFakeSecureStorage` — mocks ONLY the FlutterSecureStorage
//      MethodChannel. SQLite stays real (via Drift in-memory). This
//      catches migration/FK/trigger regressions that a fully-mocked
//      test suite would silently pass. If you're tempted to stub
//      SQLite too: don't — the 'real DB + mock platform channels'
//      line is what makes our migration tests meaningful.
//
//   3. `flushDriftTimers` — pumps one post-empty-tree frame to drain
//      Drift's StreamQueryStore.markAsClosed zero-duration timers.
//      Call at the end of ANY test that subscribes to a Drift stream.
//      Skipping it surfaces as 'pending timers' warnings and, over
//      time, hidden flakiness under FakeAsync.
//
//   4. TestKeys pattern (see lib/utils/test_keys.dart) — every
//      tappable surface has a Key in production code, and tests use
//      find.byKey(TestKeys.foo) instead of find.text('...'). This
//      makes copy refactors (ARB edits, rebranding) zero-impact on
//      tests. When adding a new screen, add a TestKey for every
//      meaningful tap target before writing the test.
//
// See Agent 6's review (2026-04-16) for the full rationale. Task 6.19
// exists specifically to make sure this file and its usage pattern
// survive future test-file consolidations.
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/l10n/app_localizations.dart';
import 'package:retraq/models/user_settings.dart';
import 'package:retraq/providers/settings_provider.dart';
import 'package:retraq/services/database_service.dart';

/// In-memory backing store for the mocked FlutterSecureStorage channel.
/// Reset between tests via [resetFakeSecureStorage].
final Map<String, String> _fakeSecureStorage = <String, String>{};

/// Installs a mock for the `flutter_secure_storage` platform channel so
/// `read`/`write`/`delete` calls return immediately in widget tests instead
/// of hanging on a missing platform implementation.
///
/// Call once from `setUpAll`. The backing store is shared across the suite;
/// call [resetFakeSecureStorage] in `setUp` if you need a clean slate per test.
void setUpFakeSecureStorage() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
        final args = (call.arguments as Map?)?.cast<String, dynamic>();
        final key = args?['key'] as String?;
        switch (call.method) {
          case 'read':
            return _fakeSecureStorage[key];
          case 'readAll':
            return Map<String, String>.from(_fakeSecureStorage);
          case 'write':
            final value = args?['value'] as String?;
            if (key != null && value != null) _fakeSecureStorage[key] = value;
            return null;
          case 'delete':
            if (key != null) _fakeSecureStorage.remove(key);
            return null;
          case 'deleteAll':
            _fakeSecureStorage.clear();
            return null;
          case 'containsKey':
            return _fakeSecureStorage.containsKey(key);
          default:
            return null;
        }
      });
}

/// Clears the in-memory secure storage backing store. Call in `setUp` if
/// tests must not see writes from previous tests in the same suite.
void resetFakeSecureStorage() {
  _fakeSecureStorage.clear();
}

/// Forces every widget under [child] to see `disableAnimations: true`.
/// This makes the new flutter_animate / Animate-based effects short-circuit
/// in tests so timers and tickers stay quiet for `pumpAndSettle`.
Widget _withReducedMotion(Widget child) {
  return Builder(
    builder: (context) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child,
      );
    },
  );
}

Widget _maybeReduceMotion(Widget child, {required bool enableAnimations}) {
  return enableAnimations ? child : _withReducedMotion(child);
}

/// Wraps a widget in MaterialApp + Scaffold for widget testing.
/// Use for screens and widgets that need a Scaffold ancestor.
///
/// By default, animations are reduced (disableAnimations=true) so widget
/// tests using `pumpAndSettle` converge cleanly. Pass [enableAnimations] true
/// for the rare test that asserts on animation widgets like AnimatedScale.
Widget wrapWidget(
  Widget child, {
  UserSettings? settings,
  bool enableAnimations = false,
}) {
  Widget app = MaterialApp(
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    home: _maybeReduceMotion(
      Scaffold(body: child),
      enableAnimations: enableAnimations,
    ),
  );
  if (settings != null) {
    app = SettingsProvider(settings: settings, child: app);
  }
  return app;
}

/// Wraps a widget in MaterialApp only (no Scaffold).
/// Use for widgets that provide their own Scaffold (e.g. LockScreen).
Widget wrapScreen(
  Widget child, {
  UserSettings? settings,
  bool enableAnimations = false,
}) {
  Widget app = MaterialApp(
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    home: _maybeReduceMotion(child, enableAnimations: enableAnimations),
  );
  if (settings != null) {
    app = SettingsProvider(settings: settings, child: app);
  }
  return app;
}

/// Wraps a widget in MaterialApp + Scaffold + SingleChildScrollView.
/// Use for tall widgets that may overflow the test viewport.
Widget wrapScrollable(
  Widget child, {
  UserSettings? settings,
  bool enableAnimations = false,
}) {
  Widget app = MaterialApp(
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    home: _maybeReduceMotion(
      Scaffold(body: SingleChildScrollView(child: child)),
      enableAnimations: enableAnimations,
    ),
  );
  if (settings != null) {
    app = SettingsProvider(settings: settings, child: app);
  }
  return app;
}

/// Flushes Drift's StreamQueryStore zero-duration timers that would
/// otherwise cause "pending timers" warnings in FakeAsync.
/// Call at the end of every test that uses Drift streams.
Future<void> flushDriftTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

/// Standard setUpAll for integration tests that need an in-memory database.
/// Initialises the database and optionally sets fast PBKDF2 iterations.
Future<void> initTestDatabase({bool fastPbkdf2 = false}) async {
  if (fastPbkdf2) {
    PinService.setPbkdf2Iterations(100);
  }
  await DatabaseService.instance.initInMemory();
}

/// Standard tearDownAll for tests that used fast PBKDF2 iterations.
void resetTestDatabase() {
  PinService.resetPbkdf2Iterations();
}
