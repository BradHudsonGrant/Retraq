// ignore_for_file: prefer_single_quotes

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/l10n/app_localizations.dart';
import 'package:retraq/utils/test_keys.dart';
import 'package:retraq/widgets/molecules/title_field.dart';

import '../../test_helpers.dart';

/// Task 1.2 — tests for the TitleField molecule extracted from
/// home_screen.dart. Pure presentational widget; tests focus on:
///   - controller binding (typing populates the parent controller)
///   - TestKey presence (existing home widget tests locate the
///     field via TestKeys.homeTitleField)
///   - InputDecoration sanity (label + hint resolve from ARB)
///   - TextCapitalization.sentences on the real TextField
void main() {
  testWidgets('TitleField binds to parent TextEditingController',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrapWidget(TitleField(controller: controller)));
    await tester.pump();

    await tester.enterText(
      find.byKey(TestKeys.homeTitleField),
      'Morning notes',
    );
    expect(controller.text, 'Morning notes',
        reason:
            'Typing into the TitleField must populate the parent-owned '
            'TextEditingController. If this breaks, home_screen save '
            'flow loses the optional title.');
  });

  testWidgets('TitleField renders with the existing TestKey',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrapWidget(TitleField(controller: controller)));
    await tester.pump();

    expect(find.byKey(TestKeys.homeTitleField), findsOneWidget,
        reason:
            'Pre-extraction home widget tests use TestKeys.homeTitleField '
            'to locate the field. Extraction must not break that key '
            'path.');
  });

  testWidgets('TitleField uses localized hint + label strings',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrapWidget(TitleField(controller: controller)));
    await tester.pump();

    final l10n = await L10n.delegate.load(const Locale('en'));
    // Label shows when field is empty; hint shows as placeholder.
    // Either can win the finder depending on render order.
    expect(
      find.text(l10n.entryTitleHint).evaluate().isNotEmpty ||
          find.text(l10n.entryTitleLabel).evaluate().isNotEmpty,
      isTrue,
      reason:
          'Either entryTitleHint or entryTitleLabel must be on screen — '
          'hardcoded English would fail the ARB-drift check.',
    );
  });

  testWidgets('TextCapitalization.sentences applied to the TextField',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrapWidget(TitleField(controller: controller)));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(TestKeys.homeTitleField),
    );
    expect(field.textCapitalization, TextCapitalization.sentences,
        reason:
            'ADHD-friendly autocap behaviour: first-letter caps on new '
            'sentences. Dropping this would regress a previously-landed '
            'UX pass.');
  });
}
