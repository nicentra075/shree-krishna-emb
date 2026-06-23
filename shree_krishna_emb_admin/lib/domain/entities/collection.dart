import 'package:equatable/equatable.dart';

/// A design collection. Owned by 'platform' (admin) today; a designer uid in a
/// future phase (see docs/design_store/PHASE-E-future-designer.md).
class CollectionEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String ownerId;
  final String ownerType; // 'platform' | 'designer'
  final bool isActive;
  final int position;
  final int designCount;
  final DateTime createdAt;

  const CollectionEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.description,
    this.imageUrl,
    this.ownerId = 'platform',
    this.ownerType = 'platform',
    this.isActive = true,
    this.position = 0,
    this.designCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        ownerId,
        ownerType,
        isActive,
        position,
        designCount,
        createdAt,
      ];
}
