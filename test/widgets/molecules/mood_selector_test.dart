import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/atoms/mood_blob.dart';
import 'package:retraq/widgets/molecules/mood_selector.dart';

import '../../test_helpers.dart';

void main() {
  group('MoodSelector', () {
    testWidgets('renders 5 mood options with correct labels', (tester) async {
      await tester.pumpWidget(
        wrapWidget(MoodSelector(selectedMood: null, onChanged: (_) {})),
      );

      expect(find.text('Rough'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Neutral'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Amazing'), findsOneWidget);
    });

    testWidgets('tapping a mood calls onChanged with correct value', (
      tester,
    ) async {
      int? selectedValue;

      await tester.pumpWidget(
        wrapWidget(
          MoodSelector(selectedMood: null, onChanged: (v) => selectedValue = v),
        ),
      );

      await tester.tap(find.text('Good'));
      expect(selectedValue, 4);
    });

    testWidgets('tapping selected mood calls onChanged with null (deselect)', (
      tester,
    ) async {
      int? selectedValue = 3;

      await tester.pumpWidget(
        wrapWidget(
          MoodSelector(selectedMood: 3, onChanged: (v) => selectedValue = v),
        ),
      );

      await tester.tap(find.text('Neutral'));
      expect(selectedValue, isNull);
    });

    testWidgets('selected mood shows visual selection state', (tester) async {
      await tester.pumpWidget(
        wrapWidget(MoodSelector(selectedMood: 2, onChanged: (_) {})),
      );

      await tester.pump();

      // The selected mood's AnimatedContainer should have a border.
      // Find the AnimatedContainer that is a descendant of the "Low" column.
      final selectedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.ancestor(
            of: find.text('Low'),
            matching: find.byType(InkWell),
          ),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = selectedContainer.decoration as BoxDecoration;
      expect(
        decoration.border,
        isNotNull,
        reason: 'Selected mood should have a colored ring border',
      );
    });

    testWidgets('unselected mood has no border', (tester) async {
      await tester.pumpWidget(
        wrapWidget(MoodSelector(selectedMood: 2, onChanged: (_) {})),
      );

      await tester.pump();

      // "Amazing" (value 5) is not selected — its container should have no border.
      final unselectedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.ancestor(
            of: find.text('Amazing'),
            matching: find.byType(InkWell),
          ),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = unselectedContainer.decoration as BoxDecoration;
      expect(
        decoration.border,
        isNull,
        reason: 'Unselected mood should not have a border',
      );
    });

    testWidgets('renders MoodBlob widgets', (tester) async {
      await tester.pumpWidget(
        wrapWidget(MoodSelector(selectedMood: null, onChanged: (_) {})),
      );

      expect(find.byType(MoodBlob), findsNWidgets(5));
    });

    testWidgets('onChanged callback fires for each mood', (tester) async {
      final tapped = <int?>[];

      await tester.pumpWidget(
        wrapWidget(
          MoodSelector(selectedMood: null, onChanged: (v) => tapped.add(v)),
        ),
      );

      await tester.tap(find.text('Rough'));
      await tester.tap(find.text('Amazing'));
      expect(tapped, [1, 5]);
    });
  });

  group('moodLabel', () {
    test('returns correct labels for values 1-5', () {
      expect(moodLabel(1), 'Rough');
      expect(moodLabel(2), 'Low');
      expect(moodLabel(3), 'Neutral');
      expect(moodLabel(4), 'Good');
      expect(moodLabel(5), 'Amazing');
    });

    test('returns empty string for out-of-range values', () {
      expect(moodLabel(0), '');
      expect(moodLabel(6), '');
      expect(moodLabel(-1), '');
    });
  });

  group('moodEmoji', () {
    test('returns non-empty emoji for values 1-5', () {
      for (var i = 1; i <= 5; i++) {
        expect(moodEmoji(i), isNotEmpty);
      }
    });

    test('returns empty string for out-of-range values', () {
      expect(moodEmoji(0), '');
      expect(moodEmoji(6), '');
    });
  });
}
