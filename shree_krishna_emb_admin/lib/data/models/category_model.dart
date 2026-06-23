import 'package:shree_krishna_emb_admin/data/models/catalog_parse.dart';
import 'package:shree_krishna_emb_admin/domain/entities/category.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.collectionId,
    required super.name,
    required super.createdAt,
    super.imageUrl,
    super.isActive,
    super.position,
  });

  factory CategoryModel.fromEntity(CategoryEntity e) => CategoryModel(
        id: e.id,
        collectionId: e.collectionId,
        name: e.name,
        createdAt: e.createdAt,
        imageUrl: e.imageUrl,
        isActive: e.isActive,
        position: e.position,
      );

  factory CategoryModel.fromFirebaseJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: toStringOrNull(json['id']) ?? 'unknown',
      collectionId: toStringOrNull(json['collectionId']) ?? '',
      name: toStringOrNull(json['name']) ?? 'Untitled',
      createdAt: parseTimestamp(json['createdAt']),
      imageUrl: toStringOrNull(json['imageUrl']),
      isActive: toBool(json['isActive'], true),
      position: toInt(json['position']),
    );
  }

  Map<String, dynamic> toFirebaseJson() => {
        'id': id,
        'collectionId': collectionId,
        'name': name,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'position': position,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CategoryModel.fromApiJson(Map<String, dynamic> json) =>
      CategoryModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();
}
