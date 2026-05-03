import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../../domain/entities/category.dart';

part 'category_model.g.dart';

const int kCategoryTypeId = 1;

@HiveType(typeId: kCategoryTypeId)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final List<int> salt;

  @HiveField(3)
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.salt,
    required this.createdAt,
  });

  Category toEntity() => Category(
        id: id,
        name: name,
        salt: Uint8List.fromList(salt),
        createdAt: createdAt,
      );

  factory CategoryModel.fromEntity(Category c) => CategoryModel(
        id: c.id,
        name: c.name,
        salt: c.salt.toList(),
        createdAt: c.createdAt,
      );
}
