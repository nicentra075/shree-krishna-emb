import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_emb/data/services/notification_service.dart';

void main() {
  test('extracts designId from data', () {
    expect(
      NotificationService.routeTargetFromData({
        'route': 'design',
        'designId': 'd9',
      }),
      'd9',
    );
  });

  test('returns null when no designId', () {
    expect(NotificationService.routeTargetFromData({'route': 'home'}), null);
    expect(NotificationService.routeTargetFromData({}), null);
  });

  test('returns null when designId is empty string', () {
    expect(NotificationService.routeTargetFromData({'designId': ''}), null);
  });
}
