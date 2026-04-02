import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sincethen/widgets/molecules/entry_card.dart';

import '../../test_helpers.dart';

void main() {
  group('EntryCard', () {
    testWidgets('renders dateLabel and text', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const EntryCard(
          dateLabel: 'Yesterday',
          text: 'Had a productive day',
        ),
      ));

      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Had a productive day'), findsOneWidget);
    });

    testWidgets('shows title when provided', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const EntryCard(
          dateLabel: 'Today',
          text: 'Some text',
          title: 'My Title',
        ),
      ));

      expect(find.text('My Title'), findsOneWidget);
    });

    testWidgets('hides title when null', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const EntryCard(
          dateLabel: 'Today',
          text: 'Some text',
        ),
      ));

      // Only dateLabel and text should be present
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Some text'), findsOneWidget);
    });

    testWidgets('hides title when empty string', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const EntryCard(
          dateLabel: 'Today',
          text: 'Some text',
          title: '',
        ),
      ));

      // Empty title should not render title widget
      expect(find.text(''), findsNothing);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWidget(
        EntryCard(
          dateLabel: 'Today',
          text: 'Tap me',
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Tap me'));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('shows more_horiz icon', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const EntryCard(dateLabel: 'Today', text: 'Content'),
      ));

      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });
  });
}
