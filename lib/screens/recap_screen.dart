import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../services/entry_repository.dart';
import '../services/recap_service.dart';
import '../utils/adaptive_layout.dart';
import '../utils/date_helpers.dart';
import '../theme/app_spacing.dart';
import '../widgets/molecules/entry_action_menu.dart';
import '../widgets/molecules/segmented_pill.dart';
import '../widgets/organisms/calendar_grid.dart';
import '../utils/entry_action_dialogs.dart';
import '../widgets/organisms/entry_detail_view.dart';
import '../widgets/organisms/week_day_list.dart';

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
    final cs = Theme.of(context).colorScheme;
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

            // ── Search bar (expandable) ──
            if (_showSearch) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search entries...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusLg,
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Search results ──
              if (_isSearching)
                Semantics(
                  liveRegion: true,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        'Searching...',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                )
              else if (_hasSearched && _searchResults.isEmpty)
                Semantics(
                  liveRegion: true,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        'No entries match your search.',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final entry = _searchResults[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: AppSpacing.borderRadiusLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  DateFormat('MMM d, yyyy')
                                      .format(entry.date),
                                  style: tt.labelMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (entry.label != null) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    entry.label!,
                                    style: tt.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                EntryActionMenu(
                                  entry: entry,
                                  onEdit: () => _confirmEditEntry(entry),
                                  onDelete: () => _confirmDeleteEntry(entry),
                                  iconAlpha: 0.65,
                                ),
                              ],
                            ),
                            if (entry.title != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              _highlightText(
                                entry.title!,
                                _searchController.text.trim(),
                                tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                cs,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xs),
                            _highlightText(
                              entry.displayText,
                              _searchController.text.trim(),
                              tt.bodyMedium,
                              cs,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],

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
              if (_isWeekView) ...[
                // Weekly summary card
                if (_weeklySummary != null) ...[
                  Card(
                    color: cs.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Recap',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _weeklySummary!.observation,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          if (_weeklySummary!.totalEntries > 0) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  size: 16,
                                  color: cs.onPrimaryContainer
                                      .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '${_weeklySummary!.totalEntries} entries \u00b7 ${_weeklySummary!.activeDays} days \u00b7 ${_weeklySummary!.preferredTime}',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (_weekEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxl),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.auto_stories,
                            size: 48,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No entries yet',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Your journal entries will appear here once you start writing.',
                            textAlign: TextAlign.center,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  WeekDayList(
                    weekStartDay: _settings?.weekStartDay ?? 1,
                    entries: _weekEntries,
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
              ],

              // ── Month view ──
              if (!_isWeekView) ...[
                if (isTablet(context))
                  // Tablet: side-by-side calendar + entry details
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: AdaptiveTwoPane(
                      leftFraction: 0.5,
                      left: SingleChildScrollView(
                        child: CalendarGrid(
                          month: _selectedMonth,
                          entryDays: _entryDays,
                          selectedDay: _selectedDay,
                          onDaySelected: _onDaySelected,
                          onPreviousMonth: _goToPreviousMonth,
                          onNextMonth: _goToNextMonth,
                          weekStartDay: _settings?.weekStartDay ?? 1,
                        ),
                      ),
                      right: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: _selectedDay != null && _selectedEntries.isNotEmpty
                            ? EntryDetailView(
                                entries: _selectedEntries,
                                date: DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month,
                                  _selectedDay!,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                                child: Center(
                                  child: Text(
                                    _selectedDay != null
                                        ? 'No entry for this day'
                                        : 'Select a day to view entries',
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  )
                else ...[
                  // Phone: stacked layout
                  CalendarGrid(
                    month: _selectedMonth,
                    entryDays: _entryDays,
                    selectedDay: _selectedDay,
                    onDaySelected: _onDaySelected,
                    onPreviousMonth: _goToPreviousMonth,
                    onNextMonth: _goToNextMonth,
                    weekStartDay: _settings?.weekStartDay ?? 1,
                  ),

                  // ── Entry detail (when a day is selected) ──
                  if (_selectedDay != null &&
                      _selectedEntries.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    EntryDetailView(
                      entries: _selectedEntries,
                      date: DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month,
                        _selectedDay!,
                      ),
                    ),
                  ] else if (_selectedDay != null &&
                      _selectedEntries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No entry for this day',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ],

            // ── Bottom padding for nav bar ──
            const SizedBox(height: AppSpacing.navBarClearance),
          ],
        ),
      ),
    );
  }

  /// Build a TextSpan that highlights occurrences of [query] in [text].
  Widget _highlightText(String text, String query, TextStyle? baseStyle, ColorScheme cs, {int? maxLines}) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines, overflow: maxLines != null ? TextOverflow.ellipsis : null);
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: cs.primaryContainer,
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ));
      start = idx + query.length;
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
