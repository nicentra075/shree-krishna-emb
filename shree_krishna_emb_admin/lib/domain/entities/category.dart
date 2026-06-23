import 'package:equatable/equatable.dart';

/// A category belonging to a collection (flat model: stores `collectionId`).
class CategoryEntity extends Equatable {
  final String id;
  final String collectionId;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final int position;
  final DateTime createdAt;

  const CategoryEntity({
    required this.id,
    required this.collectionId,
    required this.name,
    required this.createdAt,
    this.imageUrl,
    this.isActive = true,
    this.position = 0,
  });

  @override
  List<Object?> get props => [
        id,
        collectionId,
        name,
        imageUrl,
        isActive,
        position,
        createdAt,
      ];
}
