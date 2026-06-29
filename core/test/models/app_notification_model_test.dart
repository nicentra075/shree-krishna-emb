import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/enums/app_notification_type.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';

void main() {
  final json = {
    'type': 'newDesign',
    'title': 'New designs',
    'body': '3 added',
    'imageUrl': 'https://x/thumb.jpg',
    'data': {'designId': 'd1', 'route': 'design'},
    'read': false,
    'createdAt': '2026-06-27T10:00:00.000Z',
  };

  test('fromFirebaseJson parses all fields', () {
    final m = AppNotificationModel.fromFirebaseJson(json, 'n1');
    expect(m.id, 'n1');
    expect(m.type, AppNotificationType.newDesign);
    expect(m.read, false);
    expect(m.designId, 'd1');
    expect(m.createdAt.toUtc().hour, 10);
  });

  test('toFirebaseJson omits id and round-trips type', () {
    final m = AppNotificationModel.fromFirebaseJson(json, 'n1');
    final out = m.toFirebaseJson();
    expect(out.containsKey('id'), false);
    expect(out['type'], 'newDesign');
    expect(out['read'], false);
  });

  test('defaults are safe for missing fields', () {
    final m = AppNotificationModel.fromFirebaseJson({}, 'n2');
    expect(m.title, '');
    expect(m.data, isEmpty);
    expect(m.read, false);
    expect(m.type, AppNotificationType.broadcast);
  });
}
