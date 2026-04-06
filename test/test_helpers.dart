import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/user_settings.dart';
import 'package:retraq/providers/settings_provider.dart';
import 'package:retraq/services/database_service.dart';

/// Wraps a widget in MaterialApp + Scaffold for widget testing.
/// Use for screens and widgets that need a Scaffold ancestor.
Widget wrapWidget(Widget child, {UserSettings? settings}) {
  Widget app = MaterialApp(home: Scaffold(body: child));
  if (settings != null) {
    app = SettingsProvider(settings: settings, child: app);
  }
  return app;
}

/// Wraps a widget in MaterialApp only (no Scaffold).
/// Use for widgets that provide their own Scaffold (e.g. LockScreen).
Widget wrapScreen(Widget child, {UserSettings? settings}) {
  Widget app = MaterialApp(home: child);
  if (settings != null) {
    app = SettingsProvider(settings: settings, child: app);
  }
  return app;
}

/// Wraps a widget in MaterialApp + Scaffold + SingleChildScrollView.
/// Use for tall widgets that may overflow the test viewport.
Widget wrapScrollable(Widget child, {UserSettings? settings}) {
  Widget app = MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
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
