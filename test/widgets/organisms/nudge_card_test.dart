import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/organisms/nudge_card.dart';

import '../../test_helpers.dart';

void main() {
  group('NudgeCard', () {
    testWidgets('renders formatted time correctly for PM', (tester) async {
      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 20,
          nudgeMinute: 30,
          onChangeTime: () {},
        ),
      ));

      expect(find.text('Daily at 8:30 PM'), findsOneWidget);
    });

    testWidgets('renders formatted time correctly for AM', (tester) async {
      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 9,
          nudgeMinute: 15,
          onChangeTime: () {},
        ),
      ));

      expect(find.text('Daily at 9:15 AM'), findsOneWidget);
    });

    testWidgets('handles midnight (hour 0) correctly', (tester) async {
      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 0,
          nudgeMinute: 0,
          onChangeTime: () {},
        ),
      ));

      expect(find.text('Daily at 12:00 AM'), findsOneWidget);
    });

    testWidgets('handles noon (hour 12) correctly', (tester) async {
      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 12,
          nudgeMinute: 0,
          onChangeTime: () {},
        ),
      ));

      expect(find.text('Daily at 12:00 PM'), findsOneWidget);
    });

    testWidgets('shows minute with leading zero when needed', (tester) async {
      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 8,
          nudgeMinute: 5,
          onChangeTime: () {},
        ),
      ));

      // Should be "8:05 AM" not "8:5 AM"
      expect(find.text('Daily at 8:05 AM'), findsOneWidget);
    });

    testWidgets('renders nudge description text', (tester) async {
      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 20,
          nudgeMinute: 0,
          onChangeTime: () {},
        ),
      ));

      expect(
        find.textContaining('Get a quick nudge'),
        findsOneWidget,
      );
    });

    testWidgets('renders Change Time button', (tester) async {
      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 20,
          nudgeMinute: 0,
          onChangeTime: () {},
        ),
      ));

      expect(find.text('Change Time'), findsOneWidget);
    });

    testWidgets('Change Time button fires onChangeTime callback',
        (tester) async {
      var changeTimeTapped = false;

      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 20,
          nudgeMinute: 0,
          onChangeTime: () => changeTimeTapped = true,
        ),
      ));

      await tester.tap(find.text('Change Time'));
      expect(changeTimeTapped, isTrue);
    });

    testWidgets('renders notification icon', (tester) async {
      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 20,
          nudgeMinute: 0,
          onChangeTime: () {},
        ),
      ));

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('default minute is 0', (tester) async {
      await tester.pumpWidget(wrapWidget(
        NudgeCard(
          nudgeHour: 21,
          onChangeTime: () {},
        ),
      ));

      expect(find.text('Daily at 9:00 PM'), findsOneWidget);
    });
  });
}
