import 'package:equatable/equatable.dart';

/// Core domain entity representing one encrypted-file history record.
class EncryptedFile extends Equatable {
  /// Unique identifier (UUID v4).
  final String id;

  /// Original filename, e.g. "vacation.jpg".
  final String originalName;

  /// Absolute path to the saved `.enc` file on device storage.
  final String encryptedPath;

  /// UTC timestamp of when the file was encrypted.
  final DateTime createdAt;

  /// Optional category id (UUID) this file was encrypted under. `null` means
  /// the file was encrypted with a manual/random key — no category linkage.
  final String? categoryId;

  const EncryptedFile({
    required this.id,
    required this.originalName,
    required this.encryptedPath,
    required this.createdAt,
    this.categoryId,
  });

  @override
  List<Object?> get props => [
    id,
    originalName,
    encryptedPath,
    createdAt,
    categoryId,
  ];
}
