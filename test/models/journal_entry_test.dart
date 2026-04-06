import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';

void main() {
  group('JournalEntry', () {
    test('constructor sets required fields', () {
      final date = DateTime(2026, 3, 26);
      final entry = JournalEntry(date: date);

      expect(entry.date, date);
      expect(entry.id, isNull);
      expect(entry.entry, isNull);
      expect(entry.label, isNull);
      expect(entry.title, isNull);
      expect(entry.userId, isNull);
      expect(entry.createdAt, isNotNull);
    });

    test('createdAt defaults to now when omitted', () {
      final before = DateTime.now();
      final entry = JournalEntry(date: DateTime(2026, 1, 1));
      final after = DateTime.now();

      expect(entry.createdAt.isAfter(before) || entry.createdAt == before, true);
      expect(entry.createdAt.isBefore(after) || entry.createdAt == after, true);
    });

    test('createdAt uses provided value when given', () {
      final custom = DateTime(2025, 6, 15, 10, 30);
      final entry = JournalEntry(date: DateTime(2026, 1, 1), createdAt: custom);
      expect(entry.createdAt, custom);
    });

    group('displayText', () {
      test('returns entry text when set', () {
        final entry = JournalEntry(
          date: DateTime(2026, 1, 1),
          entry: 'Had a great day',
        );
        expect(entry.displayText, 'Had a great day');
      });

      test('returns empty string when entry is null', () {
        final entry = JournalEntry(date: DateTime(2026, 1, 1));
        expect(entry.displayText, '');
      });
    });

    group('isEmpty', () {
      test('returns true when entry is null', () {
        final entry = JournalEntry(date: DateTime(2026, 1, 1));
        expect(entry.isEmpty, true);
      });

      test('returns true when entry is empty string', () {
        final entry = JournalEntry(
          date: DateTime(2026, 1, 1),
          entry: '',
        );
        expect(entry.isEmpty, true);
      });

      test('returns false when entry has content', () {
        final entry = JournalEntry(
          date: DateTime(2026, 1, 1),
          entry: 'content',
        );
        expect(entry.isEmpty, false);
      });
    });

    test('label stores AM/PM/null correctly', () {
      final am = JournalEntry(date: DateTime(2026, 1, 1), entry: 'Morning', label: 'AM');
      expect(am.label, 'AM');

      final pm = JournalEntry(date: DateTime(2026, 1, 1), entry: 'Evening', label: 'PM');
      expect(pm.label, 'PM');

      final allDay = JournalEntry(date: DateTime(2026, 1, 1), entry: 'Full day');
      expect(allDay.label, isNull);
    });

    test('title is nullable and copyWith works', () {
      final entry = JournalEntry(date: DateTime(2026, 1, 1));
      expect(entry.title, isNull);

      final withTitle = entry.copyWith(title: 'My Title');
      expect(withTitle.title, 'My Title');

      final cleared = withTitle.copyWith(title: null);
      expect(cleared.title, isNull);
    });

    test('all fields are settable via copyWith', () {
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
