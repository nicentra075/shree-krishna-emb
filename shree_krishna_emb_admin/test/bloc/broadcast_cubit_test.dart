import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_emb_admin/bloc/notifications/broadcast_cubit.dart';
import 'package:shree_krishna_emb_admin/data/services/broadcast_service.dart';

class _OkSvc implements BroadcastService {
  @override
  Future<int> send(String t, String b) async => 42;
}

class _ErrSvc implements BroadcastService {
  @override
  Future<int> send(String t, String b) async => throw Exception('nope');
}

void main() {
  test('send success exposes recipientCount', () async {
    final c = BroadcastCubit(service: _OkSvc());
    await c.send('Hi', 'There');
    expect(c.state.status, BroadcastStatus.sent);
    expect(c.state.recipientCount, 42);
  });

  test('send failure -> error', () async {
    final c = BroadcastCubit(service: _ErrSvc());
    await c.send('Hi', 'There');
    expect(c.state.status, BroadcastStatus.error);
  });

  test('empty title -> error without calling service', () async {
    final c = BroadcastCubit(service: _OkSvc());
    await c.send('', 'There');
    expect(c.state.status, BroadcastStatus.error);
  });

  test('title over 120 chars -> error without calling service', () async {
    final c = BroadcastCubit(service: _OkSvc());
    await c.send('a' * 121, 'There');
    expect(c.state.status, BroadcastStatus.error);
  });

  test('empty body -> error without calling service', () async {
    final c = BroadcastCubit(service: _OkSvc());
    await c.send('Hi', '');
    expect(c.state.status, BroadcastStatus.error);
  });
}
