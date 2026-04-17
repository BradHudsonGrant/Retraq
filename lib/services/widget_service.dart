import 'package:home_widget/home_widget.dart';

import 'app_log.dart';
import 'database_service.dart';

/// Pushes journal stats to the native home screen widget.
///
/// Data keys shared with the Android widget provider:
/// - `streak` (int): current journaling streak in days
/// - `totalEntries` (int): lifetime entry count
/// - `lastEntryDate` (String): ISO-8601 date of the most recent entry
/// - `mood` (int?): mood value of the latest entry (1-5), or -1 if none
///
/// Task 3.8 — Widget MUST NOT read the DB while the app is locked.
/// The widget shows streak/entry-count/mood — mood is the main privacy
/// concern. A thief with the locked phone could otherwise see updated
/// mood after the legitimate user's lock-protected session ended.
///
/// This is enforced in TWO layers:
///   1. `update()` is called only from contexts where the app is
///      unlocked (home_screen.dart:779 after a save; main.dart:108
///      post-first-frame before lock is checked, but init path only
///      runs on an unlocked app session).
///   2. `isLockedChecker` is a top-level hook that main.dart wires to
///      the app-lock state. If set and true, `update()` returns
///      early without touching the DB or HomeWidget.
class WidgetService {
  WidgetService._();
  static final instance = WidgetService._();

  static const _androidWidgetName = 'JournalWidget';
  static const _appGroupId = 'group.com.retraq.app';

  /// Task 3.8 — Wired by main.dart from `_isLocked` state. When true,
  /// widget updates are skipped to avoid reading the DB while the app
  /// is locked at the UI layer. Null (unset) is treated as unlocked
  /// for backward compatibility; callers without the hook get the
  /// previous behavior.
  bool Function()? isLockedChecker;

  /// Initialise the home_widget plugin (call once at startup).
  Future<void> init() async {
    try {
      HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      AppLog.warn('WidgetService.init', 'non-fatal init failure: $e');
    }
  }

  /// Refresh widget data from the database and push to native widgets.
  Future<void> update() async {
    // Task 3.8 — skip when the app is locked. Do NOT log — the widget
    // refresh is a routine background event and spamming logs adds
    // noise. If diagnostics are ever needed, instrument via
    // feature_counters (Epic 11 Task 11.4).
    if (isLockedChecker?.call() ?? false) {
      return;
    }
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
      AppLog.warn('WidgetService.update', 'non-fatal update failure: $e');
    }
  }
}
