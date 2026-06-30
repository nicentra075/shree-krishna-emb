import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/models/notification_settings_model.dart';

void main() {
  test('defaults() gives sane values', () {
    final s = NotificationSettingsModel.defaults();
    expect(s.masterEnabled, true);
    expect(s.timezone, 'Asia/Kolkata');
    expect(s.dailySlots, isEmpty);
    expect(s.firedSlots, isEmpty);
  });

  test('round-trips dailySlots + firedSlots', () {
    final s = NotificationSettingsModel.fromFirebaseJson({
      'masterEnabled': true,
      'purchaseAlertsEnabled': false,
      'newDesignAlertsEnabled': true,
      'dailySlots': ['10:00', '18:00'],
      'timezone': 'Asia/Kolkata',
      'firedSlots': {'2026-06-27': ['10:00']},
      'newDesignCursor': '2026-06-27T05:00:00.000Z',
    });
    expect(s.dailySlots, ['10:00', '18:00']);
    expect(s.firedSlots['2026-06-27'], ['10:00']);
    expect(s.purchaseAlertsEnabled, false);
    final out = s.toFirebaseJson();
    expect(out['dailySlots'], ['10:00', '18:00']);
    expect((out['firedSlots'] as Map)['2026-06-27'], ['10:00']);
  });
}
