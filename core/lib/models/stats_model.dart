import 'package:equatable/equatable.dart';

// Entity - Domain layer.
// The `stats/global` document — maintained ONLY by Cloud Functions via
// FieldValue.increment. Read by the admin dashboard (Hive-cached 5 min).
class GlobalStatsEntity extends Equatable {
  final int totalUsers;
  final int totalDesigners;
  final int totalDesigns;
  final int totalOrders;

  /// Paise.
  final int totalRevenue;

  /// Paise.
  final int totalPlatformFees;
  final int pendingRefunds;
  final DateTime? updatedAt;

  const GlobalStatsEntity({
    this.totalUsers = 0,
    this.totalDesigners = 0,
    this.totalDesigns = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.totalPlatformFees = 0,
    this.pendingRefunds = 0,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    totalUsers,
    totalDesigners,
    totalDesigns,
    totalOrders,
    totalRevenue,
    totalPlatformFees,
    pendingRefunds,
    updatedAt,
  ];
}

// Model - Data layer (read-only for apps)
class GlobalStatsModel extends GlobalStatsEntity {
  const GlobalStatsModel({
    super.totalUsers,
    super.totalDesigners,
    super.totalDesigns,
    super.totalOrders,
    super.totalRevenue,
    super.totalPlatformFees,
    super.pendingRefunds,
    super.updatedAt,
  });

  factory GlobalStatsModel.fromFirebaseJson(Map<String, dynamic> json) {
    return GlobalStatsModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalDesigners: (json['totalDesigners'] as num?)?.toInt() ?? 0,
      totalDesigns: (json['totalDesigns'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
      totalPlatformFees: (json['totalPlatformFees'] as num?)?.toInt() ?? 0,
      pendingRefunds: (json['pendingRefunds'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'totalUsers': totalUsers,
      'totalDesigners': totalDesigners,
      'totalDesigns': totalDesigns,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'totalPlatformFees': totalPlatformFees,
      'pendingRefunds': pendingRefunds,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory GlobalStatsModel.fromApiJson(Map<String, dynamic> json) =>
      GlobalStatsModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();
}

// Entity - Domain layer.
// A `statsDaily/{yyyy-MM-dd}` document — doc id is the date key.
class DailyStatsEntity extends Equatable {
  /// `yyyy-MM-dd` (== doc id).
  final String date;
  final int newUsers;
  final int ordersPaid;

  /// Paise.
  final int revenue;

  /// Paise.
  final int platformFees;

  /// Paise.
  final int gst;
  final int refundsCount;

  /// Paise.
  final int refundsAmount;

  const DailyStatsEntity({
    required this.date,
    this.newUsers = 0,
    this.ordersPaid = 0,
    this.revenue = 0,
    this.platformFees = 0,
    this.gst = 0,
    this.refundsCount = 0,
    this.refundsAmount = 0,
  });

  @override
  List<Object?> get props => [
    date,
    newUsers,
    ordersPaid,
    revenue,
    platformFees,
    gst,
    refundsCount,
    refundsAmount,
  ];
}

// Model - Data layer (read-only for apps)
class DailyStatsModel extends DailyStatsEntity {
  const DailyStatsModel({
    required super.date,
    super.newUsers,
    super.ordersPaid,
    super.revenue,
    super.platformFees,
    super.gst,
    super.refundsCount,
    super.refundsAmount,
  });

  factory DailyStatsModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return DailyStatsModel(
      date: id,
      newUsers: (json['newUsers'] as num?)?.toInt() ?? 0,
      ordersPaid: (json['ordersPaid'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      platformFees: (json['platformFees'] as num?)?.toInt() ?? 0,
      gst: (json['gst'] as num?)?.toInt() ?? 0,
      refundsCount: (json['refundsCount'] as num?)?.toInt() ?? 0,
      refundsAmount: (json['refundsAmount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'date': date,
      'newUsers': newUsers,
      'ordersPaid': ordersPaid,
      'revenue': revenue,
      'platformFees': platformFees,
      'gst': gst,
      'refundsCount': refundsCount,
      'refundsAmount': refundsAmount,
    };
  }

  factory DailyStatsModel.fromApiJson(Map<String, dynamic> json) =>
      DailyStatsModel.fromFirebaseJson(json, json['date'] as String? ?? '');

  Map<String, dynamic> toApiJson() => toFirebaseJson();
}
