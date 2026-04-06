import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/molecules/segmented_pill.dart';

import '../../test_helpers.dart';

void main() {
  group('SegmentedPill', () {
    testWidgets('renders both labels', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SegmentedPill(
            leftLabel: 'AM',
            rightLabel: 'PM',
            isRightActive: false,
            onTapLeft: () {},
            onTapRight: () {},
          ),
        ),
      );

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('tapping left calls onTapLeft', (tester) async {
      var leftTapped = false;
      await tester.pumpWidget(
        wrapWidget(
          SegmentedPill(
            leftLabel: 'Left',
            rightLabel: 'Right',
            isRightActive: true,
            onTapLeft: () => leftTapped = true,
            onTapRight: () {},
          ),
        ),
      );

      await tester.tap(find.text('Left'));
      expect(leftTapped, true);
    });

    testWidgets('tapping right calls onTapRight', (tester) async {
      var rightTapped = false;
      await tester.pumpWidget(
        wrapWidget(
          SegmentedPill(
            leftLabel: 'Left',
            rightLabel: 'Right',
            isRightActive: false,
            onTapLeft: () {},
            onTapRight: () => rightTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Right'));
      expect(rightTapped, true);
    });

    testWidgets('renders with Week/Month labels', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SegmentedPill(
            leftLabel: 'Week',
            rightLabel: 'Month',
            isRightActive: true,
            onTapLeft: () {},
            onTapRight: () {},
          ),
        ),
      );

      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });
  });
}
