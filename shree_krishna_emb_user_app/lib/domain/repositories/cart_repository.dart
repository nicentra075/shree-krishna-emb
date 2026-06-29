import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Contract for the user's cart. Backend-agnostic.
abstract class CartRepository {
  Future<Either<Failure, CartModel>> load();
  Future<Either<Failure, CartModel>> save(CartModel cart);
}
