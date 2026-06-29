import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_cart_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final CartDataSource _dataSource;

  CartRepositoryImpl({required CartDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, CartModel>> load() async {
    try {
      return Right(await _dataSource.getCart());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartModel>> save(CartModel cart) async {
    try {
      await _dataSource.saveCart(cart);
      return Right(cart);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
