import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/user_settings.dart';
import '../providers/settings_provider.dart';
import '../services/app_log.dart';
import '../services/entry_repository.dart';
import '../services/settings_repository.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/review_service.dart';
import '../services/widget_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../utils/adaptive_layout.dart';
import '../utils/date_helpers.dart';
import '../utils/journal_prompts.dart';
import '../utils/test_keys.dart';
import '../widgets/molecules/empty_recent_state.dart';
import '../widgets/molecules/mood_selector.dart';
import '../widgets/molecules/segmented_pill.dart';
import '../widgets/organisms/save_success_overlay.dart';
import 'home/journal_text_area.dart';
import '../widgets/atoms/app_snack_bar.dart';
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
  // Task 2.15 — how long the current overlay should hold before the
  // exit fade. 1000ms for milestones / first ten saves, 400ms for
  // routine power-user saves.
  Duration _overlayHoldDuration = const Duration(milliseconds: 1000);
  bool _isAm = true;
  DateTime? _selectedDate;
  int? _lastSavedEntryId;
  UserSettings? _settings;
  StreamSubscription<int>? _weekCountSub;
  StreamSubscription<int>? _totalCountSub;
  StreamSubscription<List<JournalEntry>>? _yesterdaySub;
  StreamSubscription<List<JournalEntry>>? _dayBeforeSub;
  // Task 8.10 — cached total entry count. Sourced from
  // watchTotalEntryCount() so we don't block the save path on a
  // synchronous count query. Starts at 0 until the first stream
  // event arrives (matches the empty-DB state).
  int _totalCount = 0;
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
        .handleError(
          (e) => AppLog.warn('home_screen.watchWeekEntryCount', e),
        )
        .listen((count) {
          if (!mounted) return;
          setState(() => _weekCount = count);
        });

    // Task 8.10 — keep a running cache of the total entry count so the
    // save-tap path doesn't have to await a count() query before
    // deciding milestone/overlay length. Drift pushes a new value
    // whenever anything in journal_entries changes, so the cache is
    // always in sync.
    _totalCountSub?.cancel();
    _totalCountSub = _entries
        .watchTotalEntryCount()
        .handleError(
          (e) => AppLog.warn('home_screen.watchTotalEntryCount', e),
        )
        .listen((count) {
          if (!mounted) return;
          _totalCount = count;
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
    _totalCountSub?.cancel();
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

  /// Task 7.6 — localize hero prompts via already-existing
  /// `heroPrompt0..6` ARB keys (previously hardcoded English despite
  /// the keys being ready). Rotation still based on day-of-year so the
  /// prompt changes daily without UI state.
  String _resolveHeroPrompt(L10n l10n) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final prompts = <String>[
      l10n.heroPrompt0,
      l10n.heroPrompt1,
      l10n.heroPrompt2,
      l10n.heroPrompt3,
      l10n.heroPrompt4,
      l10n.heroPrompt5,
      l10n.heroPrompt6,
    ];
    return prompts[dayOfYear % prompts.length];
  }

  /// Shared journal input widgets used by both tablet and phone layouts.
  List<Widget> _buildJournalContent(ColorScheme cs, TextTheme tt, L10n l10n) {
    return [
      const SizedBox(height: AppSpacing.md),

      // Brand mark
      const RetraqLogo(size: 22),
      const SizedBox(height: AppSpacing.lg),

      // Hero prompt (Task 7.6 — localized via _resolveHeroPrompt).
      Builder(
        builder: (context) {
          final heroPrompt = _resolveHeroPrompt(l10n);
          return Semantics(
            header: true,
            label: '$heroPrompt$_accentWord',
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                style: tt.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                children: [
                  TextSpan(text: heroPrompt),
                  TextSpan(
                    text: _accentWord,
                    style: TextStyle(color: cs.primary),
                  ),
                ],
              ),
            ),
          );
        },
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
            // Task 2.9 — when a non-default date is selected, show a
            // reset X so users have an explicit way to return to today
            // without reopening the picker. Additive to the border-
            // colour signal, not a replacement.
            onDeleted: _selectedDate != null
                ? () => setState(() {
                      _selectedDate = null;
                    })
                : null,
            deleteIcon: _selectedDate != null
                ? Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  )
                : null,
            deleteButtonTooltipMessage:
                _selectedDate != null ? l10n.resetToTodayLabel : null,
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
            // Task 2.13 — warmer empty-recent state (headline + body +
            // soft icon) instead of a flat dimmed one-liner.
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xl),
              child: EmptyRecentState(),
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
                            // Task 2.13 — warmer empty-recent state in
                            // the phone layout too. Drop the bionic
                            // wrapper + opacity trick and use the
                            // dedicated widget.
                            const Padding(
                              padding: EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: EmptyRecentState(),
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
                holdDuration: _overlayHoldDuration,
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
                    AppSnackBar.show(
                      context,
                      l10n.entrySaved,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: l10n.undoLabel,
                        onPressed: () => _entries.deleteEntry(entryId),
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
      // Task 2.8 — add a third "Discard & Switch" action so users who
      // made an accidental entry aren't forced to save it before
      // flipping the period. Matches the three-action pattern already
      // used elsewhere in the app.
      final choice = await showDialog<String>(
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
                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                  child: Text(l10n.cancelLabel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'discard'),
                  child: Text(l10n.discardAndSwitchButton),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'save'),
                  child: Text(l10n.saveAndSwitchButton),
                ),
              ],
            ),
      );
      if (!mounted) return;
      switch (choice) {
        case 'save':
          await _saveEntry();
          if (!mounted) return;
          break;
        case 'discard':
          // Controllers cleared below after the setState.
          break;
        default:
          // 'cancel' or barrier dismiss — no period flip.
          return;
      }
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
      // Task 7.18 — gate the shake through AppMotion so reduce-motion
      // users get the validation feedback via the SnackBar only, no
      // 300ms animation. WCAG 2.3.3 / 2.2.2.
      if (!AppMotion.reduce(context)) {
        _shakeController.forward(from: 0);
      }
      AppSnackBar.show(
        context,
        l10n.writeSomethingFirst,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    if (moodRequired && !hasMood) {
      AppSnackBar.show(
        context,
        l10n.pickMoodToSave,
        duration: const Duration(seconds: 2),
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
      AppSnackBar.error(context, l10n.saveFailedMessage);
      return;
    }

    if (!mounted) return;

    // Task 8.10 — read the cached total rather than awaiting another
    // count() query. The watchTotalEntryCount subscription set up in
    // _initStreams keeps _totalCount current, and Drift will emit the
    // post-insert value on its next tick. Add 1 optimistically so the
    // milestone check sees the just-saved entry in the same frame
    // without waiting for the stream event.
    final totalCount = _totalCount + 1;

    final milestone = _milestoneForCount(totalCount, l10n);

    FocusScope.of(context).unfocus();

    HapticFeedback.mediumImpact();
    // Show the overlay first WITHOUT clearing the underlying form. The overlay
    // is fully opaque so the form isn't visible, but rebuilding the journal
    // tree (text controllers, recent day cards) on the same frame as the
    // overlay's elastic entry causes a visible jank. Defer the clear to the
    // dismissal callback when the overlay is already mid-fade-out.
    // Task 2.15 — keep the full ~1000ms dwell for milestone saves and
    // the first ten overall; drop to 400ms for routine saves afterward
    // so frequent journaling doesn't feel blocked between thoughts.
    final isMilestone = milestone != null;
    final shortDwell = !isMilestone && totalCount > 10;
    setState(() {
      _isSaving = false;
      _showSaveSuccess = true;
      _milestoneMessage = milestone;
      _lastSavedEntryId = savedId;
      _overlayHoldDuration = shortDwell
          ? const Duration(milliseconds: 400)
          : const Duration(milliseconds: 1000);
    });

    // Check for in-app review prompt (fires once at 5th entry)
    ReviewService.instance.checkAndPrompt(totalCount);

    // Refresh home screen widget with latest data.
    // Task 8.11 — explicit fire-and-forget. The update hops a platform
    // channel and can spend a few ms marshalling; we don't want the
    // save-tap UI path blocked on it, and the save-success overlay is
    // already visible by this point. Errors inside update() are
    // swallowed and logged via AppLog (Task 1.13).
    unawaited(WidgetService.instance.update());

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
