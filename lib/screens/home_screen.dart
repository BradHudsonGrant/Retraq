import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../services/entry_repository.dart';
import '../services/settings_repository.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/review_service.dart';
import '../services/widget_service.dart';
import '../theme/app_spacing.dart';
import '../utils/adaptive_layout.dart';
import '../utils/date_helpers.dart';
import '../utils/journal_prompts.dart';
import '../widgets/molecules/mood_selector.dart';
import '../widgets/molecules/segmented_pill.dart';
import '../widgets/organisms/save_success_overlay.dart';
import 'home/journal_text_area.dart';
import 'home/recent_day_card.dart';

/// Home / Journal screen — the entry point of the app.
/// Respects user settings for AM/PM mode and opening prompt.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final _entryController = TextEditingController();
  final _titleController = TextEditingController();
  final _entryFocus = FocusNode();
  final EntryRepository _entries = DatabaseService.instance.entries;
  final SettingsRepository _settingsRepo = DatabaseService.instance.settings;

  int? _weekCount;
  int? _selectedMood;
  bool _isSaving = false;
  bool _showSaveSuccess = false;
  String? _milestoneMessage;
  bool _isAm = true;
  DateTime? _selectedDate;
  int? _lastSavedEntryId;
  UserSettings? _settings;
  StreamSubscription<int>? _weekCountSub;
  StreamSubscription<List<JournalEntry>>? _yesterdaySub;
  StreamSubscription<List<JournalEntry>>? _dayBeforeSub;
  List<JournalEntry> _yesterdayEntries = [];
  List<JournalEntry> _dayBeforeEntries = [];
  DateTime _lastInitDate = DateTime.now();

  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _shakeAnimation = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -8, end: 0), weight: 1),
  ]).animate(_shakeController);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initStreams();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastDay = DateTime(
        _lastInitDate.year, _lastInitDate.month, _lastInitDate.day,
      );
      if (today != lastDay) _initStreams();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = SettingsProvider.maybeOf(context);
    if (s != null && s != _settings) {
      final oldAskAboutToday = _settings?.askAboutToday;
      _settings = s;
      if (!s.isAllDayMode) {
        _isAm = DateTime.now().hour < s.amPmCutoffHour;
      }
      if (oldAskAboutToday != s.askAboutToday) _subscribeRecentDays();
    }
  }

  void _initStreams() {
    _lastInitDate = DateTime.now();

    _weekCountSub?.cancel();
    _weekCountSub = _settingsRepo.watchSettings()
        .where((s) => s != null)
        .cast<UserSettings>()
        .asyncExpand((s) => _entries.watchWeekEntryCount(weekStartDay: s.weekStartDay))
        .handleError((e) => debugPrint('watchWeekEntryCount failed: $e'))
        .listen((count) {
      if (!mounted) return;
      setState(() => _weekCount = count);
    });

    _subscribeRecentDays();
  }

  void _subscribeRecentDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final askAboutToday = _settings?.askAboutToday ?? true;

    final recentDay1 = askAboutToday
        ? today
        : today.subtract(const Duration(days: 1));
    final recentDay2 = askAboutToday
        ? today.subtract(const Duration(days: 1))
        : today.subtract(const Duration(days: 2));

    _yesterdaySub?.cancel();
    _yesterdaySub = _entries.watchEntriesForDate(recentDay1).listen((entries) {
      if (!mounted) return;
      setState(() => _yesterdayEntries = entries);
    });

    _dayBeforeSub?.cancel();
    _dayBeforeSub = _entries.watchEntriesForDate(recentDay2).listen((entries) {
      if (!mounted) return;
      setState(() => _dayBeforeEntries = entries);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _weekCountSub?.cancel();
    _yesterdaySub?.cancel();
    _dayBeforeSub?.cancel();
    _shakeController.dispose();
    _titleController.dispose();
    _entryController.dispose();
    _entryFocus.dispose();
    super.dispose();
  }

  DateTime get _defaultDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_settings?.askAboutToday ?? true) return today;
    return today.subtract(const Duration(days: 1));
  }

  DateTime get _entryDate => _selectedDate ?? _defaultDate;
  bool get _isAllDayMode => _settings?.isAllDayMode ?? true;
  String get _accentWord => '${formatDateLabel(_entryDate, capitalize: false)}?';

  static const _heroPrompts = [
    'What\'s the\nTL;DR of ',
    'How was\n',
    'What happened\n',
    'Sum up\n',
    'What stood\nout ',
    'Brain dump\nfor ',
    'One thing\nabout ',
  ];

  String get _heroPrompt {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return _heroPrompts[dayOfYear % _heroPrompts.length];
  }

  /// Shared journal input widgets used by both tablet and phone layouts.
  List<Widget> _buildJournalContent(ColorScheme cs, TextTheme tt) {
    return [
      const SizedBox(height: AppSpacing.xl),

      // Hero prompt
      Semantics(
        header: true,
        label: '$_heroPrompt$_accentWord',
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(
            style: tt.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            children: [
              TextSpan(text: _heroPrompt),
              TextSpan(
                text: _accentWord,
                style: TextStyle(color: cs.primary),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),

      // Date chip
      Semantics(
        button: true,
        label: 'Change entry date, currently ${_selectedDate != null ? DateFormat('MMM d, yyyy').format(_entryDate) : formatDateLabel(_entryDate)}',
        excludeSemantics: true,
        child: InkWell(
          onTap: _pickDate,
          borderRadius: AppSpacing.borderRadiusLg,
          child: Chip(
            avatar: Icon(Icons.calendar_today, size: 16, color: cs.onSurfaceVariant),
            label: Text(
              _selectedDate != null
                  ? DateFormat('MMM d, yyyy').format(_entryDate)
                  : formatDateLabel(_entryDate),
              style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            backgroundColor: cs.surfaceContainerHigh,
            side: BorderSide(
              color: _selectedDate != null
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
        ),
      ),

      const SizedBox(height: AppSpacing.sm),
      Text(
        'Brain dump here. Full sentences optional.',
        style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
      ),

      const SizedBox(height: AppSpacing.md),

      // Mood selector (opt-in via settings)
      if (_settings?.moodEnabled ?? false) ...[
        MoodSelector(
          selectedMood: _selectedMood,
          onChanged: (mood) => setState(() => _selectedMood = mood),
        ),
        const SizedBox(height: AppSpacing.md),
      ],

      // Entry title (optional)
      if (_settings?.showEntryTitle ?? false) ...[
        _buildTitleField(cs, tt),
        const SizedBox(height: AppSpacing.sm),
      ],

      // Journal input
      AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final dx = _shakeAnimation.value;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: child,
          );
        },
        child: JournalTextArea(
          controller: _entryController,
          focusNode: _entryFocus,
          hint: _isAllDayMode
              ? dailyJournalPrompt()
              : _isAm
                  ? 'How did the morning go?'
                  : 'How about the rest of the day?',
          isSaving: _isSaving,
          onSave: _saveEntry,
          enterToSave: _settings?.enterToSave ?? false,
          bulletPoints: _settings?.bulletPointsOnEnter ?? false,
          topRightWidget: _isAllDayMode
              ? null
              : SegmentedPill(
                  leftLabel: 'AM',
                  rightLabel: 'PM',
                  isRightActive: !_isAm,
                  onTapLeft: () => _switchPeriod(true),
                  onTapRight: () => _switchPeriod(false),
                ),
        ),
      ),

      const SizedBox(height: AppSpacing.lg),

      // Progress bar
      _buildProgressBar(cs, tt),
    ];
  }

  Widget _buildJournalPane(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildJournalContent(cs, tt),
          const SizedBox(height: AppSpacing.navBarClearance),
        ],
      ),
    );
  }

  Widget _buildRecentPane(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Recent',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_yesterdayEntries.isNotEmpty)
            RecentDayCard(
              label: (_settings?.askAboutToday ?? true) ? 'Today' : 'Yesterday',
              entries: _yesterdayEntries,
            ),
          if (_dayBeforeEntries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            RecentDayCard(
              label: (_settings?.askAboutToday ?? true)
                  ? 'Yesterday'
                  : DateFormat('EEEE').format(
                      DateTime.now().subtract(const Duration(days: 2)),
                    ),
              entries: _dayBeforeEntries,
            ),
          ],
          if (_yesterdayEntries.isEmpty && _dayBeforeEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: Center(
                child: Text(
                  'No recent entries yet.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.navBarClearance),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tablet = isTablet(context);

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: tablet
                ? AdaptiveTwoPane(
                    left: _buildJournalPane(cs, tt),
                    right: _buildRecentPane(cs, tt),
                  )
                : SingleChildScrollView(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildJournalContent(cs, tt),

                        // Recent days
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Recent',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_yesterdayEntries.isNotEmpty)
                          RecentDayCard(
                            label: (_settings?.askAboutToday ?? true) ? 'Today' : 'Yesterday',
                            entries: _yesterdayEntries,
                          ),
                        if (_dayBeforeEntries.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          RecentDayCard(
                            label: (_settings?.askAboutToday ?? true)
                                ? 'Yesterday'
                                : DateFormat('EEEE').format(
                                    DateTime.now().subtract(const Duration(days: 2)),
                                  ),
                            entries: _dayBeforeEntries,
                          ),
                        ],
                        if (_yesterdayEntries.isEmpty && _dayBeforeEntries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              'Your recent entries will appear here.',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ),

                        const SizedBox(height: AppSpacing.navBarClearance),
                      ],
                    ),
                  ),
          ),

          if (_showSaveSuccess)
            Positioned.fill(
              child: SaveSuccessOverlay(
                milestoneMessage: _milestoneMessage,
                onDismissed: () {
                  if (!mounted) return;
                  final entryId = _lastSavedEntryId;
                  setState(() {
                    _showSaveSuccess = false;
                    _milestoneMessage = null;
                    _lastSavedEntryId = null;
                  });
                  if (entryId != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Entry saved'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () => _entries.deleteEntry(entryId),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleField(ColorScheme cs, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _titleController,
        textCapitalization: TextCapitalization.sentences,
        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Entry title (optional)',
          labelText: 'Entry title',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintStyle: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Row(
        children: [
          Icon(
            (_weekCount ?? 0) > 0 ? Icons.local_fire_department : Icons.edit_note,
            size: 18,
            color: cs.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _weekCount == null
                  ? '' // Loading — avoid flash
                  : _weekCount == 0
                      ? 'Start your first entry above.'
                      : '$_weekCount ${_weekCount == 1 ? 'entry' : 'entries'} this week — keep going!',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked == _defaultDate ? null : picked;
      });
    }
  }

  Future<void> _switchPeriod(bool isAm) async {
    if (isAm == _isAm) return;

    final hasText = _cleanText(_entryController.text).isNotEmpty;
    if (hasText) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save and switch?'),
          content: Text(
            'Your ${_isAm ? 'AM' : 'PM'} entry will be saved before '
            'switching to ${isAm ? 'AM' : 'PM'}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save & Switch'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _saveEntry();
      if (!mounted) return;
    }

    setState(() => _isAm = isAm);
    _entryController.clear();
    _titleController.clear();
  }

  String _cleanText(String raw) {
    final lines = raw.split('\n')
        .map((l) => l.trim())
        .where((l) => l != '•' && l != '')
        .toList();
    return lines.join('\n').trim();
  }

  Future<void> _saveEntry() async {
    final text = _cleanText(_entryController.text);
    final titleText = _titleController.text.trim();
    final moodEnabled = _settings?.moodEnabled ?? false;
    final moodRequired = _settings?.moodRequired ?? false;
    final moodOnlyEntries = _settings?.moodOnlyEntries ?? false;

    // Validate: need text OR mood (if mood-only entries allowed)
    final hasText = text.isNotEmpty;
    final hasMood = moodEnabled && _selectedMood != null;

    if (!hasText && !(moodOnlyEntries && hasMood)) {
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Write something first!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (moodRequired && !hasMood) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pick a mood to save'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final targetDate = _entryDate;

    String? label;
    if (!_isAllDayMode) {
      label = _isAm ? 'AM' : 'PM';
    }

    final entry = JournalEntry(
      date: targetDate,
      entry: hasText ? text : null,
      label: label,
      title: titleText.isNotEmpty ? titleText : null,
      mood: moodEnabled ? _selectedMood : null,
      createdAt: now,
    );

    int savedId;
    try {
      savedId = await _entries.saveEntry(entry);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save. Please try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        ),
      );
      return;
    }

    if (!mounted) return;

    // Single count fetch used for milestones and review prompt
    final totalCount = await _entries.getTotalEntryCount();
    if (!mounted) return;

    final milestone = _milestoneForCount(totalCount);

    FocusScope.of(context).unfocus();

    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = false;
      _showSaveSuccess = true;
      _milestoneMessage = milestone;
      _selectedDate = null;
      _lastSavedEntryId = savedId;
    });
    _titleController.clear();
    _entryController.clear();
    _selectedMood = null;

    // Check for in-app review prompt (fires once at 5th entry)
    ReviewService.instance.checkAndPrompt(totalCount);

    // Refresh home screen widget with latest data
    WidgetService.instance.update();

    // Cancel/reschedule today's reminder so users who already journaled
    // don't get nagged again.
    if (_settings != null) {
      NotificationService.instance.scheduleDailyIfNeeded(
        hour: _settings!.nudgeHour,
        minute: _settings!.nudgeMinute,
        hasEntriesToday: () async => true, // Just saved, so yes
      );
    }
  }

  static String? _milestoneForCount(int count) {
    const milestones = <int, String>{
      1: 'Your very first entry!',
      5: "5 entries! You're off to a great start.",
      10: "10 entries! You're building a habit.",
      25: '25 entries! Look at you go.',
      50: "50 entries! That's genuinely impressive.",
      100: "100 entries! You're a journaling pro.",
      250: '250 entries! A real treasure trove.',
      500: '500 entries! Half a thousand memories.',
      1000: '1,000 entries! Legendary status.',
    };
    return milestones[count];
  }
}
