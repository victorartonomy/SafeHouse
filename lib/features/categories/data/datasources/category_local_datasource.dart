import 'package:hive/hive.dart';

import '../../../../core/errors/failures.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getAll();
  Future<CategoryModel?> getById(String id);
  Future<void> save(CategoryModel model);
  Future<void> deleteById(String id);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  static const String boxName = 'categories';

  final Box<CategoryModel> _box;

  CategoryLocalDataSourceImpl({required Box<CategoryModel> box}) : _box = box;

  @override
  Future<List<CategoryModel>> getAll() async {
    try {
      final all = _box.values.toList();
      all.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return all;
    } catch (e) {
      throw StorageFailure('Failed to load categories: $e');
    }
  }

  @override
  Future<CategoryModel?> getById(String id) async {
    try {
      return _box.get(id);
    } catch (e) {
      throw StorageFailure('Failed to read category: $e');
    }
  }

  @override
  Future<void> save(CategoryModel model) async {
    try {
      await _box.put(model.id, model);
    } catch (e) {
      throw StorageFailure('Failed to save category: $e');
    }
  }

  @override
  Future<void> deleteById(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageFailure('Failed to delete category: $e');
    }
  }
}
