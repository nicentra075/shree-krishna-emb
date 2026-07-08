import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_fcm_token_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/fcm_token_repository.dart';

class FcmTokenRepositoryImpl implements FcmTokenRepository {
  final FcmTokenDataSource dataSource;

  FcmTokenRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> register(
    String uid,
    String token,
    String platform,
  ) async {
    try {
      await dataSource.registerToken(uid, token, platform);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> remove(String uid) async {
    try {
      await dataSource.deleteToken(uid);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
