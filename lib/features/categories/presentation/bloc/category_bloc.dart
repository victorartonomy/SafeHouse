import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/add_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetCategoriesUseCase _getAll;
  final AddCategoryUseCase _add;
  final UpdateCategoryUseCase _update;
  final DeleteCategoryUseCase _delete;

  CategoryBloc({
    required GetCategoriesUseCase getAll,
    required AddCategoryUseCase add,
    required UpdateCategoryUseCase update,
    required DeleteCategoryUseCase delete,
  })  : _getAll = getAll,
        _add = add,
        _update = update,
        _delete = delete,
        super(const CategoryState.initial()) {
    on<CategoriesLoadRequested>(_onLoad);
    on<CategoryAddRequested>(_onAdd);
    on<CategoryUpdateRequested>(_onUpdate);
    on<CategoryDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
    CategoriesLoadRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final list = await _getAll();
      emit(state.copyWith(categories: list, loading: false));
    } on Failure catch (f) {
      emit(state.copyWith(loading: false, error: f.message));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'Failed to load: $e'));
    }
  }

  Future<void> _onAdd(
    CategoryAddRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(clearError: true));
    try {
      await _add(event.name, defaultPassword: event.defaultPassword);
      add(const CategoriesLoadRequested());
    } on Failure catch (f) {
      emit(state.copyWith(error: f.message));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add: $e'));
    }
  }

  Future<void> _onUpdate(
    CategoryUpdateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(clearError: true));
    try {
      await _update(
        id: event.id,
        newName: event.newName,
        defaultPassword: event.defaultPassword,
      );
      add(const CategoriesLoadRequested());
    } on Failure catch (f) {
      emit(state.copyWith(error: f.message));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update: $e'));
    }
  }

  Future<void> _onDelete(
    CategoryDeleteRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(clearError: true));
    try {
      await _delete(event.id);
      add(const CategoriesLoadRequested());
    } on Failure catch (f) {
      emit(state.copyWith(error: f.message));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete: $e'));
    }
  }
}
