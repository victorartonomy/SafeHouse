import 'dart:math';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _local;
  final Uuid _uuid;
  final Random _random;

  CategoryRepositoryImpl({
    required CategoryLocalDataSource local,
    Uuid uuid = const Uuid(),
    Random? random,
  })  : _local = local,
        _uuid = uuid,
        _random = random ?? Random.secure();

  @override
  Future<List<Category>> getAll() async {
    final models = await _local.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Category?> getById(String id) async {
    final model = await _local.getById(id);
    return model?.toEntity();
  }

  @override
  Future<Category> add(String name, {String? defaultPassword}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const StorageFailure('Category name cannot be empty.');
    }

    // Reject duplicates (case-insensitive).
    final existing = await _local.getAll();
    if (existing.any((m) => m.name.toLowerCase() == trimmed.toLowerCase())) {
      throw StorageFailure('A category named "$trimmed" already exists.');
    }

    final salt = _generateSalt(16);
    final model = CategoryModel(
      id: _uuid.v4(),
      name: trimmed,
      salt: salt.toList(),
      createdAt: DateTime.now().toUtc(),
      defaultPassword: defaultPassword?.trim(),
    );
    await _local.save(model);
    return model.toEntity();
  }

  @override
  Future<Category> update(
    String id, {
    String? newName,
    String? defaultPassword,
  }) async {
    final existing = await _local.getById(id);
    if (existing == null) {
      throw const StorageFailure('Category not found.');
    }

    if (newName != null) {
      final trimmed = newName.trim();
      if (trimmed.isEmpty) {
        throw const StorageFailure('Category name cannot be empty.');
      }

      // Check duplicate name (excluding self).
      final all = await _local.getAll();
      if (all.any(
        (m) => m.id != id && m.name.toLowerCase() == trimmed.toLowerCase(),
      )) {
        throw StorageFailure('A category named "$trimmed" already exists.');
      }
      existing.name = trimmed;
    }

    if (defaultPassword != null) {
      existing.defaultPassword = defaultPassword.trim().isEmpty ? null : defaultPassword.trim();
    }

    await _local.save(existing); // re-put preserves salt + id + createdAt
    return existing.toEntity();
  }

  @override
  Future<void> delete(String id) => _local.deleteById(id);

  Uint8List _generateSalt(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }
}
