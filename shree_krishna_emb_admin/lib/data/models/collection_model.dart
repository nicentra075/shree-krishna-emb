import 'package:shree_krishna_emb_admin/data/models/catalog_parse.dart';
import 'package:shree_krishna_emb_admin/domain/entities/collection.dart';

class CollectionModel extends CollectionEntity {
  const CollectionModel({
    required super.id,
    required super.name,
    required super.createdAt,
    super.description,
    super.imageUrl,
    super.ownerId,
    super.ownerType,
    super.isActive,
    super.position,
    super.designCount,
  });

  factory CollectionModel.fromEntity(CollectionEntity e) => CollectionModel(
    id: e.id,
    name: e.name,
    createdAt: e.createdAt,
    description: e.description,
    imageUrl: e.imageUrl,
    ownerId: e.ownerId,
    ownerType: e.ownerType,
    isActive: e.isActive,
    position: e.position,
    designCount: e.designCount,
  );

  factory CollectionModel.fromFirebaseJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: toStringOrNull(json['id']) ?? 'unknown',
      name: toStringOrNull(json['name']) ?? 'Untitled',
      createdAt: parseTimestamp(json['createdAt']),
      description: toStringOrNull(json['description']),
      imageUrl: toStringOrNull(json['imageUrl']),
      ownerId: toStringOrNull(json['ownerId']) ?? 'platform',
      ownerType: toStringOrNull(json['ownerType']) ?? 'platform',
      isActive: toBool(json['isActive'], true),
      position: toInt(json['position']),
      designCount: toInt(json['designCount']),
    );
  }

  Map<String, dynamic> toFirebaseJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'ownerId': ownerId,
    'ownerType': ownerType,
    'isActive': isActive,
    'position': position,
    'designCount': designCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CollectionModel.fromApiJson(Map<String, dynamic> json) =>
      CollectionModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();
}
