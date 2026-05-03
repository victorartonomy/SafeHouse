import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/storage/safe_house_paths.dart';
import '../../domain/entities/encrypted_file.dart';
import '../../domain/repositories/encryption_repository.dart';
import '../datasources/aes_encryption_service.dart';
import '../datasources/encryption_local_datasource.dart';

/// Binds [AesEncryptionService], [EncryptionLocalDataSource], and the
/// device filesystem to fulfil the [EncryptionRepository] contract.
class EncryptionRepositoryImpl implements EncryptionRepository {
  final AesEncryptionService _encryptionService;
  final EncryptionLocalDataSource _localDataSource;
  final Uuid _uuid;

  EncryptionRepositoryImpl({
    required AesEncryptionService encryptionService,
    required EncryptionLocalDataSource localDataSource,
    Uuid uuid = const Uuid(),
  }) : _encryptionService = encryptionService,
       _localDataSource = localDataSource,
       _uuid = uuid;

  // ── Public API ─────────────────────────────────────────────────────────────

  @override
  Future<EncryptedFile> encryptFile({
    required String filePath,
    required String secretKey,
    String? originalFileName,
    String? categoryId,
    Uint8List? salt,
  }) async {
    try {
      // Prefer the caller-supplied name (which carries the MIME-derived
      // extension from PlatformFile.extension) over the bare filesystem path,
      // which may lack an extension on Android content URIs.
      final originalName = originalFileName ?? p.basename(filePath);
      final id = _uuid.v4();

      // Use the *original* name (not the content-URI cache stem) to derive
      // the encrypted output filename, so history and disk agree.
      final originalBase = p.basenameWithoutExtension(originalName);
      final encFilename = _buildOutputFilename(
        prefix: 'enc',
        baseName: originalBase,
        extension: '.enc',
        id: id,
      );
      final outputPath = await resolveSafeHousePath(
        subfolder: 'encrypted files',
        filename: encFilename,
      );

      await _encryptionService.encryptFile(
        inputPath: filePath,
        outputPath: outputPath,
        base64Key: secretKey,
        // Embed the original filename inside the AEAD-protected plaintext
        // so decryption can recover the extension even without history.
        originalFileName: originalName,
        salt: salt,
      );

      final record = EncryptedFile(
        id: id,
        originalName: originalName,
        encryptedPath: outputPath,
        createdAt: DateTime.now().toUtc(),
        categoryId: categoryId,
      );

      await _localDataSource.saveRecord(record);
      return record;
    } on Failure {
      rethrow;
    } catch (e) {
      throw EncryptionFailure('Encryption failed: $e');
    }
  }

  @override
  Future<Uint8List?> extractSalt(String filePath) => _encryptionService.extractSalt(filePath);

  @override
  Future<String> decryptFile({
    required String encryptedFilePath,
    required String secretKey,
  }) async {
    try {
      // Look up the Hive history record as a *fallback* filename source for
      // legacy `.enc` files that were created before we embedded the name in
      // the plaintext header. New files supersede this via the in-payload
      // header returned by the AES service.
      EncryptedFile? historyRecord;
      final allRecords = await _localDataSource.getAllRecords();
      for (final r in allRecords) {
        if (r.encryptedPath == encryptedFilePath ||
            p.basename(r.encryptedPath) == p.basename(encryptedFilePath)) {
          historyRecord = r;
          break;
        }
      }

      String fallbackBaseName;
      String fallbackExtension;
      if (historyRecord != null) {
        fallbackBaseName = p.basenameWithoutExtension(
          historyRecord.originalName,
        );
        fallbackExtension = p.extension(historyRecord.originalName);
      } else {
        var stem = p.basenameWithoutExtension(encryptedFilePath);
        if (stem.startsWith('enc_')) stem = stem.substring(4);
        fallbackBaseName = stem;
        fallbackExtension = '';
      }

      final id = _uuid.v4();

      // Decrypt to a temp path first; we only know the *real* filename
      // after the header is parsed by the service.
      final tempFilename = _buildOutputFilename(
        prefix: 'dec',
        baseName: fallbackBaseName,
        extension: '.tmp',
        id: id,
      );
      final tempPath = await resolveSafeHousePath(
        subfolder: 'decrypted files',
        filename: tempFilename,
      );

      final extractedName = await _encryptionService.decryptFile(
        inputPath: encryptedFilePath,
        outputPath: tempPath,
        base64Key: secretKey,
      );

      // Header-extracted name wins; otherwise fall back to history / stem.
      final String finalBaseName;
      final String finalExtension;
      if (extractedName != null && extractedName.isNotEmpty) {
        finalBaseName = p.basenameWithoutExtension(extractedName);
        finalExtension = p.extension(extractedName);
      } else {
        finalBaseName = fallbackBaseName;
        finalExtension = fallbackExtension;
      }

      final finalFilename = _buildOutputFilename(
        prefix: 'dec',
        baseName: finalBaseName,
        extension: finalExtension,
        id: id,
      );
      final finalPath = await resolveSafeHousePath(
        subfolder: 'decrypted files',
        filename: finalFilename,
      );

      // Rename temp → final (same volume, atomic on Android).
      try {
        await File(tempPath).rename(finalPath);
      } catch (_) {
        // Cross-volume rename fallback.
        final src = File(tempPath);
        await src.copy(finalPath);
        await src.delete();
      }

      return finalPath;
    } on Failure {
      rethrow;
    } catch (e) {
      throw EncryptionFailure('Decryption failed: $e');
    }
  }

  @override
  Future<List<EncryptedFile>> getHistory() => _localDataSource.getAllRecords();

  @override
  Future<void> clearHistory() => _localDataSource.clearAll();

  @override
  Future<void> deleteHistoryEntry(String id) async {
    final records = await _localDataSource.getAllRecords();
    final record = records.firstWhere(
      (entry) => entry.id == id,
      orElse: () => throw StorageFailure('History record not found.'),
    );

    try {
      final file = File(record.encryptedPath);
      if (await file.exists()) {
        await file.delete();
      }

      await _localDataSource.deleteById(id);
    } on Failure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Failed to delete saved file: $e');
    }
  }

  @override
  String generateKey() => _encryptionService.generateKey();

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Builds a collision-free output filename of the form:
  ///
  ///   `{prefix}_{baseName}_{YYYYMMDD_HHmmss}_{uuidPrefix}{extension}`
  ///
  /// Combining a seconds-resolution timestamp *and* a UUID fragment
  /// guarantees uniqueness even on devices with a low-resolution clock and
  /// on rapid batch operations.
  String _buildOutputFilename({
    required String prefix,
    required String baseName,
    required String extension,
    required String id,
  }) {
    final now = DateTime.now();
    final ts =
        '${now.year}'
        '${_two(now.month)}${_two(now.day)}_'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    final shortId = id.replaceAll('-', '').substring(0, 8);
    return '${prefix}_${baseName}_${ts}_$shortId$extension';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
