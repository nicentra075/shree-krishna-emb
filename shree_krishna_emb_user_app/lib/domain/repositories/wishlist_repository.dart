import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Contract for the user's favorites (wishlist). Backend-agnostic.
abstract class WishlistRepository {
  Future<Either<Failure, WishlistModel>> load();
  Future<Either<Failure, WishlistModel>> save(WishlistModel wishlist);
}
