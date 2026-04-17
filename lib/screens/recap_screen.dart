import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:retraq/l10n/app_localizations.dart';

import '../models/journal_entry.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/entry_repository.dart';
// Task 1.14 — WeeklySummary type still flows through this screen; pulled
// from the service file.
import '../services/recap_service.dart' show WeeklySummary;
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../utils/date_helpers.dart';
import '../widgets/atoms/retraq_logo.dart';
import '../utils/entry_action_dialogs.dart';
import '../utils/test_keys.dart';
import '../widgets/atoms/glow_box.dart';
import '../widgets/molecules/segmented_pill.dart';
import 'recap/month_view.dart';
import 'recap/search_view.dart';
import 'recap/week_view.dart';
import 'stats_screen.dart' show StatsScreen;

/// Recap screen — browse entries by week/month and search.
class RecapScreen extends StatefulWidget {
  const RecapScreen({super.key});

  @override
  State<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends State<RecapScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final EntryRepository _entries = DatabaseService.instance.entries;
  // Task 1.14 — pull RecapService from the DatabaseService facade
  // instead of instantiating locally. Keeps recap access consistent
  // with db.entries / db.stats / etc., and lets future tests inject
  // a fake by swapping the DatabaseService instance.
  final _recapService = DatabaseService.instance.recap;

  // View toggle
  bool _isWeekView = true;

  // Task 2.5 — top-level Entries/Insights pill state. When true,
  // the embedded StatsScreen renders instead of the Week/Month
  // browse view. Search view is always Entries-only (search results
  // don't belong in the Insights pane).
  bool _showInsights = false;

  // Search state
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<JournalEntry> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _showSearch = false;

  // Week entries + navigation
  List<JournalEntry> _weekEntries = [];
  UserSettings? _settings;
  WeeklySummary? _weeklySummary;
  int _weekOffset = 0; // 0 = current week, -1 = last week, etc.

  // Calendar state
  late DateTime _selectedMonth;
  int? _selectedDay;
  Set<int> _entryDays = {};
  Map<int, int> _dayMoods = {};
  List<JournalEntry> _monthEntries = []; // all entries for the month
  List<JournalEntry> _selectedEntries = []; // entries for selected day

