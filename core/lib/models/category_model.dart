import 'package:equatable/equatable.dart';

import '../enums/category_status.dart';

// Entity - Domain layer (pure Dart, no Firebase/API dependencies)
class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String nameLower;

  /// Optional hi_IN display label managed by the admin.
  final String? nameHi;
  final String? iconUrl;
  final int sortOrder;
  final CategoryStatus status;

  /// Maintained by the `onDesignWrite` Cloud Function — never written by apps.
  final int designCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.nameLower,
    this.nameHi,
    this.iconUrl,
    this.sortOrder = 0,
    this.status = CategoryStatus.active,
    this.designCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isArchived => status == CategoryStatus.archived;

  @override
  List<Object?> get props => [
    id,
    name,
    nameLower,
    nameHi,
    iconUrl,
    sortOrder,
    status,
    designCount,
    createdAt,
    updatedAt,
  ];

  CategoryEntity copyWith({
    String? id,
    String? name,
    String? nameLower,
    String? nameHi,
    String? iconUrl,
    int? sortOrder,
    CategoryStatus? status,
    int? designCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLower: nameLower ?? this.nameLower,
      nameHi: nameHi ?? this.nameHi,
      iconUrl: iconUrl ?? this.iconUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      designCount: designCount ?? this.designCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Model - Data layer (can be converted from Firebase/API)
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.nameLower,
    super.nameHi,
    super.iconUrl,
    super.sortOrder,
    super.status,
    super.designCount,
    required super.createdAt,
    super.updatedAt,
  });

  // Convert from Firebase Firestore JSON
  factory CategoryModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return CategoryModel(
      id: id,
      name: json['name'] as String? ?? '',
      nameLower: json['nameLower'] as String? ?? '',
      nameHi: json['nameHi'] as String?,
      iconUrl: json['iconUrl'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      status: CategoryStatus.fromString(json['status'] as String?),
      designCount: (json['designCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Convert to Firebase Firestore JSON.
  // NOTE: `designCount` is function-maintained — datasources must NOT include
  // it in update payloads (use field-specific update maps on edit).
  Map<String, dynamic> toFirebaseJson() {
    return {
      'name': name,
      'nameLower': nameLower,
      'nameHi': nameHi,
      'iconUrl': iconUrl,
      'sortOrder': sortOrder,
      'status': status.value,
      'designCount': designCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Convert from REST API JSON (future migration)
  factory CategoryModel.fromApiJson(Map<String, dynamic> json) {
    return CategoryModel.fromFirebaseJson(json, json['id'] as String? ?? '');
  }

  // Convert to REST API JSON
  Map<String, dynamic> toApiJson() {
    return {'id': id, ...toFirebaseJson()};
  }

  // Convert entity to model
  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      nameLower: entity.nameLower,
      nameHi: entity.nameHi,
      iconUrl: entity.iconUrl,
      sortOrder: entity.sortOrder,
      status: entity.status,
      designCount: entity.designCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
