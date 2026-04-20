import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_settings.dart';
import '../../services/ai/recap_ai_provider.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/molecules/segmented_pill.dart';
import '../../widgets/molecules/settings_row.dart';

class PreferencesSection extends StatefulWidget {
  const PreferencesSection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.aiProvider,
  });

  final UserSettings settings;
  final ValueChanged<UserSettings> onSettingsChanged;

  /// Injection seam for tests. Defaults to [PlatformRecapAiProvider]
  /// so the capability probe hits the real platform channel.
  final RecapAiProvider? aiProvider;

  @override
  State<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<PreferencesSection> {
  // Single provider instance reused by the on-device AI row — keeps one
  // EventChannel subscription for the whole screen lifetime rather than
  // re-opening on every rebuild.
  late final RecapAiProvider _aiProviderInstance =
      widget.aiProvider ?? PlatformRecapAiProvider();

  UserSettings get settings => widget.settings;
  ValueChanged<UserSettings> get onSettingsChanged => widget.onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final s = settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.preferencesTitle, style: tt.titleLarge),
        const SizedBox(height: AppSpacing.md),

        // All Day vs AM/PM
        SettingsRow(
          title: l10n.allDayNotes,
          subtitle: l10n.allDayNotesSubtitle,
          trailing: SegmentedPill(
            leftLabel: '${l10n.amLabel}/${l10n.pmLabel}',
            rightLabel: l10n.allDayOption,
            isRightActive: s.isAllDayMode,
            onTapLeft: () => onSettingsChanged(s.copyWith(isAllDayMode: false)),
            onTapRight: () => onSettingsChanged(s.copyWith(isAllDayMode: true)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Opening behavior
        SettingsRow(
          title: l10n.openingPrompt,
          subtitle:
              s.askAboutToday ? l10n.asksAboutToday : l10n.asksAboutYesterday,
          trailing: SegmentedPill(
            leftLabel: l10n.todayLabel,
            rightLabel: l10n.yesterdayLabel,
            isRightActive: !s.askAboutToday,
            onTapLeft: () => onSettingsChanged(s.copyWith(askAboutToday: true)),
            onTapRight:
                () => onSettingsChanged(s.copyWith(askAboutToday: false)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Journal entry title
        SettingsRow(
          title: l10n.journalEntryTitle,
          subtitle: l10n.journalEntryTitleSubtitle,
          trailing: Semantics(
            label: l10n.journalEntryTitle,
            child: Switch(
              value: s.showEntryTitle,
              onChanged:
                  (v) => onSettingsChanged(s.copyWith(showEntryTitle: v)),
              activeThumbColor: cs.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Mood tracking — single-switch UX per Run 7 survey.
        // The `moodRequired` and `moodOnlyEntries` DB columns are still
        // in the schema (no migration) but hidden from UI; they always
        // default to `false` alongside the parent toggle. If user
        // demand for these sub-behaviors re-emerges in v1.1, re-expose
        // them here — but start with zero cognitive overhead.
        SettingsRow(
          title: l10n.moodTracking,
          subtitle: l10n.moodTrackingSubtitle,
          trailing: Semantics(
            label: l10n.moodTracking,
            child: Switch(
              value: s.moodEnabled,
              onChanged:
                  (v) => onSettingsChanged(
                    s.copyWith(
                      moodEnabled: v,
                      // Always force the sub-toggles to the Run 7
                      // defaults. Enabling mood does not re-surface
                      // `moodRequired` or `moodOnlyEntries` — users
                      // who had them ON in a prior build see them
                      // reset to OFF on next settings write.
                      moodRequired: false,
                      moodOnlyEntries: false,
                    ),
                  ),
              activeThumbColor: cs.primary,
            ),
          ),
        ),
        // TODO(v1.1): if 4-week post-launch telemetry shows users
        // asking for "require mood before save" or "mood-only entries",
        // re-expose the two hidden toggles here under a "Mood options"
        // expandable row. Do NOT restore the always-visible cascade —
        // the Run 7 survey was unambiguous about cognitive overhead.
        const SizedBox(height: AppSpacing.md),

        // Bionic Reading moved inside the Advanced expansion
        // tile. Per the Run 7 simplicity brief for v1, top-level
        // Preferences stays focused on theme, mood, all-day mode,
        // opening prompt, entry title, and app lock. Power-user
        // reading ergonomics live under Advanced with enter-to-save,
        // bullet-points-on-enter, week start day, and AM/PM cutoff.
        const SizedBox(height: AppSpacing.md),

        // Advanced settings
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              l10n.advancedTitle,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            children: [
              // Bionic Reading now lives here. Settings key
              // `bionicReadingEnabled` is unchanged, so users who had
              // it enabled see their preference preserved.
              SettingsRow(
                title: l10n.bionicReading,
                subtitle: l10n.bionicReadingSubtitle,
                trailing: Semantics(
                  label: l10n.bionicReading,
                  child: Switch(
                    value: s.bionicReadingEnabled,
                    onChanged: (v) => onSettingsChanged(
                      s.copyWith(bionicReadingEnabled: v),
                    ),
                    activeThumbColor: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // On-device AI recap. Opt-in toggle gated by a live
              // capability probe — the switch is disabled on devices
              // that can't run Gemini Nano / Apple Foundation Models.
              // Inference stays on the device; entries are handed to
              // the OS's sandboxed AI runtime, not the network.
              _OnDeviceAiRecapRow(
                provider: _aiProviderInstance,
                settings: s,
                onSettingsChanged: onSettingsChanged,
              ),
              const SizedBox(height: AppSpacing.md),

              SettingsRow(
                title: l10n.enterToSave,
                subtitle: l10n.enterToSaveSubtitle,
                trailing: Semantics(
                  label: l10n.enterToSave,
                  child: Switch(
                    value: s.enterToSave,
                    onChanged:
                        (v) => onSettingsChanged(
                          s.copyWith(
                            enterToSave: v,
                            bulletPointsOnEnter:
                                v ? false : s.bulletPointsOnEnter,
                          ),
                        ),
                    activeThumbColor: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              SettingsRow(
                title: l10n.bulletPointsOnEnter,
                subtitle: l10n.bulletPointsSubtitle,
                trailing: Semantics(
                  label: l10n.bulletPointsOnEnter,
                  child: Switch(
                    value: s.bulletPointsOnEnter,
                    onChanged:
                        s.enterToSave
                            ? null
                            : (v) => onSettingsChanged(
                              s.copyWith(
                                bulletPointsOnEnter: v,
                                enterToSave: v ? false : s.enterToSave,
                              ),
                            ),
                    activeThumbColor: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              SettingsRow(
                title: l10n.weekStartsOn,
                subtitle: _dayName(l10n, s.weekStartDay),
                trailing: Semantics(
                  label: l10n.weekStartsOnA11y(_dayName(l10n, s.weekStartDay)),
                  child: DropdownButton<int>(
                    value: s.weekStartDay,
                    underline: const SizedBox.shrink(),
                    borderRadius: AppSpacing.borderRadiusLg,
                    items: [
                      DropdownMenuItem(value: 1, child: Text(l10n.mondayName)),
                      DropdownMenuItem(value: 2, child: Text(l10n.tuesdayName)),
                      DropdownMenuItem(
                        value: 3,
                        child: Text(l10n.wednesdayName),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text(l10n.thursdayName),
                      ),
                      DropdownMenuItem(value: 5, child: Text(l10n.fridayName)),
                      DropdownMenuItem(
                        value: 6,
                        child: Text(l10n.saturdayName),
                      ),
                      DropdownMenuItem(value: 7, child: Text(l10n.sundayName)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      onSettingsChanged(s.copyWith(weekStartDay: v));
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (!s.isAllDayMode)
                SettingsRow(
                  title: l10n.amPmSwitchesAt,
                  subtitle: formatHour(s.amPmCutoffHour),
                  trailing: Semantics(
                    label: l10n.amPmSwitchesAtA11y(
                      formatHour(s.amPmCutoffHour),
                    ),
                    child: DropdownButton<int>(
                      value: s.amPmCutoffHour,
                      underline: const SizedBox.shrink(),
                      borderRadius: AppSpacing.borderRadiusLg,
                      items: [
                        for (int h = 10; h <= 18; h++)
                          DropdownMenuItem(
                            value: h,
                            child: Text(formatHour(h)),
                          ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        onSettingsChanged(s.copyWith(amPmCutoffHour: v));
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _dayName(L10n l10n, int weekday) {
    switch (weekday) {
      case 1:
        return l10n.mondayName;
      case 2:
        return l10n.tuesdayName;
      case 3:
        return l10n.wednesdayName;
      case 4:
        return l10n.thursdayName;
      case 5:
        return l10n.fridayName;
      case 6:
        return l10n.saturdayName;
      case 7:
        return l10n.sundayName;
      default:
        return l10n.mondayName;
    }
  }
}

/// Opt-in on-device AI toggle + live download progress.
///
/// Listens to [RecapAiProvider.events] so the subtitle + progress bar
/// reflect the real platform state (downloadable → downloading with
/// byte count → available). When the user flips the toggle on, we also
/// kick off `startDownload()` so the model fetch begins immediately
/// — no waiting for the first recap render to realise it needs to
/// download something.
class _OnDeviceAiRecapRow extends StatefulWidget {
  const _OnDeviceAiRecapRow({
    required this.provider,
    required this.settings,
    required this.onSettingsChanged,
  });

  final RecapAiProvider provider;
  final UserSettings settings;
  final ValueChanged<UserSettings> onSettingsChanged;

  @override
  State<_OnDeviceAiRecapRow> createState() => _OnDeviceAiRecapRowState();
}

class _OnDeviceAiRecapRowState extends State<_OnDeviceAiRecapRow> {
  RecapAiStatus _status = RecapAiStatus.unavailable;
  int _bytesDownloaded = 0;
  String? _errorMessage;
  bool _gotFirstEvent = false;

  late final Stream<RecapAiEvent> _events = widget.provider.events();

  @override
  void initState() {
    super.initState();
    // Prime with a one-shot probe so the row isn't stuck on the
    // "probing" default until the first EventChannel emission arrives.
    widget.provider.checkStatus().then((s) {
      if (!mounted) return;
      setState(() {
        _status = s;
        _gotFirstEvent = true;
      });
    });
  }

  void _onToggle(bool value) {
    widget.onSettingsChanged(
      widget.settings.copyWith(useOnDeviceAiForRecaps: value),
    );
    // Turning the toggle on kicks off the download so the user sees
    // immediate feedback. The ML Kit call is idempotent — if the model
    // is already on device, this no-ops.
    if (value &&
        (_status == RecapAiStatus.downloadable ||
            _status == RecapAiStatus.downloading)) {
      widget.provider.startDownload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final s = widget.settings;

    return StreamBuilder<RecapAiEvent>(
      stream: _events,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _status = snapshot.data!.status;
          _bytesDownloaded =
              snapshot.data!.bytesDownloaded ?? _bytesDownloaded;
          _errorMessage = snapshot.data!.errorMessage;
          _gotFirstEvent = true;
        }

        final supported = _status == RecapAiStatus.available ||
            _status == RecapAiStatus.downloadable ||
            _status == RecapAiStatus.downloading;
        final downloading = _status == RecapAiStatus.downloading &&
            s.useOnDeviceAiForRecaps;

        String subtitle;
        if (!_gotFirstEvent) {
          subtitle = l10n.onDeviceAiRecapSubtitle;
        } else if (!supported) {
          subtitle =
              _errorMessage ?? l10n.onDeviceAiRecapUnavailable;
        } else if (downloading) {
          subtitle = _bytesDownloaded > 0
              ? 'Downloading AI model… ${_formatBytes(_bytesDownloaded)}'
              : 'Downloading AI model…';
        } else if (_status == RecapAiStatus.downloadable &&
            s.useOnDeviceAiForRecaps) {
          subtitle = 'Starting download…';
        } else if (_status == RecapAiStatus.available &&
            s.useOnDeviceAiForRecaps) {
          subtitle = 'AI model ready on this device.';
        } else {
          subtitle = l10n.onDeviceAiRecapSubtitle;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsRow(
              title: l10n.onDeviceAiRecap,
              subtitle: subtitle,
              trailing: Semantics(
                label: l10n.onDeviceAiRecap,
                child: Switch(
                  value: supported && s.useOnDeviceAiForRecaps,
                  onChanged: supported ? _onToggle : null,
                  activeThumbColor: cs.primary,
                ),
              ),
            ),
            // Indeterminate progress bar while downloading — ML Kit
            // doesn't report a denominator so a determinate value
            // would lie. The pulsing bar + bytes caption communicate
            // "still working" honestly.
            if (downloading) ...[
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: cs.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'One-time download. Runs entirely on your device after.',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double value = bytes.toDouble();
    while (value >= 1024 && i < units.length - 1) {
      value /= 1024;
      i++;
    }
    // Two decimals for MB+; bytes/KB look silly with fractions.
    final formatted = i >= 2 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
    return '$formatted ${units[i]}';
  }
}
