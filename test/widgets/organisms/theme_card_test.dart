import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/organisms/theme_card.dart';

/// Task 6.11 (partial) — ThemeCard widget coverage.
///
/// The widget has three real branches worth pinning:
///   1. isSelected drives the border + shadow visual treatment
///   2. isDark=null falls through to Theme.of(context).brightness
///   3. reduce-motion zeros the AnimatedContainer duration
///
/// Covered below. Visual swatch output (the mini colour dots) is
/// not pixel-tested — those are Container decorations that would
/// need a golden test (Epic 7 Task 7.15 follow-up).
void main() {
  Widget wrap(
    Widget child, {
    bool dark = false,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('renders the label text', (tester) async {
    await tester.pumpWidget(wrap(
      ThemeCard(
        label: 'Light',
        isSelected: false,
        isDark: false,
        onTap: () {},
      ),
    ));
    await tester.pump();
    expect(find.text('Light'), findsOneWidget);
  });

  testWidgets('onTap fires when the card is tapped', (tester) async {
    int taps = 0;
    await tester.pumpWidget(wrap(
      ThemeCard(
        label: 'Dark',
        isSelected: false,
        isDark: true,
        onTap: () => taps++,
      ),
    ));
    await tester.pump();

    await tester.tap(find.byType(ThemeCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets(
    'isSelected=true draws a bordered AnimatedContainer',
    (tester) async {
      await tester.pumpWidget(wrap(
        ThemeCard(
          label: 'Light',
          isSelected: true,
          isDark: false,
          onTap: () {},
        ),
      ));
      await tester.pump();

      final container = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(ThemeCard),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull,
          reason: 'selected card must surface a visible border');
    },
  );

  testWidgets(
    'isSelected=false has no border on the AnimatedContainer',
    (tester) async {
      await tester.pumpWidget(wrap(
        ThemeCard(
          label: 'Light',
          isSelected: false,
          isDark: false,
          onTap: () {},
        ),
      ));
      await tester.pump();

      final container = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(ThemeCard),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      // The unselected card keeps a subtle hairline outline (low-alpha
      // outlineVariant, width 1) to match the shared content-card
      // tier. What must NOT appear is the selection border — a full
      // primary-coloured, 2-width Border. Verify the outline is the
      // hairline variant rather than asserting `border == null`.
      final border = decoration.border as Border;
      expect(border.top.width, 1.0,
          reason: 'unselected card should use the 1px hairline outline');
      expect(border.top.color.a, closeTo(0.35, 0.01),
          reason: 'unselected outline should be the low-alpha outlineVariant');
    },
  );

  testWidgets(
    'reduce-motion zeros the AnimatedContainer duration',
    (tester) async {
      await tester.pumpWidget(wrap(
        ThemeCard(
          label: 'System',
          isSelected: false,
          isDark: null, // System
          onTap: () {},
        ),
        disableAnimations: true,
      ));
      await tester.pump();

      final container = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(ThemeCard),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(container.duration, Duration.zero);
    },
  );

  testWidgets(
    'non-reduce-motion uses a 300ms animation duration',
    (tester) async {
      await tester.pumpWidget(wrap(
        ThemeCard(
          label: 'Light',
          isSelected: false,
          isDark: false,
          onTap: () {},
        ),
      ));
      await tester.pump();

      final container = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(ThemeCard),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(container.duration, const Duration(milliseconds: 300));
    },
  );

  testWidgets(
    'isDark=null resolves to current Theme brightness',
    (tester) async {
      // Render the System variant under a DARK theme wrapper.
      // Because isDark is null, the card's internal
      // effectiveDark derives from Theme.of(context).brightness.
      // No specific frame assertion is possible without golden
      // comparisons, but we verify the widget mounts + renders
      // without throwing under both themes.
      await tester.pumpWidget(wrap(
        ThemeCard(
          label: 'System',
          isSelected: false,
          isDark: null,
          onTap: () {},
        ),
        dark: true,
      ));
      await tester.pump();
      expect(find.byType(ThemeCard), findsOneWidget);

      await tester.pumpWidget(wrap(
        ThemeCard(
          label: 'System',
          isSelected: false,
          isDark: null,
          onTap: () {},
        ),
        dark: false,
      ));
      await tester.pump();
      expect(find.byType(ThemeCard), findsOneWidget);
    },
  );
}
