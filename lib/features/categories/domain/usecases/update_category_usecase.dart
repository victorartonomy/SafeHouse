import '../entities/category.dart';
import '../repositories/category_repository.dart';

class UpdateCategoryUseCase {
  final CategoryRepository _repository;
  UpdateCategoryUseCase(this._repository);

  Future<Category> call({
    required String id,
    String? newName,
    String? defaultPassword,
  }) =>
      _repository.update(id, newName: newName, defaultPassword: defaultPassword);
}
