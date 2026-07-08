import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/utils/either.dart';

/// Contract for registering/removing the current device's FCM push token.
/// Backend-agnostic.
abstract class FcmTokenRepository {
  Future<Either<Failure, void>> register(String uid, String token, String platform);
  Future<Either<Failure, void>> remove(String uid);
}
