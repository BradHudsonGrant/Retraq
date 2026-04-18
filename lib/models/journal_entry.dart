import 'package:drift/drift.dart' show QueryRow;

/// Data model for a single journal entry.
/// Plain Dart class — Drift table definition lives in database_service.dart.
class JournalEntry {
  final int? id;

  /// The date this entry is about (not necessarily when it was written)
  final DateTime date;

  /// The entry text content
  final String? entry;

  /// Label: 'AM', 'PM', or null (null = all-day / unlabelled)
  final String? label;

  /// Optional entry title
  final String? title;

  /// Mood rating: 1 (Rough) to 5 (Amazing), or null if not set
  final int? mood;

  /// Timestamp of when the entry was saved
  final DateTime createdAt;

  /// Optional user ID (for future multi-user / family sharing)
  final int? userId;

  JournalEntry({
    this.id,
    required this.date,
    this.entry,
    this.label,
    this.title,
    this.mood,
    this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Task 1.8 — Build a [JournalEntry] from an untyped Drift [QueryRow],
  /// used by paths that issue a `customSelect` (e.g. FTS search) and
  /// therefore cannot use the typed `rowToEntry(JournalEntryRow)` mapper.
  ///
  /// Reads columns by name so adding/reordering columns in the Drift
  /// table definition cannot silently skew the mapping. Normalizes
  /// `date` to the user's local midnight (same as `rowToEntry`) so
  /// search results and list results agree on what day an entry
  /// belongs to.
  factory JournalEntry.fromRawRow(QueryRow row) {
    final dateRaw = row.read<int>('date');
    final createdRaw = row.read<int>('created_at');
    final localDate =
        DateTime.fromMillisecondsSinceEpoch(dateRaw * 1000).toLocal();
    return JournalEntry(
      id: row.read<int>('id'),
      date: DateTime(localDate.year, localDate.month, localDate.day),
      entry: row.readNullable<String>('entry'),
      label: row.readNullable<String>('label'),
      title: row.readNullable<String>('title'),
      mood: row.readNullable<int>('mood'),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(createdRaw * 1000).toLocal(),
      userId: row.readNullable<int>('user_id'),
    );
  }

  /// Convenience: the display text
  static const Object _sentinel = Object();

  JournalEntry copyWith({
    int? id,
    DateTime? date,
    Object? entry = _sentinel,
    Object? label = _sentinel,
    Object? title = _sentinel,
    Object? mood = _sentinel,
    DateTime? createdAt,
    int? userId,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      entry: entry == _sentinel ? this.entry : entry as String?,
      label: label == _sentinel ? this.label : label as String?,
      title: title == _sentinel ? this.title : title as String?,
      mood: mood == _sentinel ? this.mood : mood as int?,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  String get displayText => entry ?? '';

  bool get isEmpty => entry == null || entry!.isEmpty;

  /// Value equality so Drift stream watchers can use `.distinct()` to
  /// suppress re-emissions of identical snapshots. Without this, any
  /// journal_entries mutation re-emits the full list and downstream
  /// setState calls rebuild the whole Recap/Home trees even when the
  /// user-visible data hasn't changed.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry &&
        other.id == id &&
        other.date == date &&
        other.entry == entry &&
        other.label == label &&
        other.title == title &&
        other.mood == mood &&
        other.createdAt == createdAt &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        date,
        entry,
        label,
        title,
        mood,
        createdAt,
        userId,
      );
}
