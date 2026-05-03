import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<Category?> getById(String id);
  Future<Category> add(String name);
  Future<Category> rename(String id, String newName);
  Future<void> delete(String id);
}
