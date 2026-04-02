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
}
