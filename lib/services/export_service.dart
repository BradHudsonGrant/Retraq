import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/journal_entry.dart';
import '../models/user.dart';
import '../models/user_settings.dart';
import '../utils/date_helpers.dart';
import 'database_service.dart';

// ---------------------------------------------------------------------------
// Top-level functions for compute() — must not be closures or instance methods.
// ---------------------------------------------------------------------------

/// Encode export payload (entries + settings + user) to pretty-printed JSON.
/// Accepts a map with keys: 'entries', 'settings', 'user'.
String _encodeExportPayload(Map<String, dynamic> data) {
  final entryMaps = data['entries'] as List<Map<String, dynamic>>;
  final payload = <String, dynamic>{
    'schemaVersion': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'entryCount': entryMaps.length,
    'entries': entryMaps,
    'settings': data['settings'],
    'user': data['user'],
    if (data['consentRecords'] != null) 'consentRecords': data['consentRecords'],
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

/// Format a list of entry maps into readable plain text.
String _formatEntriesToText(List<Map<String, dynamic>> entryMaps) {
  final readableFmt = DateFormat('EEEE, MMMM d, yyyy');
  final buffer = StringBuffer();
  buffer.writeln('SinceThen Journal Export');
  buffer.writeln('Exported: ${readableFmt.format(DateTime.now())}');
  buffer.writeln('Total entries: ${entryMaps.length}');
  buffer.writeln('${'=' * 40}\n');

  for (final map in entryMaps) {
    final date = DateTime.parse(map['date'] as String);
    buffer.writeln(readableFmt.format(date));
    buffer.writeln('-' * 30);
    final title = map['title'] as String?;
    if (title != null && title.isNotEmpty) {
      buffer.writeln('[Title: $title]');
    }
    final mood = map['mood'] as int?;
    if (mood != null) {
      const moodLabels = ['', 'Rough', 'Low', 'Neutral', 'Good', 'Amazing'];
      buffer.writeln('[Mood: ${moodLabels[mood]}]');
    }
    final label = map['label'] as String?;
    final entry = map['entry'] as String?;
    if (label != null) {
      buffer.writeln('[$label] ${entry ?? ''}');
    } else {
      buffer.writeln(entry ?? '');
    }
    buffer.writeln();
  }

  return buffer.toString();
}

/// Decode a JSON string and parse the entries list into maps.
/// Returns the parsed list, or throws on invalid input.
List<Map<String, dynamic>> _decodeEntriesFromJson(String content) {
  final json = jsonDecode(content) as Map<String, dynamic>;
  final entriesJson = json['entries'] as List<dynamic>?;
  if (entriesJson == null) {
    throw const FormatException('Missing "entries" key in JSON');
  }
  if (entriesJson.length > 500000) {
    throw const FormatException(
        'Too many entries (max 500,000)');
  }
  // Validate that every element is a Map.
  for (var i = 0; i < entriesJson.length; i++) {
    if (entriesJson[i] is! Map<String, dynamic>) {
      throw FormatException('Entry at index $i is not a valid object');
    }
  }
  return entriesJson.cast<Map<String, dynamic>>();
}

/// Strip control characters (except newline \n) from a string.
String _sanitizeText(String input) {
  // Remove all C0/C1 control chars except \n (0x0A).
  return input.replaceAll(RegExp(r'[\x00-\x09\x0B-\x1F\x7F-\x9F]'), '');
}

/// Handles exporting journal entries as JSON or plain text.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  final _entries = DatabaseService.instance.entries;
  final _settingsRepo = DatabaseService.instance.settings;
  final _userRepo = DatabaseService.instance.userRepo;
  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _readableFmt = DateFormat('EEEE, MMMM d, yyyy');

  /// Fetch entries for the given range, or current week by default.
  Future<List<JournalEntry>> _getEntries({DateTime? start, DateTime? end}) async {
    if (start != null && end != null) {
      return _entries.getEntriesForDateRange(start, end);
    }
    // Default: current week based on user's weekStartDay setting.
    final settings = await _settingsRepo.getSettings();
    final weekStart = weekStartDate(
        weekStartDay: settings.weekStartDay);
    final today = DateTime.now();
    return _entries.getEntriesForDateRange(
        weekStart, DateTime(today.year, today.month, today.day));
  }

  /// Convert JournalEntry list to serialisable maps (main isolate, cheap).
  List<Map<String, dynamic>> _entriesToMaps(List<JournalEntry> entries) {
    return entries.map((e) => <String, dynamic>{
      'date': _dateFmt.format(e.date),
      'entry': e.entry,
      'label': e.label,
      'title': e.title,
      'mood': e.mood,
      'createdAt': e.createdAt.toIso8601String(),
    }).toList();
  }

  /// Serialise [UserSettings] to a JSON-safe map (excluding sensitive pinHash).
  Map<String, dynamic> _settingsToMap(UserSettings s) => {
    'themeMode': s.themeMode,
    'isAllDayMode': s.isAllDayMode,
    'askAboutToday': s.askAboutToday,
    'showEntryTitle': s.showEntryTitle,
    'weekStartDay': s.weekStartDay,
    'nudgeHour': s.nudgeHour,
    'nudgeMinute': s.nudgeMinute,
    'appLockEnabled': s.appLockEnabled,
    'biometricEnabled': s.biometricEnabled,
    'enterToSave': s.enterToSave,
    'bulletPointsOnEnter': s.bulletPointsOnEnter,
    'amPmCutoffHour': s.amPmCutoffHour,
    'moodEnabled': s.moodEnabled,
    'moodRequired': s.moodRequired,
    'moodOnlyEntries': s.moodOnlyEntries,
  };

  /// Serialise [User] to a JSON-safe map, or null.
  Map<String, dynamic>? _userToMap(User? u) => u == null
      ? null
      : {
          'displayName': u.displayName,
          'email': u.email,
          'subscriptionTier': u.subscriptionTier,
          'createdAt': u.createdAt.toIso8601String(),
        };

  /// Export entries as a JSON file and open the share sheet.
  /// Defaults to current week. Pass start/end for custom range.
  /// Pass exportAll: true to export everything.
  Future<void> exportAsJson({DateTime? start, DateTime? end, bool exportAll = false}) async {
    try {
      final entries = exportAll
          ? await _entries.getAllEntries()
          : await _getEntries(start: start, end: end);
      final maps = _entriesToMaps(entries);

      // Fetch settings, user, and consent records on the main isolate.
      final settings = await _settingsRepo.getSettings();
      final user = await _userRepo.getUser();
      final consentRecords = await _userRepo.getConsentRecords();

      final exportData = <String, dynamic>{
        'entries': maps,
        'settings': _settingsToMap(settings),
        'user': _userToMap(user),
        'consentRecords': consentRecords
            .map((r) => {
                  'consentType': r.consentType,
                  'documentVersion': r.documentVersion,
                  'acceptedAt': r.acceptedAt.toIso8601String(),
                  'appVersion': r.appVersion,
                })
            .toList(),
      };

      // Heavy JSON encoding runs off the UI thread.
      final jsonStr = await compute(_encodeExportPayload, exportData);

      await _shareFile(jsonStr, 'sincethen_export.json', 'application/json');
    } catch (e, stack) {
      debugPrint('ExportService.exportAsJson failed: $e\n$stack');
      throw Exception('Failed to export journal as JSON: $e');
    }
  }

  /// Export entries as readable plain text and open the share sheet.
  /// Defaults to current week. Pass start/end for custom range.
  /// Pass exportAll: true to export everything.
  Future<void> exportAsText({DateTime? start, DateTime? end, bool exportAll = false}) async {
    try {
      final entries = exportAll
          ? await _entries.getAllEntries()
          : await _getEntries(start: start, end: end);
      final maps = _entriesToMaps(entries);

      // Heavy text formatting runs off the UI thread.
      final text = await compute(_formatEntriesToText, maps);

      await _shareFile(text, 'sincethen_export.txt', 'text/plain');
    } catch (e, stack) {
      debugPrint('ExportService.exportAsText failed: $e\n$stack');
      throw Exception('Failed to export journal as text: $e');
    }
  }

  /// Share a single entry's text via the system share sheet.
  Future<void> shareEntry(JournalEntry entry) async {
    try {
      final dateStr = _readableFmt.format(entry.date);
      final text = 'SinceThen - $dateStr\n\n${entry.displayText}';
      await Share.share(text);
    } catch (e, stack) {
      debugPrint('ExportService.shareEntry failed: $e\n$stack');
      throw Exception('Failed to share entry: $e');
    }
  }

  /// Share all entries for a given day, concatenated.
  Future<void> shareDayEntries(List<JournalEntry> entries, DateTime date) async {
    if (entries.isEmpty) return;
    try {
      final dateStr = _readableFmt.format(date);
      final buffer = StringBuffer('SinceThen - $dateStr\n');
      for (final e in entries) {
        buffer.writeln();
        if (e.label != null) buffer.writeln('[${e.label}]');
        if (e.title != null && e.title!.isNotEmpty) buffer.writeln(e.title);
        buffer.writeln(e.displayText);
      }
      await Share.share(buffer.toString().trimRight());
    } catch (e, stack) {
      debugPrint('ExportService.shareDayEntries failed: $e\n$stack');
      throw Exception('Failed to share day entries: $e');
    }
  }

  /// Import entries from a JSON file matching the export format.
  /// Returns a summary: {imported, skipped, errors}.
  Future<Map<String, int>> importFromJson(String filePath) async {
    int imported = 0;
    int skipped = 0;
    int errors = 0;

    final file = File(filePath);
    final fileSize = await file.length();
    if (fileSize > 50 * 1024 * 1024) {
      throw const FormatException('File too large (max 50MB)');
    }
    final content = await file.readAsString();

    // Heavy JSON decoding runs off the UI thread.
    final List<Map<String, dynamic>> entryMaps;
    try {
      entryMaps = await compute(_decodeEntriesFromJson, content);
    } catch (e, stack) {
      debugPrint('ExportService.importFromJson: invalid JSON format: $e\n$stack');
      return {'imported': 0, 'skipped': 0, 'errors': 1};
    }

    // DB operations must stay on the main isolate.
    // Pre-fetch existing entries grouped by date to avoid O(N) DB calls.
    final entriesToInsert = <JournalEntry>[];
    final existingByDate = <String, List<JournalEntry>>{};

    for (final map in entryMaps) {
      try {
        // --- date validation ---
        final dateStr = map['date'] as String?;
        if (dateStr == null || dateStr.isEmpty) {
          errors++;
          continue;
        }
        final date = DateTime.tryParse(dateStr);
        if (date == null) {
          errors++;
          continue;
        }
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        if (date.year < 2000 ||
            date.isAfter(DateTime(tomorrow.year, tomorrow.month, tomorrow.day))) {
          errors++;
          continue;
        }

        // --- createdAt validation ---
        final createdAtStr = map['createdAt'] as String?;
        if (createdAtStr == null || createdAtStr.isEmpty) {
          errors++;
          continue;
        }
        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt == null) {
          errors++;
          continue;
        }
        if (createdAt.year < 2000 ||
            createdAt.isAfter(DateTime.now().add(const Duration(days: 1)))) {
          errors++;
          continue;
        }

        // --- entry text validation & sanitization ---
        final rawEntry = map['entry'];
        if (rawEntry != null && rawEntry is! String) {
          errors++;
          continue;
        }
        String? entryText = rawEntry as String?;
        if (entryText != null) {
          if (entryText.length > 50000) {
            errors++;
            continue;
          }
          entryText = _sanitizeText(entryText);
        }

        // --- title validation & sanitization ---
        final rawTitle = map['title'];
        if (rawTitle != null && rawTitle is! String) {
          errors++;
          continue;
        }
        String? title = rawTitle as String?;
        if (title != null) {
          if (title.length > 500) {
            errors++;
            continue;
          }
          title = _sanitizeText(title);
        }

        // --- label validation ---
        final rawLabel = map['label'];
        if (rawLabel != null && rawLabel is! String) {
          errors++;
          continue;
        }
        final label = rawLabel as String?;
        if (label != null && label != 'AM' && label != 'PM') {
          errors++;
          continue;
        }

        // --- mood validation ---
        final rawMood = map['mood'];
        int? mood;
        if (rawMood != null) {
          if (rawMood is int && rawMood >= 1 && rawMood <= 5) {
            mood = rawMood;
          } else {
            // Invalid mood value — skip it silently, don't reject the entry
            mood = null;
          }
        }

        // Duplicate check: same date + createdAt.
        // Cache existing entries per date to avoid repeated DB queries.
        if (!existingByDate.containsKey(dateStr)) {
          existingByDate[dateStr] = await _entries.getEntriesForDate(date);
        }
        final existing = existingByDate[dateStr]!;
        final isDuplicate = existing.any(
            (e) => e.createdAt.toIso8601String() == createdAt.toIso8601String());
        if (isDuplicate) {
          skipped++;
          continue;
        }

        final entry = JournalEntry(
          date: date,
          entry: entryText,
          label: label,
          title: title,
          mood: mood,
          createdAt: createdAt,
        );
        entriesToInsert.add(entry);
        // Add to cache so subsequent entries for same date detect duplicates.
        existing.add(entry);
      } catch (e, stack) {
        debugPrint('ExportService.importFromJson: failed to parse entry: $e\n$stack');
        errors++;
      }
    }

    // Batch-insert all valid entries in a single DB transaction.
    if (entriesToInsert.isNotEmpty) {
      try {
        await _entries.batchSaveEntries(entriesToInsert);
        imported = entriesToInsert.length;
      } catch (e, stack) {
        debugPrint('ExportService.importFromJson: batch insert failed: $e\n$stack');
        errors += entriesToInsert.length;
      }
    }

    return {'imported': imported, 'skipped': skipped, 'errors': errors};
  }

  Future<void> _shareFile(String content, String filename, String mimeType) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    try {
      await Share.shareXFiles([XFile(file.path, mimeType: mimeType)]);
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
