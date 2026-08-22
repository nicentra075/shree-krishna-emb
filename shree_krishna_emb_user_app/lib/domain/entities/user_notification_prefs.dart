/// Per-user notification preferences (WS-B4). Stored as a `notificationPrefs`
/// map on `users/{uid}`. All flags default to true.
class UserNotificationPrefs {
  final bool pushEnabled;
  final bool purchaseAlerts;
  final bool newDesignAlerts;
  final bool promotions;

  const UserNotificationPrefs({
    this.pushEnabled = true,
    this.purchaseAlerts = true,
    this.newDesignAlerts = true,
    this.promotions = true,
  });

  factory UserNotificationPrefs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserNotificationPrefs();
    return UserNotificationPrefs(
      pushEnabled: json['pushEnabled'] != false,
      purchaseAlerts: json['purchaseAlerts'] != false,
      newDesignAlerts: json['newDesignAlerts'] != false,
      promotions: json['promotions'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'pushEnabled': pushEnabled,
    'purchaseAlerts': purchaseAlerts,
    'newDesignAlerts': newDesignAlerts,
    'promotions': promotions,
  };

  UserNotificationPrefs copyWith({
    bool? pushEnabled,
    bool? purchaseAlerts,
    bool? newDesignAlerts,
    bool? promotions,
  }) {
    return UserNotificationPrefs(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      purchaseAlerts: purchaseAlerts ?? this.purchaseAlerts,
      newDesignAlerts: newDesignAlerts ?? this.newDesignAlerts,
      promotions: promotions ?? this.promotions,
    );
  }
}
