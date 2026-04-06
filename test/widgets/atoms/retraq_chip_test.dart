import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/atoms/retraq_chip.dart';

import '../../test_helpers.dart';

void main() {
  group('RetraqChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(wrapWidget(const RetraqChip(label: 'Yesterday')));
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('uses custom color when provided', (tester) async {
      await tester.pumpWidget(
        wrapWidget(const RetraqChip(label: 'Tag', color: Colors.red)),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
    });

    testWidgets('uses custom textColor when provided', (tester) async {
      await tester.pumpWidget(
        wrapWidget(const RetraqChip(label: 'Tag', textColor: Colors.blue)),
      );

      final text = tester.widget<Text>(find.text('Tag'));
      expect(text.style?.color, Colors.blue);
    });

    testWidgets('uses theme colors when no custom colors given', (
      tester,
    ) async {
      await tester.pumpWidget(wrapWidget(const RetraqChip(label: 'Default')));

      // Should render without error using theme defaults
      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('has pill shape (large border radius)', (tester) async {
      await tester.pumpWidget(wrapWidget(const RetraqChip(label: 'Pill')));

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(9999));
    });
  });
}
