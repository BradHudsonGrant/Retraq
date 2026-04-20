import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intercepts newlines and triggers save instead.
/// Strips the newline character so it never appears in the text.
class EnterToSaveFormatter extends TextInputFormatter {
  EnterToSaveFormatter({required this.onEnter});

  final VoidCallback onEnter;
  bool _firing = false;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Detect a newline that wasn't there before.
    if (!_firing &&
        newValue.text.contains('\n') &&
        (!oldValue.text.contains('\n') ||
            newValue.text.split('\n').length >
                oldValue.text.split('\n').length)) {
      _firing = true;
      // Schedule the save after this frame so the formatter returns cleanly.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onEnter();
        _firing = false;
      });
      // Return old value — swallow the newline.
      return oldValue;
    }
    return newValue;
  }
}

/// Replaces plain newlines with newline + bullet prefix.
/// On backspace at a bullet marker, collapses the line up.
class BulletPointFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // Backspace at a bullet: collapse "\n• " into just "\n"
    if (newText.length < oldText.length) {
      final cursor = newValue.selection.baseOffset;
      // Detect that "\n• " was partially deleted — the user backspaced
      // one char and cursor is right after "\n".
      // Check if old text had "\n• " ending right where the deletion happened.
      final deleted = oldText.length - newText.length;
      if (deleted == 1 && cursor >= 0 && cursor < newText.length) {
        // If cursor now sits right after \n and the old text had "• " after \n
        if (cursor > 0 &&
            newText[cursor - 1] == '\n' &&
            oldText.length > cursor + 1 &&
            oldText.substring(cursor, cursor + 2) == '• ') {
          // Remove the \n too — collapse lines
          final collapsed =
              newText.substring(0, cursor - 1) + newText.substring(cursor);
          return TextEditingValue(
            text: collapsed,
            selection: TextSelection.collapsed(offset: cursor - 1),
          );
        }
        // If user deleted the "•" and we're left with "\n " — clean up
        if (newText.substring(
                  (cursor - 1).clamp(0, newText.length),
                  (cursor + 1).clamp(0, newText.length),
                ) ==
                '\n ' ||
            (cursor >= 2 && newText.substring(cursor - 2, cursor) == '\n•')) {
          // Strip the whole bullet prefix: find the \n before cursor
          int nlPos = newText.lastIndexOf('\n', cursor - 1);
          if (nlPos == -1) nlPos = 0;
          // Remove from \n to cursor (inclusive of bullet remnants)
          String after = newText.substring(cursor);
          // Trim leading space/bullet from after
          if (after.startsWith(' ')) after = after.substring(1);
          final collapsed = newText.substring(0, nlPos) + after;
          return TextEditingValue(
            text: collapsed,
            selection: TextSelection.collapsed(offset: nlPos),
          );
        }
      }
      return newValue;
    }

    // Newline insertion: add bullet prefix.
    if (newText.length <= oldText.length) return newValue;

    final newChars = newText.length - oldText.length;
    final insertPos = newValue.selection.baseOffset - newChars;
    if (insertPos < 0) return newValue;

    final inserted = newText.substring(insertPos, insertPos + newChars);
    if (!inserted.contains('\n')) return newValue;

    final before = newText.substring(0, insertPos);
    final after = newText.substring(insertPos + newChars);
    final replaced = inserted.replaceAll('\n', '\n• ');
    final result = '$before$replaced$after';
    final cursorOffset = insertPos + replaced.length;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }
}
