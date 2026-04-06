import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/widgets/atoms/bionic_text.dart';

import '../../test_helpers.dart';

/// Extracts the bionic [TextSpan] children from a [BionicText] widget.
/// The widget tree is: RichText -> root TextSpan -> wrapper TextSpan(style) -> [children].
List<TextSpan> _bionicSpans(WidgetTester tester) {
  final bionicFinder = find.byType(BionicText);
  final richTextFinder = find.descendant(
    of: bionicFinder,
    matching: find.byType(RichText),
  );
  final richText = tester.widget<RichText>(richTextFinder);
  final rootSpan = richText.text as TextSpan;
  // The first child is the wrapper TextSpan with our base style.
  final wrapperSpan = rootSpan.children!.first as TextSpan;
  return wrapperSpan.children!.cast<TextSpan>();
}

void main() {
  group('BionicText', () {
    testWidgets('renders plain text when enabled is false', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const BionicText(
          text: 'Hello world',
          enabled: false,
        ),
      ));

      // When disabled, BionicText builds a plain Text(data) widget.
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders bionic bold spans when enabled is true',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const BionicText(
          text: 'Hello',
          enabled: true,
        ),
      ));

      final spans = _bionicSpans(tester);

      // "Hello" (5 letters) -> bold "Hel" + normal "lo"
      expect(spans.length, 2);
      expect(spans[0].text, 'Hel');
      expect(spans[0].style?.fontWeight, FontWeight.w900);
      expect(spans[1].text, 'lo');
    });

    testWidgets('single character words are not bolded', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const BionicText(
          text: 'I am a test',
          enabled: true,
        ),
      ));

      final spans = _bionicSpans(tester);
      final texts = spans.map((s) => s.text).toList();

      // "I" (1 char, no split), " ", "a"|"m" (from "am"), " ",
      // "a" (1 char, no split), " ", "te"|"st" (from "test")
      expect(texts, ['I', ' ', 'a', 'm', ' ', 'a', ' ', 'te', 'st']);

      // Single-char "I" should have no bold style override.
      expect(spans[0].style?.fontWeight, isNull);

      // "a" (bold part of "am") should be bold.
      expect(spans[2].style?.fontWeight, FontWeight.w900);
    });

    testWidgets('empty string is handled', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const BionicText(
          text: '',
          enabled: true,
        ),
      ));

      // Empty string triggers early return -> plain Text widget.
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('punctuation does not count toward bold length',
        (tester) async {
      await tester.pumpWidget(wrapWidget(
        const BionicText(
          text: 'hello,',
          enabled: true,
        ),
      ));

      final spans = _bionicSpans(tester);

      // "hello," has 5 letters -> ceil(5/2) = 3 bold -> "hel" + "lo,"
      expect(spans.length, 2);
      expect(spans[0].text, 'hel');
      expect(spans[0].style?.fontWeight, FontWeight.w900);
      expect(spans[1].text, 'lo,');
    });

    testWidgets('passes through maxLines and overflow', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const BionicText(
          text: 'Some text here',
          enabled: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ));

      final textFinder = find.descendant(
        of: find.byType(BionicText),
        matching: find.byType(Text),
      );
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('preserves whitespace between words', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const BionicText(
          text: 'hi  there',
          enabled: true,
        ),
      ));

      final spans = _bionicSpans(tester);
      final texts = spans.map((s) => s.text).toList();

      // "hi" -> "h" bold + "i" normal, "  " whitespace, "the" bold + "re" normal
      expect(texts, ['h', 'i', '  ', 'the', 're']);
    });
  });
}
