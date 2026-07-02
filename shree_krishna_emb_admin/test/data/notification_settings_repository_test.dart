import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_notification_settings_datasource.dart';
import 'package:shree_krishna_emb_admin/data/repositories/notification_settings_repository_impl.dart';

class _Ds implements NotificationSettingsDataSource {
  bool boom = false;
  NotificationSettingsModel? saved;

  @override
  Future<NotificationSettingsModel> get() async {
    if (boom) throw Exception('x');
    return NotificationSettingsModel.defaults();
  }

  @override
  Future<void> save(NotificationSettingsModel m, String adminUid) async {
    if (boom) throw Exception('x');
    saved = m;
  }
}

void main() {
  test('load success -> Right', () async {
    final repo = NotificationSettingsRepositoryImpl(dataSource: _Ds());
    final result = await repo.load();
    expect(result, isA<Right<Failure, NotificationSettingsModel>>());
  });

  test('load failure -> Left', () async {
    final repo = NotificationSettingsRepositoryImpl(dataSource: _Ds()..boom = true);
    final result = await repo.load();
    expect(result, isA<Left<Failure, NotificationSettingsModel>>());
  });

  test('save success -> Right and persists via dataSource', () async {
    final ds = _Ds();
    final repo = NotificationSettingsRepositoryImpl(dataSource: ds);
    final result = await repo.save(NotificationSettingsModel.defaults(), 'admin1');
    expect(result, isA<Right<Failure, void>>());
    expect(ds.saved, isNotNull);
  });

  test('save failure -> Left', () async {
    final repo = NotificationSettingsRepositoryImpl(dataSource: _Ds()..boom = true);
    final result = await repo.save(NotificationSettingsModel.defaults(), 'admin1');
    expect(result, isA<Left<Failure, void>>());
  });
}
