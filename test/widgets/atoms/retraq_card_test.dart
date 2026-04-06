import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/atoms/retraq_card.dart';

import '../../test_helpers.dart';

void main() {
  group('RetraqCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        wrapWidget(const RetraqCard(child: Text('Card Content'))),
      );
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          const RetraqCard(color: Colors.amber, child: Text('Colored')),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.amber);
    });

    testWidgets('onTap callback fires', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          RetraqCard(onTap: () => tapped = true, child: const Text('Tappable')),
        ),
      );

      await tester.tap(find.text('Tappable'));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('wraps in GestureDetector when onTap is set', (tester) async {
      await tester.pumpWidget(
        wrapWidget(RetraqCard(onTap: () {}, child: const Text('Tap'))),
      );
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('no GestureDetector when onTap is null', (tester) async {
      await tester.pumpWidget(
        wrapWidget(const RetraqCard(child: Text('No Tap'))),
      );
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('has AnimatedScale when tappable', (tester) async {
      await tester.pumpWidget(
        wrapWidget(RetraqCard(onTap: () {}, child: const Text('Scale'))),
      );
      expect(find.byType(AnimatedScale), findsOneWidget);
    });
  });
}
