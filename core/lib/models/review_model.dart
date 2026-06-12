import 'package:equatable/equatable.dart';

// Entity - Domain layer.
// `designs/{designId}/reviews/{reviewerUid}` — doc id = reviewer uid, so each
// user has exactly one (upsertable) review per design. Creation is gated by
// security rules on the existence of users/{uid}/purchases/{designId}.
class ReviewEntity extends Equatable {
  /// Reviewer uid (== doc id).
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  /// 1–5 (validated by security rules).
  final int rating;

  /// Max 1000 chars (validated by security rules).
  final String comment;
  final String orderId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReviewEntity({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    this.comment = '',
    this.orderId = '',
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    userId,
    userName,
    userPhotoUrl,
    rating,
    comment,
    orderId,
    createdAt,
    updatedAt,
  ];
}

// Model - Data layer
class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.userId,
    required super.userName,
    super.userPhotoUrl,
    required super.rating,
    super.comment,
    super.orderId,
    required super.createdAt,
    super.updatedAt,
  });

  factory ReviewModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return ReviewModel(
      userId: id,
      userName: json['userName'] as String? ?? '',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'orderId': orderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ReviewModel.fromApiJson(Map<String, dynamic> json) =>
      ReviewModel.fromFirebaseJson(json, json['userId'] as String? ?? '');

  Map<String, dynamic> toApiJson() => toFirebaseJson();
}
