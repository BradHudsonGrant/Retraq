import 'package:flutter/material.dart';
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
    final s = settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferences', style: tt.titleLarge),
        const SizedBox(height: AppSpacing.md),

        // All Day vs AM/PM
        SettingsRow(
          title: 'All Day Notes',
          subtitle: 'One entry or split AM/PM',
          trailing: SegmentedPill(
            leftLabel: 'AM/PM',
            rightLabel: 'All Day',
            isRightActive: s.isAllDayMode,
            onTapLeft: () => onSettingsChanged(s.copyWith(isAllDayMode: false)),
            onTapRight: () => onSettingsChanged(s.copyWith(isAllDayMode: true)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Opening behavior
        SettingsRow(
          title: 'Opening Prompt',
          subtitle: s.askAboutToday ? 'Asks about today' : 'Asks about yesterday',
          trailing: SegmentedPill(
            leftLabel: 'Today',
            rightLabel: 'Yesterday',
            isRightActive: !s.askAboutToday,
            onTapLeft: () => onSettingsChanged(s.copyWith(askAboutToday: true)),
            onTapRight: () => onSettingsChanged(s.copyWith(askAboutToday: false)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Journal entry title
        SettingsRow(
          title: 'Journal Entry Title',
          subtitle: 'Show or hide title fields in new entries',
          trailing: Semantics(
            label: 'Journal entry title',
            child: Switch(
              value: s.showEntryTitle,
              onChanged: (v) => onSettingsChanged(s.copyWith(showEntryTitle: v)),
              activeColor: cs.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Mood tracking
        SettingsRow(
          title: 'Mood Tracking',
          subtitle: 'Log how you feel with each entry',
          trailing: Semantics(
            label: 'Mood tracking',
            child: Switch(
              value: s.moodEnabled,
              onChanged: (v) => onSettingsChanged(s.copyWith(
                moodEnabled: v,
                // Disable dependent settings when mood is turned off
                moodRequired: v ? s.moodRequired : false,
                moodOnlyEntries: v ? s.moodOnlyEntries : false,
              )),
              activeColor: cs.primary,
            ),
          ),
        ),

        if (s.moodEnabled) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: SettingsRow(
              title: 'Require Mood',
              subtitle: 'Must pick a mood before saving',
              trailing: Semantics(
                label: 'Require mood selection',
                child: Switch(
                  value: s.moodRequired,
                  onChanged: (v) => onSettingsChanged(s.copyWith(moodRequired: v)),
                  activeColor: cs.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: SettingsRow(
              title: 'Mood-Only Entries',
              subtitle: 'Save entries with just a mood, no text',
              trailing: Semantics(
                label: 'Allow mood-only entries',
                child: Switch(
                  value: s.moodOnlyEntries,
                  onChanged: (v) => onSettingsChanged(s.copyWith(moodOnlyEntries: v)),
                  activeColor: cs.primary,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // Advanced settings
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              'Advanced',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            children: [
              SettingsRow(
                title: 'Enter to Save',
                subtitle: 'Press Enter to save entry instead of new line',
                trailing: Semantics(
                  label: 'Enter to save',
                  child: Switch(
                    value: s.enterToSave,
                    onChanged: (v) => onSettingsChanged(s.copyWith(
                      enterToSave: v,
                      bulletPointsOnEnter: v ? false : s.bulletPointsOnEnter,
                    )),
                    activeColor: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              SettingsRow(
                title: 'Bullet Points on Enter',
                subtitle: 'Auto-insert • when pressing Enter',
                trailing: Semantics(
                  label: 'Bullet points on enter',
                  child: Switch(
                    value: s.bulletPointsOnEnter,
                    onChanged: s.enterToSave
                        ? null
                        : (v) => onSettingsChanged(s.copyWith(
                            bulletPointsOnEnter: v,
                            enterToSave: v ? false : s.enterToSave,
                          )),
                    activeColor: cs.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              SettingsRow(
                title: 'Week Starts On',
                subtitle: _dayName(s.weekStartDay),
                trailing: Semantics(
                  label: 'Week starts on ${_dayName(s.weekStartDay)}',
                  child: DropdownButton<int>(
                  value: s.weekStartDay,
                  underline: const SizedBox.shrink(),
                  borderRadius: AppSpacing.borderRadiusLg,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Monday')),
                    DropdownMenuItem(value: 2, child: Text('Tuesday')),
                    DropdownMenuItem(value: 3, child: Text('Wednesday')),
                    DropdownMenuItem(value: 4, child: Text('Thursday')),
                    DropdownMenuItem(value: 5, child: Text('Friday')),
                    DropdownMenuItem(value: 6, child: Text('Saturday')),
                    DropdownMenuItem(value: 7, child: Text('Sunday')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    onSettingsChanged(s.copyWith(weekStartDay: v));
                  },
                )),
              ),
              const SizedBox(height: AppSpacing.md),

              if (!s.isAllDayMode)
                SettingsRow(
                  title: 'AM/PM Switches At',
                  subtitle: formatHour(s.amPmCutoffHour),
                  trailing: Semantics(
                    label: 'AM/PM switches at ${formatHour(s.amPmCutoffHour)}',
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
                  )),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _dayName(int weekday) {
    const names = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return names[weekday] ?? 'Monday';
  }
}
