import 'package:equatable/equatable.dart';

/// The downloadable design source files supported by the platform.
const List<String> kDesignFormats = ['DST', 'EMB', 'DHE'];

/// A single downloadable design source file attached to a design, tagged with
/// its [format] (DST | EMB | DHE). The end user downloads these once they own
/// the design. [path] is the Storage path (used for management); it may be
/// empty for an externally-hosted URL.
class DesignFileRef extends Equatable {
  final String format;
  final String name;
  final String url;
  final String path;
  final int sizeBytes;

  const DesignFileRef({
    required this.format,
    required this.name,
    required this.url,
    this.path = '',
    this.sizeBytes = 0,
  });

  factory DesignFileRef.fromMap(Map<String, dynamic> map) => DesignFileRef(
    format: (map['format'] ?? '').toString(),
    name: (map['name'] ?? '').toString(),
    url: (map['url'] ?? '').toString(),
    path: (map['path'] ?? '').toString(),
    sizeBytes: (map['sizeBytes'] is num)
        ? (map['sizeBytes'] as num).toInt()
        : 0,
  );

  Map<String, dynamic> toMap() => {
    'format': format,
    'name': name,
    'url': url,
    'path': path,
    'sizeBytes': sizeBytes,
  };

  @override
  List<Object?> get props => [format, name, url, path, sizeBytes];
}

/// A design product. `finalPrice` is computed on write
/// (`isFree ? 0 : price - discountAmount`). `authorId` is 'platform' for admin
/// uploads; a designer uid in a future phase.
class DesignEntity extends Equatable {
  final String id;
  final String name;
  final String? code;
  final List<String> images;
  final String authorId;
  final String? authorName;
  final String? description;
  final int price;
  final int discountAmount;
  final bool isFree;
  final int finalPrice;
  final String? colorOrNeedleCount;

  /// Legacy single-format string (joined formats). Kept for back-compat with
  /// older readers; new code uses [designFormats].
  final String? designFormat;

  /// The selected design formats (subset of [kDesignFormats]).
  final List<String> designFormats;

  /// The downloadable source files, one (or more) per selected format.
  final List<DesignFileRef> designFiles;
  final int stitchCount;
  final int height;
  final int width;
  final String? collectionId;
  final String? categoryId;
  final String status; // active | pending | rejected | inactive
  final int popularity;
  final DateTime createdAt;

  const DesignEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.code,
    this.images = const [],
    this.authorId = 'platform',
    this.authorName,
    this.description,
    this.price = 0,
    this.discountAmount = 0,
    this.isFree = false,
    this.finalPrice = 0,
    this.colorOrNeedleCount,
    this.designFormat,
    this.designFormats = const [],
    this.designFiles = const [],
    this.stitchCount = 0,
    this.height = 0,
    this.width = 0,
    this.collectionId,
    this.categoryId,
    this.status = 'active',
    this.popularity = 0,
  });

  /// Computes the final price from price/discount/isFree.
  static int computeFinalPrice({
    required bool isFree,
    required int price,
    required int discountAmount,
  }) {
    if (isFree) return 0;
    final result = price - discountAmount;
    return result < 0 ? 0 : result;
  }

  String? get firstImageUrl => images.isNotEmpty ? images.first : null;

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    images,
    authorId,
    authorName,
    description,
    price,
    discountAmount,
    isFree,
    finalPrice,
    colorOrNeedleCount,
    designFormat,
    designFormats,
    designFiles,
    stitchCount,
    height,
    width,
    collectionId,
    categoryId,
    status,
    popularity,
    createdAt,
  ];
}
