import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository _repository;
  GetCategoriesUseCase(this._repository);

  Future<List<Category>> call() => _repository.getAll();
}
