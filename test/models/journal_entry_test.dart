import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';

void main() {
  group('JournalEntry.displayText', () {
    test('returns the entry text when set', () {
      final entry = JournalEntry(
        date: DateTime(2026, 1, 1),
        entry: 'Had a great day',
      );
      expect(entry.displayText, 'Had a great day');
    });

    test('returns an empty string when entry is null', () {
      final entry = JournalEntry(date: DateTime(2026, 1, 1));
      expect(entry.displayText, '');
    });
  });

  group('JournalEntry.isEmpty', () {
    test('is true when entry is null', () {
      final entry = JournalEntry(date: DateTime(2026, 1, 1));
      expect(entry.isEmpty, true);
    });

    test('is true when entry is an empty string', () {
      final entry = JournalEntry(date: DateTime(2026, 1, 1), entry: '');
      expect(entry.isEmpty, true);
    });

    test('is false when entry has content', () {
      final entry = JournalEntry(
        date: DateTime(2026, 1, 1),
        entry: 'content',
      );
      expect(entry.isEmpty, false);
    });
  });

  group('JournalEntry.copyWith', () {
    test('title is nullable — copyWith can set and clear it', () {
      final entry = JournalEntry(date: DateTime(2026, 1, 1));
      expect(entry.title, isNull);

      final withTitle = entry.copyWith(title: 'My Title');
      expect(withTitle.title, 'My Title');

      final cleared = withTitle.copyWith(title: null);
      expect(cleared.title, isNull);
    });

    test('every field is settable', () {
      // Field-coverage guard: a field added to JournalEntry but forgotten
      // in copyWith would silently drop on save-edit-save round-trips.
      final entry = JournalEntry(date: DateTime(2026, 1, 1));
      final updated = entry.copyWith(
        id: 42,
        entry: 'Some text',
        label: 'AM',
        userId: 1,
      );

      expect(updated.id, 42);
      expect(updated.entry, 'Some text');
      expect(updated.label, 'AM');
      expect(updated.userId, 1);
    });
  });
}
