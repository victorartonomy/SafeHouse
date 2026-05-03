import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class CategoriesLoadRequested extends CategoryEvent {
  const CategoriesLoadRequested();
}

class CategoryAddRequested extends CategoryEvent {
  final String name;
  const CategoryAddRequested(this.name);
  @override
  List<Object?> get props => [name];
}

class CategoryRenameRequested extends CategoryEvent {
  final String id;
  final String newName;
  const CategoryRenameRequested({required this.id, required this.newName});
  @override
  List<Object?> get props => [id, newName];
}

class CategoryDeleteRequested extends CategoryEvent {
  final String id;
  const CategoryDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}
