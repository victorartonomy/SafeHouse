import 'package:hive/hive.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/encrypted_file.dart';

/// Contract for local persistence of [EncryptedFile] history.
abstract class EncryptionLocalDataSource {
  Future<void> saveRecord(EncryptedFile record);
  Future<List<EncryptedFile>> getAllRecords();
  Future<void> clearAll();
  Future<void> deleteById(String id);
}

/// Hive-backed implementation.
///
/// The box is injected so it can be opened (and the adapter registered)
/// in [injection_container.dart] before this class is constructed.
class EncryptionLocalDataSourceImpl implements EncryptionLocalDataSource {
  static const String boxName = 'encrypted_files';

  final Box<EncryptedFile> _box;

  EncryptionLocalDataSourceImpl({required Box<EncryptedFile> box}) : _box = box;

  @override
  Future<void> saveRecord(EncryptedFile record) async {
    try {
      // Keyed by UUID — idempotent put, fast lookup for delete.
      await _box.put(record.id, record);
    } catch (e) {
      throw StorageFailure('Failed to save record: $e');
    }
  }

  @override
  Future<List<EncryptedFile>> getAllRecords() async {
    try {
      final records = _box.values.toList();
      // Newest first.
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (e) {
      throw StorageFailure('Failed to load history: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _box.clear();
    } catch (e) {
      throw StorageFailure('Failed to clear history: $e');
    }
  }

  @override
  Future<void> deleteById(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageFailure('Failed to delete record: $e');
    }
  }
}
