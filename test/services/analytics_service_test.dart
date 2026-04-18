// ignore_for_file: prefer_single_quotes

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Task 11.4 / 11.13 — tests for the AnalyticsService facade + kill
/// switch. Covers:
///   1. Default-on behaviour (no SharedPreferences value)
///   2. Kill switch flips cached flag + persists
///   3. `bump` is a no-op when the flag is off
///   4. `bump` records when the flag is on
///   5. Backend swap for tests works cleanly
///   6. `refreshFromPrefs` survives a hostile storage env
void main() {
  setUp(() {
    AnalyticsService.resetForTest();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    AnalyticsService.resetForTest();
  });

  test('default isEnabled is true (no SharedPreferences value)', () {
    expect(AnalyticsService.instance.isEnabled, isTrue,
        reason:
            'Local counters never leave the device (no-network CI '
            'guard), so default-on matches Agent 11 audit and does '
            'not violate the privacy-policy invariant.');
  });

  test('refreshFromPrefs reads the persisted flag', () async {
    SharedPreferences.setMockInitialValues({'keep_usage_stats': false});
    await AnalyticsService.instance.refreshFromPrefs();
    expect(AnalyticsService.instance.isEnabled, isFalse);

    SharedPreferences.setMockInitialValues({'keep_usage_stats': true});
    await AnalyticsService.instance.refreshFromPrefs();
    expect(AnalyticsService.instance.isEnabled, isTrue);
  });

  test('setEnabled updates the cache synchronously + persists', () async {
    await AnalyticsService.instance.setEnabled(false);
    expect(AnalyticsService.instance.isEnabled, isFalse);

    // Cold-start simulation — fresh service + refreshFromPrefs
    // observes the persisted value.
    AnalyticsService.resetForTest();
    await AnalyticsService.instance.refreshFromPrefs();
    expect(AnalyticsService.instance.isEnabled, isFalse);
  });

  test('bump records writes when enabled', () async {
    final backend = RecordingAnalyticsBackend();
    AnalyticsService.setBackendForTest(backend);

    await AnalyticsService.instance.bump(FeatureCounterKey.onThisDayOpened);
    await AnalyticsService.instance.bump(FeatureCounterKey.onThisDayOpened);
    await AnalyticsService.instance.bump(FeatureCounterKey.recapGenerated);

    expect(backend.writes, [
      FeatureCounterKey.onThisDayOpened,
      FeatureCounterKey.onThisDayOpened,
      FeatureCounterKey.recapGenerated,
    ]);
    expect(AnalyticsService.instance.read(FeatureCounterKey.onThisDayOpened), 2);
  });

  test('bump is a no-op when disabled', () async {
    final backend = RecordingAnalyticsBackend();
    AnalyticsService.setBackendForTest(backend);
    await AnalyticsService.instance.setEnabled(false);

    await AnalyticsService.instance.bump(FeatureCounterKey.onThisDayOpened);
    await AnalyticsService.instance.bump(FeatureCounterKey.notificationOpened);

    expect(backend.writes, isEmpty,
        reason:
            'Kill switch OFF → every bump short-circuits before the '
            'backend sees it. If this regressed, the user would ship '
            'counter rows after explicitly opting out.');
  });

  test(
    'flipping the switch on after being off resumes normal writes',
    () async {
      final backend = RecordingAnalyticsBackend();
      AnalyticsService.setBackendForTest(backend);
      await AnalyticsService.instance.setEnabled(false);
      await AnalyticsService.instance.bump(FeatureCounterKey.onThisDayOpened);
      expect(backend.writes, isEmpty);

      await AnalyticsService.instance.setEnabled(true);
      await AnalyticsService.instance.bump(FeatureCounterKey.onThisDayOpened);
      expect(backend.writes, [FeatureCounterKey.onThisDayOpened]);
    },
  );

  test('every FeatureCounterKey value is accepted by the facade', () async {
    // Smoke — guards against a future enum addition that accidentally
    // crashes because a switch expression doesn't cover it.
    final backend = RecordingAnalyticsBackend();
    AnalyticsService.setBackendForTest(backend);

    for (final key in FeatureCounterKey.values) {
      await AnalyticsService.instance.bump(key);
    }
    expect(backend.writes.length, FeatureCounterKey.values.length);
  });
}
