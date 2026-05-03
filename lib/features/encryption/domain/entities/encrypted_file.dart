import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'encrypted_file.g.dart';

/// Hive type ID — must be unique across all registered adapters in the app.
const int kEncryptedFileTypeId = 0;

/// Core domain entity representing one encrypted-file history record.
///
/// Annotated with Hive fields so that [EncryptedFileAdapter] (generated via
/// `build_runner`) can persist it directly — no separate DTO needed.
@HiveType(typeId: kEncryptedFileTypeId)
class EncryptedFile extends Equatable {
  /// Unique identifier (UUID v4).
  @HiveField(0)
  final String id;

  /// Original filename, e.g. "vacation.jpg".
  @HiveField(1)
  final String originalName;

  /// Absolute path to the saved `.enc` file on device storage.
  @HiveField(2)
  final String encryptedPath;

  /// Base64-encoded 256-bit AES key used for this file.
  ///
  /// When [categoryId] is non-null, this key was derived from the category's
  /// password + salt via PBKDF2; we still record it so manual recovery is
  /// possible if the category is later deleted.
  @HiveField(3)
  final String secretKey;

  /// UTC timestamp of when the file was encrypted.
  @HiveField(4)
  final DateTime createdAt;

  /// Optional category id (UUID) this file was encrypted under. `null` means
  /// the file was encrypted with a manual/random key — no category linkage.
  @HiveField(5)
  final String? categoryId;

  const EncryptedFile({
    required this.id,
    required this.originalName,
    required this.encryptedPath,
    required this.secretKey,
    required this.createdAt,
    this.categoryId,
  });

  @override
  List<Object?> get props => [
    id,
    originalName,
    encryptedPath,
    secretKey,
    createdAt,
    categoryId,
  ];
}
