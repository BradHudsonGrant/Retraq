import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class NudgeCard extends StatelessWidget {
  const NudgeCard({
    super.key,
    required this.nudgeHour,
    required this.onChangeTime,
  });

  final int nudgeHour;
  final VoidCallback onChangeTime;

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:00 $period';
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
                'Daily at ${_formatHour(nudgeHour)}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onPrimary,
                ),
              ),
              FilledButton(
                onPressed: onChangeTime,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.surfaceContainerLowest,
                  foregroundColor: cs.primary,
                  shape: const StadiumBorder(),
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
