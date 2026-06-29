enum AppNotificationType {
  newDesign('newDesign'),
  purchase('purchase'),
  broadcast('broadcast');

  const AppNotificationType(this.value);
  final String value;

  static AppNotificationType fromString(String? raw) {
    return AppNotificationType.values.firstWhere(
      (t) => t.value == raw,
      orElse: () => AppNotificationType.broadcast,
    );
  }
}
