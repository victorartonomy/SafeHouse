import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// User-defined category that groups encrypted files under a shared password.
///
/// **No password stored.** PBKDF2 derives the AES key on demand from the
/// user-entered password and the [salt] persisted here.
class Category extends Equatable {
  /// UUID v4.
  final String id;

  /// User-visible name, e.g. "Personal", "Work", "Bank".
  final String name;

  /// 16-byte cryptographically random salt, generated once at create time.
  /// Persisted alongside the category so the same password always derives
  /// the same AES key.
  final Uint8List salt;

  /// Optional default password for this category.
  final String? defaultPassword;

  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.salt,
    this.defaultPassword,
    required this.createdAt,
  });

  Category copyWith({
    String? name,
    String? defaultPassword,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        salt: salt,
        defaultPassword: defaultPassword ?? this.defaultPassword,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, salt, defaultPassword, createdAt];
}
