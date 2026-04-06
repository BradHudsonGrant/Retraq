import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'database_service.dart';

/// Pushes journal stats to the native home screen widget.
///
/// Data keys shared with the Android widget provider:
/// - `streak` (int): current journaling streak in days
/// - `totalEntries` (int): lifetime entry count
/// - `lastEntryDate` (String): ISO-8601 date of the most recent entry
/// - `mood` (int?): mood value of the latest entry (1-5), or -1 if none
class WidgetService {
  WidgetService._();
  static final instance = WidgetService._();

  static const _androidWidgetName = 'JournalWidget';
  static const _appGroupId = 'group.com.retraq.app';

  /// Initialise the home_widget plugin (call once at startup).
  Future<void> init() async {
    try {
      HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      debugPrint('WidgetService init failed (non-fatal): $e');
    }
  }

  /// Refresh widget data from the database and push to native widgets.
  Future<void> update() async {
    try {
      final db = DatabaseService.instance;
      // Use lightweight query instead of full getAllStats().
      final widgetData = await db.stats.getWidgetData();

      // Find the latest entry's mood (if any).
      final entries = await db.entries.getEntriesForDate(DateTime.now());
      final latestMood = entries.isNotEmpty ? (entries.first.mood ?? -1) : -1;
      final lastDate =
          entries.isNotEmpty
              ? entries.first.createdAt.toIso8601String().substring(0, 10)
              : '';

      await Future.wait([
        HomeWidget.saveWidgetData<int>('streak', widgetData.currentStreak),
        HomeWidget.saveWidgetData<int>('totalEntries', widgetData.totalEntries),
        HomeWidget.saveWidgetData<String>('lastEntryDate', lastDate),
        HomeWidget.saveWidgetData<int>('mood', latestMood),
      ]);

      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e) {
      debugPrint('WidgetService update failed (non-fatal): $e');
    }
  }
}
