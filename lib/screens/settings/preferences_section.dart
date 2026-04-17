import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_settings.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/molecules/segmented_pill.dart';
import '../../widgets/molecules/settings_row.dart';

class PreferencesSection extends StatelessWidget {
  const PreferencesSection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final UserSettings settings;
  final ValueChanged<UserSettings> onSettingsChanged;

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

        // Mood tracking — Task 4.5: single-switch UX per Run 7 survey.
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

        // Bionic Reading
        SettingsRow(
          title: l10n.bionicReading,
          subtitle: l10n.bionicReadingSubtitle,
          trailing: Semantics(
            label: l10n.bionicReading,
            child: Switch(
              value: s.bionicReadingEnabled,
              onChanged:
                  (v) => onSettingsChanged(s.copyWith(bionicReadingEnabled: v)),
              activeThumbColor: cs.primary,
            ),
          ),
        ),
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
