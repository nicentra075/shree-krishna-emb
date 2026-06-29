import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/enums/app_notification_type.dart';

void main() {
  test('value <-> fromString round trips', () {
    for (final t in AppNotificationType.values) {
      expect(AppNotificationType.fromString(t.value), t);
    }
  });
  test('fromString defaults to broadcast on null/unknown', () {
    expect(AppNotificationType.fromString(null), AppNotificationType.broadcast);
    expect(AppNotificationType.fromString('garbage'), AppNotificationType.broadcast);
  });
  test('wire values are stable strings', () {
    expect(AppNotificationType.newDesign.value, 'newDesign');
    expect(AppNotificationType.purchase.value, 'purchase');
    expect(AppNotificationType.broadcast.value, 'broadcast');
  });
}
