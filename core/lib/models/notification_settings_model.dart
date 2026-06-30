import 'package:equatable/equatable.dart';

class NotificationSettingsEntity extends Equatable {
  final bool masterEnabled;
  final bool purchaseAlertsEnabled;
  final bool newDesignAlertsEnabled;
  final List<String> dailySlots;     // ["HH:mm"], <=4
  final String timezone;
  final DateTime? newDesignCursor;
  final Map<String, List<String>> firedSlots; // {"YYYY-MM-DD": ["HH:mm"]}
  final DateTime? updatedAt;
  final String? updatedBy;

  const NotificationSettingsEntity({
    this.masterEnabled = true,
    this.purchaseAlertsEnabled = true,
    this.newDesignAlertsEnabled = true,
    this.dailySlots = const [],
    this.timezone = 'Asia/Kolkata',
    this.newDesignCursor,
    this.firedSlots = const {},
    this.updatedAt,
    this.updatedBy,
  });

  NotificationSettingsEntity copyWith({
    bool? masterEnabled,
    bool? purchaseAlertsEnabled,
    bool? newDesignAlertsEnabled,
    List<String>? dailySlots,
    String? timezone,
    DateTime? newDesignCursor,
    Map<String, List<String>>? firedSlots,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      NotificationSettingsEntity(
        masterEnabled: masterEnabled ?? this.masterEnabled,
        purchaseAlertsEnabled: purchaseAlertsEnabled ?? this.purchaseAlertsEnabled,
        newDesignAlertsEnabled: newDesignAlertsEnabled ?? this.newDesignAlertsEnabled,
        dailySlots: dailySlots ?? this.dailySlots,
        timezone: timezone ?? this.timezone,
        newDesignCursor: newDesignCursor ?? this.newDesignCursor,
        firedSlots: firedSlots ?? this.firedSlots,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  List<Object?> get props => [
        masterEnabled, purchaseAlertsEnabled, newDesignAlertsEnabled,
        dailySlots, timezone, newDesignCursor, firedSlots, updatedAt, updatedBy,
      ];
}

class NotificationSettingsModel extends NotificationSettingsEntity {
  const NotificationSettingsModel({
    super.masterEnabled,
    super.purchaseAlertsEnabled,
    super.newDesignAlertsEnabled,
    super.dailySlots,
    super.timezone,
    super.newDesignCursor,
    super.firedSlots,
    super.updatedAt,
    super.updatedBy,
  });

  factory NotificationSettingsModel.defaults() => const NotificationSettingsModel();

  factory NotificationSettingsModel.fromFirebaseJson(Map<String, dynamic> json) {
    final fired = <String, List<String>>{};
    (json['firedSlots'] as Map?)?.forEach((k, v) {
      fired['$k'] = (v as List?)?.cast<String>() ?? const [];
    });
    return NotificationSettingsModel(
      masterEnabled: json['masterEnabled'] as bool? ?? true,
      purchaseAlertsEnabled: json['purchaseAlertsEnabled'] as bool? ?? true,
      newDesignAlertsEnabled: json['newDesignAlertsEnabled'] as bool? ?? true,
      dailySlots: (json['dailySlots'] as List?)?.cast<String>() ?? const [],
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      newDesignCursor: _ts(json['newDesignCursor']),
      firedSlots: fired,
      updatedAt: _ts(json['updatedAt']),
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirebaseJson() => {
        'masterEnabled': masterEnabled,
        'purchaseAlertsEnabled': purchaseAlertsEnabled,
        'newDesignAlertsEnabled': newDesignAlertsEnabled,
        'dailySlots': dailySlots,
        'timezone': timezone,
        'newDesignCursor': newDesignCursor?.toIso8601String(),
        'firedSlots': firedSlots,
        'updatedAt': updatedAt?.toIso8601String(),
        'updatedBy': updatedBy,
      };

  factory NotificationSettingsModel.fromApiJson(Map<String, dynamic> json) =>
      NotificationSettingsModel.fromFirebaseJson(json);
  Map<String, dynamic> toApiJson() => toFirebaseJson();

  factory NotificationSettingsModel.fromEntity(NotificationSettingsEntity e) =>
      NotificationSettingsModel(
        masterEnabled: e.masterEnabled,
        purchaseAlertsEnabled: e.purchaseAlertsEnabled,
        newDesignAlertsEnabled: e.newDesignAlertsEnabled,
        dailySlots: e.dailySlots,
        timezone: e.timezone,
        newDesignCursor: e.newDesignCursor,
        firedSlots: e.firedSlots,
        updatedAt: e.updatedAt,
        updatedBy: e.updatedBy,
      );

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    try { return (v as dynamic).toDate() as DateTime; } catch (_) { return null; }
  }
}
