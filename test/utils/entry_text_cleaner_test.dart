// ignore_for_file: prefer_single_quotes

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/utils/entry_text_cleaner.dart';

/// tests for `cleanEntryText`, the pure-function
/// canonicaliser previously stuck as `_cleanText` inside
/// home_screen.dart. Every branch of the rule now has a dedicated
/// case so future refactors can swap the implementation safely.
void main() {
  test('plain text passes through unchanged (trimmed)', () {
    expect(cleanEntryText('A quick traq.'), 'A quick traq.');
  });

  test('leading + trailing whitespace is trimmed', () {
    expect(cleanEntryText('   spacious   '), 'spacious');
  });

  test('empty string → empty string', () {
    expect(cleanEntryText(''), '');
  });

  test('whitespace-only input → empty (not whitespace)', () {
    expect(cleanEntryText('   \n\t\n   '), '',
        reason:
            'A draft of only whitespace must canonicalise to empty — '
            'validation treats this as "no text" and refuses to save.');
  });

  test('blank lines between content are dropped', () {
    expect(
      cleanEntryText('first line\n\n\nsecond line'),
      'first line\nsecond line',
    );
  });

  test('lone bullet lines (•) are dropped', () {
    // bulletPointsOnEnter auto-inserts • on newline; pressing Enter
    // a few times without typing leaves a stack of bullet-only rows.
    expect(
      cleanEntryText('Real item\n•\n•\n•'),
      'Real item',
      reason:
          'Empty-bullet rows from bulletPointsOnEnter must not '
          'survive to the DB.',
    );
  });

  test('bullet followed by content stays', () {
    expect(
      cleanEntryText('• first\n• second'),
      '• first\n• second',
    );
  });

  test('mixed bullet + text + whitespace normalises cleanly', () {
    expect(
      cleanEntryText('• one\n  \n• two\n\n•\n• three'),
      '• one\n• two\n• three',
    );
  });

  test('single newline preserved within content', () {
    expect(
      cleanEntryText('line a\nline b'),
      'line a\nline b',
    );
  });

  test('windows-style line endings: \\r stays on the preceding line', () {
    // cleanEntryText only splits on \n. If Windows-style \r\n shows
    // up (unlikely on Flutter text input, but still) the \r is
    // treated as trailing whitespace on the preceding line and gets
    // trimmed. Pin this so a future regex change doesn't silently
    // duplicate or drop lines.
    expect(
      cleanEntryText('first\r\nsecond\r\n'),
      'first\nsecond',
    );
  });
}
