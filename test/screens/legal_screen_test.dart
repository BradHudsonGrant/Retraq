import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/screens/legal_screen.dart';

void main() {
  const testContent = '''
# Test Title

This is a paragraph.

## Section Header

- Bullet one
- Bullet two

**Bold text** here.
''';

  Widget wrap(Widget child) => MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => child),
            ),
            child: const Text('Go'),
          ),
        ),
      );

  bool richTextContains(Widget widget, String text) {
    if (widget is RichText) {
      return widget.text.toPlainText().contains(text);
    }
    return false;
  }

  group('LegalScreen', () {
    testWidgets('renders the title in app bar', (tester) async {
      await tester.pumpWidget(wrap(
        const LegalScreen(title: 'My Legal Page', content: testContent),
      ));
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'My Legal Page'), findsOneWidget);
    });

    testWidgets('renders body content text', (tester) async {
      await tester.pumpWidget(wrap(
        const LegalScreen(title: 'Legal', content: testContent),
      ));
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => richTextContains(w, 'This is a paragraph.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders headings from markdown', (tester) async {
      await tester.pumpWidget(wrap(
        const LegalScreen(title: 'Legal', content: testContent),
      ));
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // # heading is rendered without the # prefix
      expect(find.text('Test Title'), findsOneWidget);
      // ## subheading is rendered without the ## prefix
      expect(find.text('Section Header'), findsOneWidget);
    });

    testWidgets('renders bullet list items', (tester) async {
      await tester.pumpWidget(wrap(
        const LegalScreen(title: 'Legal', content: testContent),
      ));
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) => richTextContains(w, 'Bullet one')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => richTextContains(w, 'Bullet two')),
        findsOneWidget,
      );
      // Bullet character is rendered
      expect(find.text('\u2022  '), findsNWidgets(2));
    });

    testWidgets('shows back button in app bar', (tester) async {
      await tester.pumpWidget(wrap(
        const LegalScreen(title: 'Legal', content: testContent),
      ));
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // AppBar shows a back button when pushed onto a navigation stack
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        ),
        findsOneWidget,
      );
    });
  });
}
