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
  final String? defaultPassword;
  const CategoryAddRequested(this.name, {this.defaultPassword});
  @override
  List<Object?> get props => [name, defaultPassword];
}

class CategoryUpdateRequested extends CategoryEvent {
  final String id;
  final String? newName;
  final String? defaultPassword;
  const CategoryUpdateRequested({
    required this.id,
    this.newName,
    this.defaultPassword,
  });
  @override
  List<Object?> get props => [id, newName, defaultPassword];
}

class CategoryDeleteRequested extends CategoryEvent {
  final String id;
  const CategoryDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}
