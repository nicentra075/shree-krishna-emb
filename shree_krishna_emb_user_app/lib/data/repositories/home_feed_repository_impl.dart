import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_home_feed_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/local_home_feed_cache.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';
import 'package:shree_krishna_emb/domain/repositories/home_feed_repository.dart';

class HomeFeedRepositoryImpl implements HomeFeedRepository {
  final HomeFeedDataSource _dataSource;
  final LocalHomeFeedCache _cache;

  HomeFeedRepositoryImpl({
    required HomeFeedDataSource dataSource,
    required LocalHomeFeedCache cache,
  })  : _dataSource = dataSource,
        _cache = cache;

  @override
  Future<Either<Failure, HomeFeed>> load({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.read();
      if (cached != null && cached.sections.isNotEmpty) {
        return Right(cached);
      }
    }
    try {
      final feed = await _dataSource.getHomeFeed();
      await _cache.write(feed);
      return Right(feed);
    } on ServerException catch (e) {
      // Fall back to any cached copy on network error.
      final cached = _cache.read();
      if (cached != null && cached.sections.isNotEmpty) return Right(cached);
      return Left(ServerFailure(e.message));
    } catch (e) {
      final cached = _cache.read();
      if (cached != null && cached.sections.isNotEmpty) return Right(cached);
      return Left(UnknownFailure(e.toString()));
    }
  }
}
