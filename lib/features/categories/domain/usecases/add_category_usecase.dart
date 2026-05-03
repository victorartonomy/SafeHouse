import '../entities/category.dart';
import '../repositories/category_repository.dart';

class AddCategoryUseCase {
  final CategoryRepository _repository;
  AddCategoryUseCase(this._repository);

  Future<Category> call(String name, {String? defaultPassword}) =>
      _repository.add(name, defaultPassword: defaultPassword);
}
