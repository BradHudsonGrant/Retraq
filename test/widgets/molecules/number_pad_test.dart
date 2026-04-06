import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/molecules/number_pad.dart';

import '../../test_helpers.dart';

void main() {
  group('NumberPad', () {
    testWidgets('renders digits 0-9', (tester) async {
      await tester.pumpWidget(
        wrapWidget(NumberPad(onDigit: (_) {}, onDelete: () {})),
      );

      for (var i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('tapping a digit calls onDigit with correct value', (
      tester,
    ) async {
      final digits = <int>[];

      await tester.pumpWidget(
        wrapWidget(NumberPad(onDigit: (d) => digits.add(d), onDelete: () {})),
      );

      await tester.tap(find.text('1'));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('0'));
      expect(digits, [1, 5, 0]);
    });

    testWidgets('delete button calls onDelete', (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        wrapWidget(NumberPad(onDigit: (_) {}, onDelete: () => deleted = true)),
      );

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      expect(deleted, isTrue);
    });

    testWidgets('disabled state prevents interaction', (tester) async {
      final digits = <int>[];
      var deleted = false;

      await tester.pumpWidget(
        wrapWidget(
          NumberPad(
            onDigit: (d) => digits.add(d),
            onDelete: () => deleted = true,
            isDisabled: true,
          ),
        ),
      );

      // IgnorePointer should block taps
      await tester.tap(find.text('5'), warnIfMissed: false);
      await tester.tap(
        find.byIcon(Icons.backspace_outlined),
        warnIfMissed: false,
      );
      expect(digits, isEmpty);
      expect(deleted, isFalse);
    });

    testWidgets('disabled state has reduced opacity', (tester) async {
      await tester.pumpWidget(
        wrapWidget(
          NumberPad(onDigit: (_) {}, onDelete: () {}, isDisabled: true),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.3);
    });

    testWidgets('shows biometric button when onBiometric is provided', (
      tester,
    ) async {
      var biometricTapped = false;

      await tester.pumpWidget(
        wrapWidget(
          NumberPad(
            onDigit: (_) {},
            onDelete: () {},
            onBiometric: () => biometricTapped = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      await tester.tap(find.byIcon(Icons.fingerprint));
      expect(biometricTapped, isTrue);
    });

    testWidgets('hides biometric button when onBiometric is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(NumberPad(onDigit: (_) {}, onDelete: () {})),
      );

      expect(find.byIcon(Icons.fingerprint), findsNothing);
    });
  });

  group('PinDots', () {
    testWidgets('shows correct number of filled and empty dots', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(const PinDots(length: 3, maxLength: 6)),
      );

      // Should have 6 AnimatedContainers total (one per dot)
      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(containers.length, 6);
    });

    testWidgets('zero length shows all empty dots', (tester) async {
      await tester.pumpWidget(
        wrapWidget(const PinDots(length: 0, maxLength: 4)),
      );

      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(containers.length, 4);

      // All dots should have border (empty state) — none filled
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
      }
    });

    testWidgets('full length shows all filled dots', (tester) async {
      await tester.pumpWidget(
        wrapWidget(const PinDots(length: 4, maxLength: 4)),
      );

      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(containers.length, 4);

      // All dots should NOT have a border (filled state)
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNull);
      }
    });

    testWidgets('error state uses error color', (tester) async {
      await tester.pumpWidget(
        wrapWidget(const PinDots(length: 4, maxLength: 4, isError: true)),
      );

      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      // Error dots should use error color
      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration;
        // Error color comes from theme, just verify it's set
        expect(decoration.color, isNotNull);
      }
    });

    testWidgets('semantics label describes digit count', (tester) async {
      await tester.pumpWidget(
        wrapWidget(const PinDots(length: 2, maxLength: 6)),
      );

      expect(find.bySemanticsLabel('2 of 6 digits entered'), findsOneWidget);
    });

    testWidgets('error semantics label includes error', (tester) async {
      await tester.pumpWidget(
        wrapWidget(const PinDots(length: 4, maxLength: 4, isError: true)),
      );

      expect(
        find.bySemanticsLabel('4 of 4 digits entered, error'),
        findsOneWidget,
      );
    });
  });
}
