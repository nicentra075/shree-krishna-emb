import 'package:equatable/equatable.dart';

/// A designer that has been authorised by an admin to appear under
/// "Authorised Design Sellers" on the home screen.
class SellerEntity extends Equatable {
  final String uid;
  final int? userId;
  final String name;
  final String? storeName;
  final String? storeImageUrl;
  final String? storeDescription;

  const SellerEntity({
    required this.uid,
    required this.name,
    this.userId,
    this.storeName,
    this.storeImageUrl,
    this.storeDescription,
  });

  /// Prefer the store name; fall back to the designer's name.
  String get displayName =>
      (storeName != null && storeName!.trim().isNotEmpty) ? storeName! : name;

  @override
  List<Object?> get props => [
    uid,
    userId,
    name,
    storeName,
    storeImageUrl,
    storeDescription,
  ];
}
