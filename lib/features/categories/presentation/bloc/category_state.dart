import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';

class CategoryState extends Equatable {
  final List<Category> categories;
  final bool loading;
  final String? error;

  const CategoryState({
    this.categories = const [],
    this.loading = false,
    this.error,
  });

  const CategoryState.initial() : this();

  CategoryState copyWith({
    List<Category>? categories,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [categories, loading, error];
}
