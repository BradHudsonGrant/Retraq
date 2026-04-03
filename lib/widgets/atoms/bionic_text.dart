import 'package:flutter/material.dart';

/// Renders text with bionic reading style: the first half of each word
/// is displayed in bold to help guide the eye through the text faster.
///
/// When [enabled] is `false`, renders as a plain [Text] widget.
class BionicText extends StatelessWidget {
  const BionicText({
    super.key,
    required this.text,
    this.style,
    this.enabled = true,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  /// The text content to display.
  final String text;

  /// Base text style. The bold portion uses [FontWeight.w700]
  /// (or [FontWeight.w800] when the base is already semi-bold).
  final TextStyle? style;

  /// When `false`, renders as a plain [Text] widget with no bionic styling.
  final bool enabled;

  /// Optional maximum number of lines.
  final int? maxLines;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (!enabled || text.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    return Text.rich(
      TextSpan(
        style: style,
        children: _buildSpans(),
      ),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  /// Splits [text] into words and whitespace, then builds [TextSpan]s
  /// where the first ceil(letterCount / 2) letters of each word are bold.
  List<TextSpan> _buildSpans() {
    final spans = <TextSpan>[];
    // Match runs of whitespace or runs of non-whitespace.
    final segments = RegExp(r'\S+|\s+').allMatches(text);

    final baseFontWeight = style?.fontWeight ?? FontWeight.w400;
    final boldWeight = baseFontWeight.index >= FontWeight.w600.index
        ? FontWeight.w800
        : FontWeight.w700;
    // Use fontVariations for variable fonts (Manrope) — renders crisper
    final boldVariations = baseFontWeight.index >= FontWeight.w600.index
        ? const [FontVariation('wght', 800)]
        : const [FontVariation('wght', 700)];

    for (final match in segments) {
      final segment = match.group(0)!;

      // Whitespace — preserve as-is.
      if (segment.trim().isEmpty) {
        spans.add(TextSpan(text: segment));
        continue;
      }

      // Single character words stay as-is.
      if (segment.length == 1) {
        spans.add(TextSpan(text: segment));
        continue;
      }

      // Count only letters/digits for the bold split, but keep the full
      // string intact (punctuation stays attached to its half).
      final letterIndices = <int>[];
      for (var i = 0; i < segment.length; i++) {
        if (_isLetterOrDigit(segment.codeUnitAt(i))) {
          letterIndices.add(i);
        }
      }

      // If the word has fewer than 2 letters, render as-is.
      if (letterIndices.length < 2) {
        spans.add(TextSpan(text: segment));
        continue;
      }

      // Bold the first ceil(letterCount / 2) letters.
      final boldLetterCount = (letterIndices.length + 1) ~/ 2;
      // The split index in the original string is right after the
      // last bold letter.
      final splitIndex = letterIndices[boldLetterCount - 1] + 1;

      spans.add(TextSpan(
        text: segment.substring(0, splitIndex),
        style: TextStyle(
          fontWeight: boldWeight,
          fontVariations: boldVariations,
        ),
      ));
      spans.add(TextSpan(
        text: segment.substring(splitIndex),
      ));
    }

    return spans;
  }

  /// Returns `true` for ASCII letters and digits.
  static bool _isLetterOrDigit(int codeUnit) {
    return (codeUnit >= 0x30 && codeUnit <= 0x39) || // 0-9
        (codeUnit >= 0x41 && codeUnit <= 0x5A) || // A-Z
        (codeUnit >= 0x61 && codeUnit <= 0x7A); // a-z
  }
}
