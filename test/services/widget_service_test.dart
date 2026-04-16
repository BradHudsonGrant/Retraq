@Tags(['integration'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/database_service.dart';
import 'package:retraq/services/widget_service.dart';

import '../test_helpers.dart';

/// Tracks data saved via HomeWidget.saveWidgetData and updateWidget calls.
final Map<String, dynamic> _savedWidgetData = {};
bool _widgetUpdated = false;

void _mockHomeWidgetPlugin() {
  _savedWidgetData.clear();
  _widgetUpdated = false;
  const channel = MethodChannel('home_widget');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'setAppGroupId':
            return null;
          case 'saveWidgetData':
            final key = call.arguments['id'] as String;
            final value = call.arguments['data'];
            _savedWidgetData[key] = value;
            return true;
          case 'updateWidget':
            _widgetUpdated = true;
            return true;
          default:
            return null;
        }
      });
}

void main() {
  final db = DatabaseService.instance;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestDatabase();
  });

  setUp(() async {
    _mockHomeWidgetPlugin();
    // Clear all entries
    final all = await db.entries.getAllEntries();
    for (final e in all) {
      if (e.id != null) await db.entries.deleteEntry(e.id!);
    }
  });

  group('WidgetService.init', () {
    test('init calls setAppGroupId without error', () async {
      // Should not throw; mock handles setAppGroupId
      await WidgetService.instance.init();
    });
  });

  group('WidgetService.update', () {
    test('pushes correct keys with no entries', () async {
      await WidgetService.instance.update();

      expect(_savedWidgetData.containsKey('streak'), true);
      expect(_savedWidgetData.containsKey('totalEntries'), true);
      expect(_savedWidgetData.containsKey('lastEntryDate'), true);
      expect(_savedWidgetData.containsKey('mood'), true);
      expect(_widgetUpdated, true);
    });

    test('streak and totalEntries are 0 with no entries', () async {
      await WidgetService.instance.update();

      expect(_savedWidgetData['streak'], 0);
      expect(_savedWidgetData['totalEntries'], 0);
      expect(_savedWidgetData['lastEntryDate'], '');
      expect(_savedWidgetData['mood'], -1);
    });

    test(
      'Task 3.8 — skips DB read + HomeWidget push when app is locked',
      () async {
        // Seed an entry so the update WOULD produce visible data if it ran.
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        await db.entries.saveEntry(
          JournalEntry(
            date: today,
            entry: 'Should not appear on widget',
            mood: 5,
            createdAt: now,
          ),
        );

        // Pretend the app is locked.
        WidgetService.instance.isLockedChecker = () => true;
        try {
          await WidgetService.instance.update();

          // The mocked HomeWidget channel should NOT have received any
          // saveWidgetData or updateWidget calls.
          expect(
            _savedWidgetData,
            isEmpty,
            reason:
                'Widget must not push data while the app is locked (Task 3.8).',
          );
          expect(
            _widgetUpdated,
            isFalse,
            reason:
                'Widget refresh intent must not fire while the app is locked.',
          );
        } finally {
          WidgetService.instance.isLockedChecker = null;
        }
      },
    );

    test('Task 3.8 — proceeds normally when isLockedChecker returns false',
        () async {
      WidgetService.instance.isLockedChecker = () => false;
      try {
        await WidgetService.instance.update();
        expect(_savedWidgetData.containsKey('streak'), true);
        expect(_widgetUpdated, isTrue);
      } finally {
        WidgetService.instance.isLockedChecker = null;
      }
    });

    test('pushes correct data after saving an entry', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await db.entries.saveEntry(
        JournalEntry(
          date: today,
          entry: 'Widget test entry',
          mood: 4,
          createdAt: now,
        ),
      );

      await WidgetService.instance.update();

      expect(_savedWidgetData['totalEntries'], 1);
      expect(_savedWidgetData['mood'], 4);
      expect(_savedWidgetData['lastEntryDate'], isNotEmpty);
      expect(_widgetUpdated, true);
    });

    test('mood is -1 when entry has no mood set', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await db.entries.saveEntry(
        JournalEntry(date: today, entry: 'No mood entry', createdAt: now),
      );

      await WidgetService.instance.update();

      expect(_savedWidgetData['mood'], -1);
    });
  });
}
