import 'dart:typed_data';
import '../entities/encrypted_file.dart';

/// Abstract contract for encryption operations and history persistence.
///
/// The Data layer supplies the concrete implementation; the Domain layer
/// only ever depends on this interface — never on the impl directly.
abstract class EncryptionRepository {
  /// Encrypts the file at [filePath] using AES-256 with [secretKey].
  ///
  /// Persists the resulting `.enc` file to app storage, saves a record to
  /// the Hive history box, and returns the completed [EncryptedFile] entity.
  ///
  /// Throws a [Failure] subclass on any error.
  /// [originalFileName] may be supplied by the caller when the file-picker
  /// path lacks an extension (common on Android with content URIs).
  /// Falls back to [p.basename(filePath)] when omitted.
  Future<EncryptedFile> encryptFile({
    required String filePath,
    required String secretKey,
    String? originalFileName,
    String? categoryId,
    Uint8List? salt,
  });

  /// Extracts the salt from a file, if any.
  Future<Uint8List?> extractSalt(String filePath);

  /// Decrypts [encryptedFilePath] using [secretKey].
  ///
  /// Writes the recovered plaintext file to app storage and returns its
  /// absolute path.
  ///
  /// Throws a [Failure] subclass on any error.
  Future<String> decryptFile({
    required String encryptedFilePath,
    required String secretKey,
  });

  /// Returns all [EncryptedFile] records from the local Hive history box,
  /// sorted newest-first.
  Future<List<EncryptedFile>> getHistory();

  /// Permanently removes all records from the Hive history box.
  Future<void> clearHistory();

  /// Removes a single history record by [id] and deletes its saved file.
  Future<void> deleteHistoryEntry(String id);

  /// Generates a cryptographically random AES-256 key.
  /// Returns the key as a base64 string ready for display and storage.
  String generateKey();
}
