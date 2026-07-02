import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/bloc/settings/notification_settings_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/settings/notification_settings_state.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/notification_settings_repository.dart';

class _Repo implements NotificationSettingsRepository {
  bool boomOnSave = false;

  @override
  Future<Either<Failure, NotificationSettingsModel>> load() async =>
      Right(NotificationSettingsModel.defaults());

  @override
  Future<Either<Failure, void>> save(
    NotificationSettingsModel s,
    String adminUid,
  ) async {
    if (boomOnSave) return const Left(ServerFailure('nope'));
    return const Right(null);
  }
}

void main() {
  test('load() populates settings and status ready', () async {
    final c = NotificationSettingsCubit(repository: _Repo());
    await c.load();
    expect(c.state.status, NotifSettingsStatus.ready);
    expect(c.state.settings, NotificationSettingsModel.defaults());
  });

  test('addSlot caps at 4 and dedupes + sorts', () async {
    final c = NotificationSettingsCubit(repository: _Repo());
    await c.load();
    c.addSlot('18:00');
    c.addSlot('10:00');
    c.addSlot('10:00'); // dup ignored
    c.addSlot('14:00');
    c.addSlot('21:00');
    c.addSlot('23:00'); // 5th rejected
    expect(c.state.settings.dailySlots, ['10:00', '14:00', '18:00', '21:00']);
  });

  test('removeSlot removes a slot', () async {
    final c = NotificationSettingsCubit(repository: _Repo());
    await c.load();
    c.addSlot('10:00');
    c.addSlot('18:00');
    c.removeSlot('10:00');
    expect(c.state.settings.dailySlots, ['18:00']);
  });

  test('toggles flip corresponding flags', () async {
    final c = NotificationSettingsCubit(repository: _Repo());
    await c.load();
    c.toggleMaster(false);
    c.togglePurchase(false);
    c.toggleNewDesign(false);
    expect(c.state.settings.masterEnabled, false);
    expect(c.state.settings.purchaseAlertsEnabled, false);
    expect(c.state.settings.newDesignAlertsEnabled, false);
  });

  test('save success -> saved status', () async {
    final c = NotificationSettingsCubit(repository: _Repo());
    await c.load();
    await c.save('admin1');
    expect(c.state.status, NotifSettingsStatus.saved);
  });

  test('save failure -> error status with message', () async {
    final c = NotificationSettingsCubit(repository: _Repo()..boomOnSave = true);
    await c.load();
    await c.save('admin1');
    expect(c.state.status, NotifSettingsStatus.error);
    expect(c.state.error, 'nope');
  });
}
