import 'package:hive/hive.dart';
import '../../domain/entities/encrypted_file.dart';

part 'encrypted_file_model.g.dart';

/// Hive type ID — must be unique across all registered adapters in the app.
const int kEncryptedFileTypeId = 0;

/// Data layer model representing one encrypted-file history record.
///
/// Note: This model does not store the 'secretKey' to enforce security,
/// ensuring derived keys from category passwords are not persisted locally.
@HiveType(typeId: kEncryptedFileTypeId)
class EncryptedFileModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String originalName;

  @HiveField(2)
  final String encryptedPath;

  // Field 3 was 'secretKey'. We intentionally skip it here to drop it during migration.
  // We leave the index skipped to maintain compatibility with existing boxes.

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String? categoryId;

  EncryptedFileModel({
    required this.id,
    required this.originalName,
    required this.encryptedPath,
    required this.createdAt,
    this.categoryId,
  });

  /// Maps the Hive model to the Domain entity.
  EncryptedFile toDomain() {
    return EncryptedFile(
      id: id,
      originalName: originalName,
      encryptedPath: encryptedPath,
      createdAt: createdAt,
      categoryId: categoryId,
    );
  }

  /// Creates a Hive model from the Domain entity.
  factory EncryptedFileModel.fromDomain(EncryptedFile entity) {
    return EncryptedFileModel(
      id: entity.id,
      originalName: entity.originalName,
      encryptedPath: entity.encryptedPath,
      createdAt: entity.createdAt,
      categoryId: entity.categoryId,
    );
  }
}
