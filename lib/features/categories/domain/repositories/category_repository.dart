import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<Category?> getById(String id);
  Future<Category> add(String name, {String? defaultPassword});
  Future<Category> update(String id, {String? newName, String? defaultPassword});
  Future<void> delete(String id);
}