  // Subscriptions
  StreamSubscription<List<JournalEntry>>? _weekEntriesSub;
  StreamSubscription<List<JournalEntry>>? _entrySub;
  StreamSubscription<List<JournalEntry>>? _monthEntriesSub;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    _listenToMonthData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = SettingsProvider.maybeOf(context);
    if (s != null && s != _settings) {
      final oldStart = _settings?.weekStartDay;
      _settings = s;
      if (oldStart != s.weekStartDay || _weekEntriesSub == null) {
        _weekOffset = 0;
        _subscribeWeekEntries(s.weekStartDay);
      }
    }
  }

  /// Calculate the start of the week for a given offset from current week.
  DateTime _weekStartForOffset(int weekStartDay) {
    final currentWeekStart = weekStartDate(weekStartDay: weekStartDay);
    return currentWeekStart.add(Duration(days: _weekOffset * 7));
  }

  void _subscribeWeekEntries(int weekStartDay) {
    _weekEntriesSub?.cancel();
    final weekStart = _weekStartForOffset(weekStartDay);

    _weekEntriesSub = _entries.watchWeekEntriesFrom(weekStart).listen((
      entries,
    ) {
      if (!mounted) return;
      setState(() => _weekEntries = entries);
      _loadWeeklySummary(weekStartDay);
    });
  }

  Future<void> _loadWeeklySummary(int weekStartDay) async {
    final weekStart = _weekStartForOffset(weekStartDay);
    final summary = await _recapService.getWeeklySummary(
      weekStart,
      weekStartDay,
    );
    if (!mounted) return;
    setState(() => _weeklySummary = summary);
  }

  void _goToPreviousWeek() {
    setState(() => _weekOffset -= 1);
    _subscribeWeekEntries(_settings?.weekStartDay ?? 1);
  }

  void _goToNextWeek() {
    if (_weekOffset >= 0) return; // can't go past current week
    setState(() => _weekOffset += 1);
    _subscribeWeekEntries(_settings?.weekStartDay ?? 1);
  }

  void _listenToMonthData() {
    _monthEntriesSub?.cancel();
    _monthEntriesSub = _entries.watchMonthEntries(_selectedMonth).listen((
      entries,
    ) {
      if (!mounted) return;

      // Derive entry days and mood map from the full entries list,
      // avoiding two extra database queries.
      final days = <int>{};
      final moods = <int, int>{};
      for (final e in entries) {
        final day = e.date.day;
        days.add(day);
        if (e.mood != null) {
          // Last entry's mood wins (entries are ordered by date ASC).
          moods[day] = e.mood!;
        }
      }

      setState(() {
        _monthEntries = entries;
        _entryDays = days;
        _dayMoods = moods;
      });
    });
  }

  void _onDaySelected(int day) {
    if (_selectedDay == day) {
      // Tapping the same day again — deselect and go back to full month
      setState(() {
        _selectedDay = null;
        _selectedEntries = [];
      });
      _entrySub?.cancel();
      return;
    }

    setState(() => _selectedDay = day);
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);

    _entrySub?.cancel();
    _entrySub = _entries.watchEntriesForDate(date).listen((entries) {
      if (!mounted) return;
      setState(() => _selectedEntries = entries);
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDay = null;
      _selectedEntries = [];
      _monthEntries = [];
      _dayMoods = {};
    });
    _entrySub?.cancel();
    _listenToMonthData();
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final nextMonth =
        (_selectedMonth.month == 12)
            ? DateTime(_selectedMonth.year + 1, 1)
            : DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final currentMonthEnd =
        (now.month == 12)
            ? DateTime(now.year + 1, 1)
            : DateTime(now.year, now.month + 1);
    if (nextMonth.isAfter(currentMonthEnd)) return;

    setState(() {
      _selectedMonth = nextMonth;
      _selectedDay = null;
      _selectedEntries = [];
      _monthEntries = [];
      _dayMoods = {};
    });
    _entrySub?.cancel();
    _listenToMonthData();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _entries.searchEntries(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
      }
    });
  }

  Future<void> _confirmEditEntry(JournalEntry entry) async {
    final changed = await confirmAndEditEntry(context, entry);
    if (changed && _searchController.text.trim().isNotEmpty) {
      _onSearchChanged(_searchController.text);
    }
  }

  Future<void> _confirmDeleteEntry(JournalEntry entry) async {
    final deleted = await confirmAndDeleteEntry(context, entry);
    if (deleted && mounted && _searchController.text.trim().isNotEmpty) {
      _onSearchChanged(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _weekEntriesSub?.cancel();
    _entrySub?.cancel();
    _monthEntriesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l10n = L10n.of(context)!;
    final weekStartDay = _settings?.weekStartDay ?? 1;

    final searchButton = IconButton(
      key: TestKeys.recapSearchToggle,
      icon: Icon(_showSearch ? Icons.close : Icons.search),
      onPressed: _toggleSearch,
      tooltip: _showSearch ? l10n.closeSearch : l10n.searchEntries,
    );

    final headerRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Animate(
          effects: [
            FadeEffect(duration: 480.ms, curve: Curves.easeOut),
            SlideEffect(
              begin: const Offset(-0.05, 0),
              end: Offset.zero,
              duration: 520.ms,
              curve: AppMotion.emphasizedDecelerate,
            ),
          ],
          child: Row(
            children: [
              const RetraqLogo(size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.recapTitle,
                style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Animate(
          effects: [
            FadeEffect(delay: 80.ms, duration: 420.ms, curve: Curves.easeOut),
            ScaleEffect(
              delay: 80.ms,
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              duration: 460.ms,
              curve: AppMotion.springSmooth,
            ),
          ],
          child:
              _showSearch
                  ? GlowBox(
                    color: cs.primary,
                    glowOpacity: 0.45,
                    blurRadius: 22,
                    spreadRadius: 1,
                    shape: BoxShape.circle,
                    child: searchButton,
                  )
                  : searchButton,
        ),
      ],
    );

    final scrollView = SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // ── Header with search toggle ──
          headerRow,

          // ── Search view (expandable) ──
          if (_showSearch)
            RecapSearchView(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              searchResults: _searchResults,
              isSearching: _isSearching,
              hasSearched: _hasSearched,
              onEdit: _confirmEditEntry,
              onDelete: _confirmDeleteEntry,
            ),

          // ── Browse view (when not searching) ──
          if (!_showSearch) ...[
            const SizedBox(height: AppSpacing.md),

            // Task 2.5 — top-level Entries / Insights pill. Replaces
            // the removed Stats bottom-nav tab. Browse body swaps
            // between the existing Week/Month entries view and the
            // embedded StatsScreen(embedded: true).
            Center(
              child: SegmentedPill(
                key: TestKeys.recapEntriesInsightsPill,
                leftLabel: l10n.entriesLabel,
                rightLabel: l10n.insightsLabel,
                isRightActive: _showInsights,
                onTapLeft: () => setState(() => _showInsights = false),
                onTapRight: () => setState(() => _showInsights = true),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Insights pane ──
            if (_showInsights)
              const StatsScreen(embedded: true),

            // ── Entries pane (Week/Month toggle + views) ──
            if (!_showInsights) ...[
              // ── Week / Month toggle ──
              Center(
                child: SegmentedPill(
                  key: TestKeys.recapWeekMonthToggle,
                  // Task 2.2 — localize via existing ARB keys.
                  leftLabel: l10n.weekLabel,
                  rightLabel: l10n.monthLabel,
                  isRightActive: !_isWeekView,
                  onTapLeft: () => setState(() => _isWeekView = true),
                  onTapRight: () => setState(() => _isWeekView = false),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

            // ── Week view ──
            if (_isWeekView)
              RecapWeekView(
                weekEntries: _weekEntries,
                weekStartDay: weekStartDay,
                weeklySummary: _weeklySummary,
                weekOffset: _weekOffset,
                weekStart: _weekStartForOffset(weekStartDay),
                onPreviousWeek: _goToPreviousWeek,
                onNextWeek: _weekOffset < 0 ? _goToNextWeek : null,
                onDaySelected: (date) {
                  // Switch to month view and select the day
                  if (date.month != _selectedMonth.month ||
                      date.year != _selectedMonth.year) {
                    setState(() {
                      _selectedMonth = DateTime(date.year, date.month);
                    });
                    _listenToMonthData();
                  }
                  setState(() => _isWeekView = false);
                  _onDaySelected(date.day);
                },
              ),

              // ── Month view ──
              if (!_isWeekView)
                RecapMonthView(
                  selectedMonth: _selectedMonth,
                  entryDays: _entryDays,
                  dayMoods: _dayMoods,
                  selectedDay: _selectedDay,
                  monthEntries: _monthEntries,
                  selectedEntries: _selectedEntries,
                  weekStartDay: weekStartDay,
                  onDaySelected: _onDaySelected,
                  onPreviousMonth: _goToPreviousMonth,
                  onNextMonth: _goToNextMonth,
                ),
            ], // end Entries pane
          ], // end Browse view

          // ── Bottom padding for nav bar ──
          const SizedBox(height: AppSpacing.navBarClearance),
        ],
      ),
    );

    // Gradient sits OUTSIDE SafeArea so it extends behind the status bar,
    // blending the system chrome into the Recap header. Only the scroll
    // content respects the safe-area insets.
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 280,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.primary.withValues(alpha: 0.16),
                    cs.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(child: scrollView),
      ],
    );
  }
}
