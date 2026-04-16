import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
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
import '../utils/test_keys.dart';
import '../widgets/molecules/mood_selector.dart';
import '../widgets/molecules/segmented_pill.dart';
import '../widgets/organisms/save_success_overlay.dart';
import 'home/journal_text_area.dart';
import '../widgets/atoms/bionic_text.dart';
import '../widgets/atoms/retraq_logo.dart';
import 'home/recent_day_card.dart';

/// Home / Journal screen — the entry point of the app.
/// Respects user settings for AM/PM mode and opening prompt.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver,
        TickerProviderStateMixin {
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
        _lastInitDate.year,
        _lastInitDate.month,
        _lastInitDate.day,
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
    _weekCountSub = _settingsRepo
        .watchSettings()
        .where((s) => s != null)
        .cast<UserSettings>()
        .map((s) => s.weekStartDay)
        .distinct()
        .asyncExpand(
          (weekStartDay) =>
              _entries.watchWeekEntryCount(weekStartDay: weekStartDay),
        )
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

    final recentDay1 =
        askAboutToday ? today : today.subtract(const Duration(days: 1));
    final recentDay2 =
        askAboutToday
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
  String get _accentWord =>
      '${formatDateLabel(_entryDate, capitalize: false)}?';

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
  List<Widget> _buildJournalContent(ColorScheme cs, TextTheme tt, L10n l10n) {
    return [
      const SizedBox(height: AppSpacing.md),

      // Brand mark
      const RetraqLogo(size: 22),
      const SizedBox(height: AppSpacing.lg),

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
              TextSpan(text: _accentWord, style: TextStyle(color: cs.primary)),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),

      // Date chip
      Semantics(
        button: true,
        label: l10n.changeDateLabel(
          _selectedDate != null
              ? DateFormat('MMM d, yyyy').format(_entryDate)
              : formatDateLabel(_entryDate),
        ),
        excludeSemantics: true,
        child: InkWell(
          key: TestKeys.homeDateChip,
          onTap: _pickDate,
          borderRadius: AppSpacing.borderRadiusLg,
          child: Chip(
            avatar: Icon(
              Icons.calendar_today,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
            label: Text(
              _selectedDate != null
                  ? DateFormat('MMM d, yyyy').format(_entryDate)
                  : formatDateLabel(_entryDate),
              style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            backgroundColor: cs.surfaceContainerHigh,
            side: BorderSide(
              color:
                  _selectedDate != null
                      ? cs.primary.withValues(alpha: 0.5)
                      : cs.outlineVariant.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
        ),
      ),

      const SizedBox(height: AppSpacing.sm),
      BionicText(
        text: l10n.homeSubtitle,
        style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        enabled: _settings?.bionicReadingEnabled ?? false,
      ),

      const SizedBox(height: AppSpacing.md),

      // Mood selector (opt-in via settings)
      if (_settings?.moodEnabled ?? false) ...[
        MoodSelector(
          key: TestKeys.homeMoodSelector,
          selectedMood: _selectedMood,
          onChanged: (mood) => setState(() => _selectedMood = mood),
        ),
        const SizedBox(height: AppSpacing.md),
      ],

      // Entry title (optional)
      if (_settings?.showEntryTitle ?? false) ...[
        _buildTitleField(cs, tt, l10n),
        const SizedBox(height: AppSpacing.sm),
      ],

      // Journal input
      AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final dx = _shakeAnimation.value;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: JournalTextArea(
          controller: _entryController,
          focusNode: _entryFocus,
          hint:
              _isAllDayMode
                  ? dailyJournalPrompt()
                  : _isAm
                  ? l10n.amHint
                  : l10n.pmHint,
          isSaving: _isSaving,
          onSave: _saveEntry,
          enterToSave: _settings?.enterToSave ?? false,
          bulletPoints: _settings?.bulletPointsOnEnter ?? false,
          textFieldKey: TestKeys.homeEntryField,
          saveButtonKey: TestKeys.homeSaveButton,
          topRightWidget:
              _isAllDayMode
                  ? null
                  : SegmentedPill(
                    key: TestKeys.homeAmPmToggle,
                    leftLabel: l10n.amLabel,
                    rightLabel: l10n.pmLabel,
                    isRightActive: !_isAm,
                    onTapLeft: () => _switchPeriod(true),
                    onTapRight: () => _switchPeriod(false),
                  ),
        ),
      ),

      const SizedBox(height: AppSpacing.lg),

      // Progress bar
      _buildProgressBar(cs, tt, l10n),
    ];
  }

  Widget _buildJournalPane(ColorScheme cs, TextTheme tt, L10n l10n) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildJournalContent(cs, tt, l10n),
          const SizedBox(height: AppSpacing.navBarClearance),
        ],
      ),
    );
  }

  Widget _buildRecentPane(ColorScheme cs, TextTheme tt, L10n l10n) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.recentLabel,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_yesterdayEntries.isNotEmpty)
            RecentDayCard(
              label:
                  (_settings?.askAboutToday ?? true)
                      ? l10n.todayLabel
                      : l10n.yesterdayLabel,
              entries: _yesterdayEntries,
            ),
          if (_dayBeforeEntries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            RecentDayCard(
              label:
                  (_settings?.askAboutToday ?? true)
                      ? l10n.yesterdayLabel
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
                child: BionicText(
                  text: l10n.noRecentEntries,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  enabled: _settings?.bionicReadingEnabled ?? false,
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
    final l10n = L10n.of(context)!;
    final tablet = isTablet(context);

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child:
                tablet
                    ? AdaptiveTwoPane(
                      left: _buildJournalPane(cs, tt, l10n),
                      right: _buildRecentPane(cs, tt, l10n),
                    )
                    : SingleChildScrollView(
                      padding: AppSpacing.pagePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._buildJournalContent(cs, tt, l10n),

                          // Recent days
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            l10n.recentLabel,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_yesterdayEntries.isNotEmpty)
                            RecentDayCard(
                              label:
                                  (_settings?.askAboutToday ?? true)
                                      ? l10n.todayLabel
                                      : l10n.yesterdayLabel,
                              entries: _yesterdayEntries,
                            ),
                          if (_dayBeforeEntries.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            RecentDayCard(
                              label:
                                  (_settings?.askAboutToday ?? true)
                                      ? l10n.yesterdayLabel
                                      : DateFormat('EEEE').format(
                                        DateTime.now().subtract(
                                          const Duration(days: 2),
                                        ),
                                      ),
                              entries: _dayBeforeEntries,
                            ),
                          ],
                          if (_yesterdayEntries.isEmpty &&
                              _dayBeforeEntries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.md,
                              ),
                              child: BionicText(
                                text: l10n.recentEntriesPlaceholder,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                enabled:
                                    _settings?.bionicReadingEnabled ?? false,
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
                  // Clear the form here (deferred from _saveEntry) so the
                  // form rebuild happens during the overlay dismissal frame
                  // rather than competing with its entrance animation.
                  _titleController.clear();
                  _entryController.clear();
                  setState(() {
                    _showSaveSuccess = false;
                    _milestoneMessage = null;
                    _lastSavedEntryId = null;
                    _selectedDate = null;
                    _selectedMood = null;
                  });
                  if (entryId != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.entrySaved),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusLg,
                        ),
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: l10n.undoLabel,
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

  Widget _buildTitleField(ColorScheme cs, TextTheme tt, L10n l10n) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TextField(
        key: TestKeys.homeTitleField,
        controller: _titleController,
        textCapitalization: TextCapitalization.sentences,
        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: l10n.entryTitleHint,
          labelText: l10n.entryTitleLabel,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          // Task 7.1 — alpha 0.75 to meet WCAG 1.4.3 AA contrast.
          hintStyle: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant.withValues(alpha: 0.75),
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme cs, TextTheme tt, L10n l10n) {
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
            (_weekCount ?? 0) > 0
                ? Icons.local_fire_department
                : Icons.edit_note,
            size: 18,
            color: cs.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: BionicText(
              text:
                  _weekCount == null
                      ? '' // Loading — avoid flash
                      : _weekCount == 0
                      ? l10n.progressFirstEntry
                      : l10n.progressWeekCount(_weekCount!),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              enabled: _settings?.bionicReadingEnabled ?? false,
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

    final l10n = L10n.of(context)!;
    final hasText = _cleanText(_entryController.text).isNotEmpty;
    if (hasText) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text(l10n.saveAndSwitch),
              content: Text(
                l10n.saveAndSwitchContent(
                  _isAm ? l10n.amLabel : l10n.pmLabel,
                  isAm ? l10n.amLabel : l10n.pmLabel,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancelLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.saveAndSwitchButton),
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
    final lines =
        raw
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l != '•' && l != '')
            .toList();
    return lines.join('\n').trim();
  }

  Future<void> _saveEntry() async {
    final l10n = L10n.of(context)!;
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
          content: Text(l10n.writeSomethingFirst),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (moodRequired && !hasMood) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pickMoodToSave),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
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
      label = _isAm ? l10n.amLabel : l10n.pmLabel;
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
            l10n.saveFailedMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    // Single count fetch used for milestones and review prompt
    final totalCount = await _entries.getTotalEntryCount();
    if (!mounted) return;

    final milestone = _milestoneForCount(totalCount, l10n);

    FocusScope.of(context).unfocus();

    HapticFeedback.mediumImpact();
    // Show the overlay first WITHOUT clearing the underlying form. The overlay
    // is fully opaque so the form isn't visible, but rebuilding the journal
    // tree (text controllers, recent day cards) on the same frame as the
    // overlay's elastic entry causes a visible jank. Defer the clear to the
    // dismissal callback when the overlay is already mid-fade-out.
    setState(() {
      _isSaving = false;
      _showSaveSuccess = true;
      _milestoneMessage = milestone;
      _lastSavedEntryId = savedId;
    });

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

  static String? _milestoneForCount(int count, L10n l10n) {
    final milestones = <int, String>{
      1: l10n.milestone1,
      5: l10n.milestone5,
      10: l10n.milestone10,
      25: l10n.milestone25,
      50: l10n.milestone50,
      100: l10n.milestone100,
      250: l10n.milestone250,
      500: l10n.milestone500,
      1000: l10n.milestone1000,
    };
    return milestones[count];
  }
}
