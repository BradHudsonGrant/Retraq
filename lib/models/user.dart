/// Data model for a user account.
/// Plain Dart class — Drift table definition lives in database_service.dart.
class User {
  final int? id;
  final String? displayName;
  final String? email;
  final DateTime createdAt;

  User({
    this.id,
    this.displayName,
    this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  User copyWith({
    int? id,
    String? displayName,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
