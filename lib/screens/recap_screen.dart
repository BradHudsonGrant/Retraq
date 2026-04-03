import 'dart:async';
import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/entry_repository.dart';
import '../services/recap_service.dart';
import '../theme/app_spacing.dart';
import '../utils/date_helpers.dart';
import '../utils/entry_action_dialogs.dart';
import '../widgets/molecules/segmented_pill.dart';
import 'recap/month_view.dart';
import 'recap/search_view.dart';
import 'recap/week_view.dart';

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
  final _recapService = RecapService(DatabaseService.instance.entries);

  // View toggle
  bool _isWeekView = true;

  // Search state
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<JournalEntry> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _showSearch = false;

  // Week entries
  List<JournalEntry> _weekEntries = [];
  UserSettings? _settings;
  WeeklySummary? _weeklySummary;

  // Calendar state
  late DateTime _selectedMonth;
  int? _selectedDay;
  Set<int> _entryDays = {};
  List<JournalEntry> _selectedEntries = [];

  // Subscriptions
  StreamSubscription<List<JournalEntry>>? _weekEntriesSub;
  StreamSubscription<Set<int>>? _monthSub;
  StreamSubscription<List<JournalEntry>>? _entrySub;

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
        _subscribeWeekEntries(s.weekStartDay);
      }
    }
  }

  void _subscribeWeekEntries(int weekStartDay) {
    _weekEntriesSub?.cancel();
    _weekEntriesSub =
        _entries.watchWeekEntries(weekStartDay: weekStartDay).listen((entries) {
      if (!mounted) return;
      setState(() => _weekEntries = entries);
      _loadWeeklySummary(weekStartDay);
    });
  }

  Future<void> _loadWeeklySummary(int weekStartDay) async {
    final weekStart = weekStartDate(weekStartDay: weekStartDay);
    final summary = await _recapService.getWeeklySummary(weekStart, weekStartDay);
    if (!mounted) return;
    setState(() => _weeklySummary = summary);
  }

  void _listenToMonthData() {
    _monthSub?.cancel();
    _monthSub = _entries.watchMonthEntryDays(_selectedMonth).listen((days) {
      if (!mounted) return;
      setState(() {
        _entryDays = days;
      });
    });
  }

  void _onDaySelected(int day) {
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
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDay = null;
      _selectedEntries = [];
    });
    _entrySub?.cancel();
    _listenToMonthData();
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final nextMonth = (_selectedMonth.month == 12)
        ? DateTime(_selectedMonth.year + 1, 1)
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final currentMonthEnd = (now.month == 12)
        ? DateTime(now.year + 1, 1)
        : DateTime(now.year, now.month + 1);
    if (nextMonth.isAfter(currentMonthEnd)) return;

    setState(() {
      _selectedMonth = nextMonth;
      _selectedDay = null;
      _selectedEntries = [];
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
    _monthSub?.cancel();
    _entrySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── Header with search toggle ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recap',
                  style: tt.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: Icon(_showSearch ? Icons.close : Icons.search),
                  onPressed: _toggleSearch,
                  tooltip: _showSearch ? 'Close search' : 'Search entries',
                ),
              ],
            ),

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

              // ── Week / Month toggle ──
              Center(
                child: SegmentedPill(
                  leftLabel: 'Week',
                  rightLabel: 'Month',
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
                  weekStartDay: _settings?.weekStartDay ?? 1,
                  weeklySummary: _weeklySummary,
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
                  selectedDay: _selectedDay,
                  selectedEntries: _selectedEntries,
                  weekStartDay: _settings?.weekStartDay ?? 1,
                  onDaySelected: _onDaySelected,
                  onPreviousMonth: _goToPreviousMonth,
                  onNextMonth: _goToNextMonth,
                ),
            ],

            // ── Bottom padding for nav bar ──
            const SizedBox(height: AppSpacing.navBarClearance),
          ],
        ),
      ),
    );
  }
}
