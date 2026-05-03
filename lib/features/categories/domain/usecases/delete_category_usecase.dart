import '../repositories/category_repository.dart';

class DeleteCategoryUseCase {
  final CategoryRepository _repository;
  DeleteCategoryUseCase(this._repository);

  Future<void> call(String id) => _repository.delete(id);
}
