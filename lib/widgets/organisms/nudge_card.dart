import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class NudgeCard extends StatelessWidget {
  const NudgeCard({
    super.key,
    required this.nudgeHour,
    this.nudgeMinute = 0,
    required this.onChangeTime,
  });

  final int nudgeHour;
  final int nudgeMinute;
  final VoidCallback onChangeTime;

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: AppSpacing.borderRadiusXxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(Icons.notifications_active, size: 36, color: cs.onPrimary)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Get a quick nudge to drop a breadcrumb before you forget your day.',
            style: tt.titleMedium?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily at ${_formatTime(nudgeHour, nudgeMinute)}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onPrimary,
                ),
              ),
              FilledButton(
                onPressed: onChangeTime,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.surfaceContainerLowest,
                  foregroundColor: cs.primary,
                ),
                child: const Text('Change Time'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
