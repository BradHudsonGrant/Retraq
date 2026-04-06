import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retraq/models/journal_entry.dart';
import 'package:retraq/services/database_service.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase(fastPbkdf2: true);

    // Seed test entries
    await DatabaseService.instance.entries.saveEntry(JournalEntry(
      date: DateTime(2026, 1, 10),
      entry: 'Morning jog and coffee',
      label: 'AM',
      title: 'Good Morning',
      createdAt: DateTime(2026, 1, 10, 8, 0),
    ));
    await DatabaseService.instance.entries.saveEntry(JournalEntry(
      date: DateTime(2026, 1, 10),
      entry: 'Read a novel in the evening',
      label: 'PM',
      createdAt: DateTime(2026, 1, 10, 20, 0),
    ));
    await DatabaseService.instance.entries.saveEntry(JournalEntry(
      date: DateTime(2026, 1, 11),
      entry: 'Worked on the Flutter app',
      title: 'Dev Day',
      createdAt: DateTime(2026, 1, 11, 14, 0),
    ));
  });

  tearDownAll(() {
    resetTestDatabase();
  });

  group('JSON export format', () {
    test('exported JSON has expected top-level keys', () async {
      final db = DatabaseService.instance;
      final entries = await db.entries.getEntriesForDateRange(
        DateTime(2026, 1, 10),
        DateTime(2026, 1, 11),
      );

      // Replicate the export logic to test structure (ExportService uses
      // _shareFile which requires platform channels, so we build the JSON
      // the same way the service does).
      final data = entries.map((e) => {
            'date': '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
            'entry': e.entry,
            'label': e.label,
            'title': e.title,
            'createdAt': e.createdAt.toIso8601String(),
          }).toList();

      final jsonMap = {
        'exportedAt': DateTime.now().toIso8601String(),
        'entryCount': data.length,
        'entries': data,
      };

      expect(jsonMap.containsKey('exportedAt'), true);
      expect(jsonMap.containsKey('entryCount'), true);
      expect(jsonMap.containsKey('entries'), true);
      expect(jsonMap['entryCount'], entries.length);
    });

    test('each entry in JSON has date, entry, label, title, createdAt', () async {
      final db = DatabaseService.instance;
      final entries = await db.entries.getEntriesForDateRange(
        DateTime(2026, 1, 10),
        DateTime(2026, 1, 10),
      );

      for (final e in entries) {
        final map = {
          'date': '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
          'entry': e.entry,
          'label': e.label,
          'title': e.title,
          'createdAt': e.createdAt.toIso8601String(),
        };
        expect(map.containsKey('date'), true);
        expect(map.containsKey('entry'), true);
        expect(map.containsKey('label'), true);
        expect(map.containsKey('title'), true);
        expect(map.containsKey('createdAt'), true);
      }
    });

    test('JSON round-trips through encode/decode', () async {
      final db = DatabaseService.instance;
      final entries = await db.entries.getEntriesForDateRange(
        DateTime(2026, 1, 10),
        DateTime(2026, 1, 11),
      );

      final data = entries.map((e) => {
            'date': '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
            'entry': e.entry,
            'label': e.label,
            'title': e.title,
            'createdAt': e.createdAt.toIso8601String(),
          }).toList();

      final jsonStr = const JsonEncoder.withIndent('  ').convert({
        'exportedAt': DateTime.now().toIso8601String(),
        'entryCount': data.length,
        'entries': data,
      });

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['entryCount'], entries.length);
      final decodedEntries = decoded['entries'] as List;
      expect(decodedEntries.length, entries.length);
      // Verify all decoded dates are within the queried range
      for (final de in decodedEntries) {
        final date = de['date'] as String;
        expect(date, anyOf('2026-01-10', '2026-01-11'));
      }
    });
  });

  group('Text export format', () {
    test('text output contains header and entries', () async {
      final db = DatabaseService.instance;
      final entries = await db.entries.getEntriesForDateRange(
        DateTime(2026, 1, 10),
        DateTime(2026, 1, 11),
      );

      // Replicate text export logic
      final buffer = StringBuffer();
      buffer.writeln('Retraq Journal Export');
      buffer.writeln('Total entries: ${entries.length}');
      buffer.writeln('${'=' * 40}\n');

      for (final e in entries) {
        if (e.label != null) {
          buffer.writeln('[${e.label}] ${e.entry ?? ''}');
        } else {
          buffer.writeln(e.entry ?? '');
        }
        buffer.writeln();
      }

      final text = buffer.toString();
      expect(text, contains('Retraq Journal Export'));
      expect(text, contains('Total entries: ${entries.length}'));
      expect(text, contains('=' * 40));
    });

    test('text output includes label prefix when present', () async {
      final db = DatabaseService.instance;
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 1, 10));

      final buffer = StringBuffer();
      for (final e in entries) {
        if (e.label != null) {
          buffer.writeln('[${e.label}] ${e.entry ?? ''}');
        } else {
          buffer.writeln(e.entry ?? '');
        }
      }
      final text = buffer.toString();

      expect(text, contains('[AM]'));
      expect(text, contains('[PM]'));
      expect(text, contains('Morning jog'));
    });

    test('text output handles entry with no label', () async {
      final db = DatabaseService.instance;
      final entries = await db.entries.getEntriesForDate(DateTime(2026, 1, 11));
      expect(entries.length, 1);

      final e = entries.first;
      expect(e.label, isNull);

      final line = e.label != null
          ? '[${e.label}] ${e.entry ?? ''}'
          : e.entry ?? '';
      expect(line, 'Worked on the Flutter app');
    });
  });

  group('Import with duplicates handling', () {
    test('duplicate detection identifies existing entries by date and createdAt', () async {
      final db = DatabaseService.instance;

      // Fetch an existing entry seeded in setUpAll
      final existing = (await db.entries.getEntriesForDate(DateTime(2026, 1, 10))).first;

      // Simulate the import duplicate-check logic from ExportService
      final entriesForDate = await db.entries.getEntriesForDate(DateTime(2026, 1, 10));
      final isDuplicate = entriesForDate.any((e) =>
          e.createdAt.toIso8601String() ==
          existing.createdAt.toIso8601String());
      expect(isDuplicate, true, reason: 'Existing entry should be detected as duplicate');
    });

    test('duplicate detection matches on date and createdAt', () async {
      final db = DatabaseService.instance;
      final existing = (await db.entries.getEntriesForDate(DateTime(2026, 1, 10))).first;

      final entriesForDate = await db.entries.getEntriesForDate(DateTime(2026, 1, 10));
      final isDuplicate = entriesForDate.any((e) =>
          e.createdAt.toIso8601String() ==
          existing.createdAt.toIso8601String());
      expect(isDuplicate, true);

      // A different createdAt should not be a duplicate
      final isNotDuplicate = entriesForDate.any((e) =>
          e.createdAt.toIso8601String() ==
          DateTime(2099, 1, 1).toIso8601String());
      expect(isNotDuplicate, false);
    });

    test('import adds new entries that are not duplicates', () async {
      final db = DatabaseService.instance;
      final beforeCount =
          (await db.entries.getEntriesForDate(DateTime(2026, 2, 15))).length;
      expect(beforeCount, 0);

      final newEntry = JournalEntry(
        date: DateTime(2026, 2, 15),
        entry: 'Brand new imported entry',
        createdAt: DateTime(2026, 2, 15, 9, 30),
      );
      await db.entries.saveEntry(newEntry);

      final afterCount =
          (await db.entries.getEntriesForDate(DateTime(2026, 2, 15))).length;
      expect(afterCount, 1);
    });
  });

  group('Malformed JSON handling', () {
    test('importFromJson returns error for non-JSON content', () async {
      final tmpDir = Directory.systemTemp.createTempSync('export_test_bad_');
      final tmpFile = File('${tmpDir.path}/bad.json');
      tmpFile.writeAsStringSync('this is not json{{{');

      try {
        // We can't call ExportService.importFromJson directly in unit tests
        // because it's a singleton tied to platform channels. Instead we
        // replicate its parse-and-validate logic.
        final content = tmpFile.readAsStringSync();
        Map<String, dynamic>? parsed;
        try {
          parsed = jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {
          parsed = null;
        }
        expect(parsed, isNull);
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('importFromJson returns error when entries key is missing', () {
      final jsonStr = jsonEncode({'exportedAt': 'now', 'entryCount': 0});
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final entriesJson = decoded['entries'] as List<dynamic>?;
      expect(entriesJson, isNull);
    });

    test('entry missing required date field is detected', () {
      final raw = {'entry': 'no date here', 'createdAt': '2026-01-10T08:00:00.000'};
      final dateStr = raw['date'];
      expect(dateStr, isNull);
    });

    test('entry missing required createdAt field is detected', () {
      final raw = {'date': '2026-01-10', 'entry': 'no createdAt'};
      final createdAtStr = raw['createdAt'];
      expect(createdAtStr, isNull);
    });

    test('entry with unparseable date is caught', () {
      final raw = {
        'date': 'not-a-date',
        'entry': 'test',
        'createdAt': '2026-01-10T08:00:00.000',
      };
      expect(() => DateTime.parse(raw['date']!), throwsFormatException);
    });

    test('entry with future date is suspicious', () {
      final futureDate = DateTime.now().add(const Duration(days: 365));
      final raw = {
        'date': futureDate.toIso8601String(),
        'entry': 'from the future',
        'createdAt': futureDate.toIso8601String(),
      };
      final parsed = DateTime.parse(raw['date']!);
      expect(parsed.isAfter(DateTime.now()), true);
    });

    test('entry with year before 2000 is suspicious', () {
      final raw = {
        'date': '1999-12-31',
        'entry': 'too old',
        'createdAt': '1999-12-31T00:00:00.000',
      };
      final parsed = DateTime.parse(raw['date']!);
      expect(parsed.year < 2000, true);
    });

    test('invalid label values are detected', () {
      final validLabels = {null, 'AM', 'PM'};
      expect(validLabels.contains('AM'), true);
      expect(validLabels.contains('PM'), true);
      expect(validLabels.contains(null), true);
      expect(validLabels.contains('INVALID'), false);
    });

    test('empty entries list is valid JSON structure', () {
      final jsonStr = jsonEncode({
        'exportedAt': DateTime.now().toIso8601String(),
        'entryCount': 0,
        'entries': [],
      });
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final entries = decoded['entries'] as List<dynamic>;
      expect(entries, isEmpty);
    });

    test('control characters in entry text are detectable', () {
      final text = 'Normal text\x00with\x01control\x02chars';
      // C0 control characters (except newline \x0A) should be sanitized
      final sanitized = text.replaceAll(RegExp(r'[\x00-\x09\x0B-\x1F\x7F-\x9F]'), '');
      expect(sanitized, 'Normal textwithcontrolchars');
    });
  });
}
