import 'package:shree_krishna_emb_admin/data/models/catalog_parse.dart';
import 'package:shree_krishna_emb_admin/domain/entities/design.dart';

class DesignModel extends DesignEntity {
  const DesignModel({
    required super.id,
    required super.name,
    required super.createdAt,
    super.code,
    super.images,
    super.authorId,
    super.authorName,
    super.description,
    super.price,
    super.discountAmount,
    super.isFree,
    super.finalPrice,
    super.colorOrNeedleCount,
    super.designFormat,
    super.designFormats,
    super.designFiles,
    super.stitchCount,
    super.height,
    super.width,
    super.collectionId,
    super.categoryId,
    super.status,
    super.popularity,
  });

  factory DesignModel.fromEntity(DesignEntity e) => DesignModel(
    id: e.id,
    name: e.name,
    createdAt: e.createdAt,
    code: e.code,
    images: e.images,
    authorId: e.authorId,
    authorName: e.authorName,
    description: e.description,
    price: e.price,
    discountAmount: e.discountAmount,
    isFree: e.isFree,
    finalPrice: e.finalPrice,
    colorOrNeedleCount: e.colorOrNeedleCount,
    designFormat: e.designFormat,
    designFormats: e.designFormats,
    designFiles: e.designFiles,
    stitchCount: e.stitchCount,
    height: e.height,
    width: e.width,
    collectionId: e.collectionId,
    categoryId: e.categoryId,
    status: e.status,
    popularity: e.popularity,
  );

  factory DesignModel.fromFirebaseJson(Map<String, dynamic> json) {
    final isFree = toBool(json['isFree']);
    final price = toInt(json['price']);
    final discount = toInt(json['discountAmount']);
    return DesignModel(
      id: toStringOrNull(json['id']) ?? 'unknown',
      name: toStringOrNull(json['name']) ?? 'Untitled',
      createdAt: parseTimestamp(json['createdAt']),
      code: toStringOrNull(json['code']),
      images: toStringList(json['images']),
      authorId: toStringOrNull(json['authorId']) ?? 'platform',
      authorName: toStringOrNull(json['authorName']),
      description: toStringOrNull(json['description']),
      price: price,
      discountAmount: discount,
      isFree: isFree,
      // Prefer the stored value; recompute if absent (older docs).
      finalPrice: json.containsKey('finalPrice')
          ? toInt(json['finalPrice'])
          : DesignEntity.computeFinalPrice(
              isFree: isFree,
              price: price,
              discountAmount: discount,
            ),
      colorOrNeedleCount: toStringOrNull(json['colorOrNeedleCount']),
      designFormat: toStringOrNull(json['designFormat']),
      designFormats: _parseFormats(json),
      designFiles: _parseFiles(json['designFiles']),
      stitchCount: toInt(json['stitchCount']),
      height: toInt(json['height']),
      width: toInt(json['width']),
      collectionId: toStringOrNull(json['collectionId']),
      categoryId: toStringOrNull(json['categoryId']),
      status: toStringOrNull(json['status']) ?? 'active',
      popularity: toInt(json['popularity']),
    );
  }

  Map<String, dynamic> toFirebaseJson() => {
    'id': id,
    'name': name,
    'code': code,
    'images': images,
    'authorId': authorId,
    'authorName': authorName,
    'description': description,
    'price': price,
    'discountAmount': discountAmount,
    'isFree': isFree,
    // Always store the computed final price so queries/clients never recompute.
    'finalPrice': DesignEntity.computeFinalPrice(
      isFree: isFree,
      price: price,
      discountAmount: discountAmount,
    ),
    'colorOrNeedleCount': colorOrNeedleCount,
    // Legacy joined string kept in sync for older readers.
    'designFormat': designFormats.isNotEmpty
        ? designFormats.join(', ')
        : designFormat,
    'designFormats': designFormats,
    'designFiles': designFiles.map((f) => f.toMap()).toList(),
    'stitchCount': stitchCount,
    'height': height,
    'width': width,
    'collectionId': collectionId,
    'categoryId': categoryId,
    'status': status,
    'popularity': popularity,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DesignModel.fromApiJson(Map<String, dynamic> json) =>
      DesignModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();

  /// Prefers the `designFormats` list; falls back to splitting the legacy
  /// `designFormat` string so older docs still surface their formats.
  static List<String> _parseFormats(Map<String, dynamic> json) {
    final list = toStringList(json['designFormats']);
    if (list.isNotEmpty) return list;
    final legacy = toStringOrNull(json['designFormat']);
    if (legacy == null || legacy.trim().isEmpty) return const [];
    return legacy
        .split(RegExp(r'[,/]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<DesignFileRef> _parseFiles(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => DesignFileRef.fromMap(Map<String, dynamic>.from(m)))
        .where((f) => f.url.isNotEmpty)
        .toList();
  }
}
