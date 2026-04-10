import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/atoms/retraq_button.dart';

import '../../test_helpers.dart';

void main() {
  group('RetraqButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        wrapWidget(RetraqButton(label: 'Save Entry', onPressed: () {})),
      );
      expect(find.text('Save Entry'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          RetraqButton(label: 'Save', icon: Icons.check, onPressed: () {}),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('calls onPressed on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          RetraqButton(label: 'Tap Me', onPressed: () => tapped = true),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('does not fire when onPressed is null (disabled)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(const RetraqButton(label: 'Disabled', onPressed: null)),
      );

      // Widget renders but button is disabled
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('uses OutlinedButton when isOutlined is true', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          RetraqButton(label: 'Outlined', isOutlined: true, onPressed: () {}),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('uses FilledButton by default', (tester) async {
      await tester.pumpWidget(
        wrapWidget(RetraqButton(label: 'Filled', onPressed: () {})),
      );
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('has AnimatedScale for press feedback', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          RetraqButton(label: 'Animate', onPressed: () {}),
          enableAnimations: true,
        ),
      );
      expect(find.byType(AnimatedScale), findsOneWidget);
    });
  });
}
