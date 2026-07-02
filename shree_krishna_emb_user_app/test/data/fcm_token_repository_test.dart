import 'package:flutter_test/flutter_test.dart';
import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_fcm_token_datasource.dart';
import 'package:shree_krishna_emb/data/repositories/fcm_token_repository_impl.dart';

class _ThrowingDs implements FcmTokenDataSource {
  @override
  Future<void> deleteToken(String uid, String token) async =>
      throw Exception('boom');
  @override
  Future<void> registerToken(String uid, String token, String platform) async =>
      throw Exception('boom');
}

class _OkDs implements FcmTokenDataSource {
  String? lastToken;
  String? deletedToken;
  @override
  Future<void> deleteToken(String uid, String token) async {
    deletedToken = token;
  }

  @override
  Future<void> registerToken(String uid, String token, String platform) async {
    lastToken = token;
  }
}

void main() {
  test('register success returns Right', () async {
    final ds = _OkDs();
    final repo = FcmTokenRepositoryImpl(dataSource: ds);
    final r = await repo.register('u1', 't1', 'android');
    expect(r, isA<Right<Failure, void>>());
    expect(ds.lastToken, 't1');
  });

  test('register failure returns Left(Failure)', () async {
    final repo = FcmTokenRepositoryImpl(dataSource: _ThrowingDs());
    final r = await repo.register('u1', 't1', 'android');
    expect(r, isA<Left<Failure, void>>());
    r.fold((f) => expect(f, isA<Failure>()), (_) => fail('should be Left'));
  });

  test('remove success returns Right', () async {
    final ds = _OkDs();
    final repo = FcmTokenRepositoryImpl(dataSource: ds);
    final r = await repo.remove('u1', 't1');
    expect(r, isA<Right<Failure, void>>());
    expect(ds.deletedToken, 't1');
  });

  test('remove failure returns Left(Failure)', () async {
    final repo = FcmTokenRepositoryImpl(dataSource: _ThrowingDs());
    final r = await repo.remove('u1', 't1');
    expect(r, isA<Left<Failure, void>>());
    r.fold((f) => expect(f, isA<Failure>()), (_) => fail('should be Left'));
  });
}
