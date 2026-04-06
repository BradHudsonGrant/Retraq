// ignore_for_file: prefer_single_quotes
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/utils/text_input_formatters.dart';

/// Helper to simulate a format update.
TextEditingValue _format(
  TextInputFormatter formatter,
  TextEditingValue oldValue,
  TextEditingValue newValue,
) {
  return formatter.formatEditUpdate(oldValue, newValue);
}

TextEditingValue _val(String text, {int? offset}) {
  final o = offset ?? text.length;
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: o),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BulletPointFormatter', () {
    late BulletPointFormatter formatter;

    setUp(() {
      formatter = BulletPointFormatter();
    });

    test('passes through normal text insertion unchanged', () {
      final result = _format(formatter, _val('Hello'), _val('Hello world'));
      expect(result.text, 'Hello world');
    });

    test('inserts bullet prefix after newline', () {
      // User types "Hello" then presses Enter
      final result = _format(
        formatter,
        _val('Hello'),
        _val('Hello\n', offset: 6),
      );
      expect(result.text, 'Hello\n• ');
    });

    test('inserts bullet prefix for newline in the middle of text', () {
      // User presses Enter after "Hello" when "world" follows
      final oldVal = _val('Helloworld', offset: 5);
      final newVal = _val('Hello\nworld', offset: 6);
      final result = _format(formatter, oldVal, newVal);
      expect(result.text, 'Hello\n• world');
    });

    test('handles multiple newlines in pasted text', () {
      final oldVal = _val('');
      final newVal = _val('line1\nline2\nline3', offset: 17);
      final result = _format(formatter, oldVal, newVal);
      expect(result.text, 'line1\n• line2\n• line3');
    });

    test('passes through deletion of normal characters', () {
      // Deleting a normal character (backspace from "Hello" to "Hell")
      final result = _format(
        formatter,
        _val('Hello', offset: 5),
        _val('Hell', offset: 4),
      );
      expect(result.text, 'Hell');
    });
  });

  group('EnterToSaveFormatter', () {
    test('swallows newline and returns old value', () {
      final formatter = EnterToSaveFormatter(onEnter: () {});

      final oldVal = _val('Hello');
      final newVal = _val('Hello\n', offset: 6);
      final result = _format(formatter, oldVal, newVal);

      // Should return old value (swallow the newline)
      expect(result.text, 'Hello');
      // onEnter is scheduled via addPostFrameCallback, so it won't fire
      // synchronously in a unit test — we just verify the newline was swallowed
    });

    test('allows normal text through', () {
      final formatter = EnterToSaveFormatter(onEnter: () {});

      final oldVal = _val('Hello');
      final newVal = _val('Hello world');
      final result = _format(formatter, oldVal, newVal);

      expect(result.text, 'Hello world');
    });

    test('allows deletion through', () {
      final formatter = EnterToSaveFormatter(onEnter: () {});

      final oldVal = _val('Hello');
      final newVal = _val('Hell', offset: 4);
      final result = _format(formatter, oldVal, newVal);

      expect(result.text, 'Hell');
    });
  });
}
