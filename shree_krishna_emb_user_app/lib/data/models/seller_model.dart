import 'package:shree_krishna_emb/domain/entities/seller.dart';

class SellerModel extends SellerEntity {
  const SellerModel({
    required super.uid,
    required super.name,
    super.userId,
    super.storeName,
    super.storeImageUrl,
    super.storeDescription,
  });

  factory SellerModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    int? parseUserId(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('${value ?? ''}');
    }

    String? str(dynamic value) {
      if (value == null) return null;
      final s = value.toString();
      return s.isEmpty ? null : s;
    }

    return SellerModel(
      uid: id,
      name: str(json['name']) ?? 'Designer',
      userId: parseUserId(json['userId']),
      storeName: str(json['storeName']),
      storeImageUrl: str(json['storeImageUrl']),
      storeDescription: str(json['storeDescription']),
    );
  }
}
