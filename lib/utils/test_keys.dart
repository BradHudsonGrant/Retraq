import 'package:flutter/widgets.dart';

/// Centralized widget keys used by integration and widget tests.
///
/// These keys are *attached in production widget trees* so tests can look
/// them up — they are not themselves runtime-only. Prefer these over
/// text-based finders (`find.text`) in tests: they are resilient to copy
/// tweaks, localization, and theme changes, and they make it obvious at a
/// glance which widgets are test-surfaces vs. incidental.
///
/// Rules of thumb:
///   • Only attach keys to widgets tests actually need to tap / read / verify.
///   • For list rows and other dynamic items, use the `entryTile()` helper
///     rather than a static constant.
///   • If you rename a key, update every `find.byKey` site in one pass —
///     these strings are the stable contract between app and tests.
class TestKeys {
  TestKeys._();

  // ── App shell / navigation ──────────────────────────────────────────────
  static const navJournalTab = Key('nav_tab_journal');
  static const navRecapTab = Key('nav_tab_recap');
  static const navStatsTab = Key('nav_tab_stats');
  static const navSettingsTab = Key('nav_tab_settings');

  // ── Home / Journal screen ───────────────────────────────────────────────
  static const homeDateChip = Key('home_date_chip');
  static const homeMoodSelector = Key('home_mood_selector');
  static const homeTitleField = Key('home_title_field');
  static const homeEntryField = Key('home_entry_field');
  static const homeSaveButton = Key('home_save_button');
  static const homeAmPmToggle = Key('home_ampm_toggle');

  /// Dynamic key for a mood option button (1..5).
  static Key moodOption(int value) => Key('mood_option_$value');

  // ── Recap screen ────────────────────────────────────────────────────────
  static const recapSearchToggle = Key('recap_search_toggle');
  static const recapSearchField = Key('recap_search_field');
  // Task 2.5 — Entries/Insights top-level pill. When right is active,
  // the embedded StatsScreen renders inside the Recap pane (Stats tab
  // collapsed into Recap; NavigationBar dropped from 4 tabs to 3).
  static const recapEntriesInsightsPill =
      Key('recap_entries_insights_pill');
  static const recapWeekMonthToggle = Key('recap_week_month_toggle');
  static const recapPreviousWeek = Key('recap_previous_week');
  static const recapNextWeek = Key('recap_next_week');
  static const recapPreviousMonth = Key('recap_previous_month');
  static const recapNextMonth = Key('recap_next_month');

  /// Dynamic key for a single entry tile in lists (by entry id).
  static Key entryTile(int entryId) => Key('entry_tile_$entryId');

  /// Dynamic key for a calendar day cell (by day-of-month).
  static Key calendarDay(int day) => Key('calendar_day_$day');

  // ── Settings screen ─────────────────────────────────────────────────────
  static const settingsAppearanceSection = Key('settings_section_appearance');
  static const settingsPreferencesSection = Key('settings_section_preferences');
  static const settingsSecuritySection = Key('settings_section_security');
  static const settingsNudgeCard = Key('settings_nudge_card');
  static const settingsDataSection = Key('settings_section_data');
  static const settingsLegalFooter = Key('settings_legal_footer');
}
