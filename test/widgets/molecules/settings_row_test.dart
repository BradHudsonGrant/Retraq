import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/molecules/settings_row.dart';

import '../../test_helpers.dart';

void main() {
  group('SettingsRow', () {
    testWidgets('renders title and trailing widget', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SettingsRow(
          title: 'Dark Mode',
          trailing: Icon(Icons.toggle_on),
        ),
      ));

      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.byIcon(Icons.toggle_on), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SettingsRow(
          title: 'App Lock',
          subtitle: 'PIN required to open',
          trailing: Icon(Icons.lock),
        ),
      ));

      expect(find.text('App Lock'), findsOneWidget);
      expect(find.text('PIN required to open'), findsOneWidget);
    });

    testWidgets('hides subtitle when null', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const SettingsRow(
          title: 'Simple Row',
          trailing: Icon(Icons.arrow_forward),
        ),
      ));

      expect(find.text('Simple Row'), findsOneWidget);
      // Only one text widget (the title)
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('trailing switch is interactive', (tester) async {
      var toggled = false;
      await tester.pumpWidget(wrapWidget(
        SettingsRow(
          title: 'Toggle',
          trailing: Switch(
            value: false,
            onChanged: (v) => toggled = true,
          ),
        ),
      ));

      await tester.tap(find.byType(Switch));
      expect(toggled, true);
    });
  });
}
