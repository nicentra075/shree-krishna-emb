import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_wishlist_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/wishlist_repository.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistDataSource _dataSource;

  WishlistRepositoryImpl({required WishlistDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, WishlistModel>> load() async {
    try {
      return Right(await _dataSource.getWishlist());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WishlistModel>> save(WishlistModel wishlist) async {
    try {
      await _dataSource.saveWishlist(wishlist);
      return Right(wishlist);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
