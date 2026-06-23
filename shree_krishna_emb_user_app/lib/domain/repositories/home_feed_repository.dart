import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';

abstract class HomeFeedRepository {
  /// Cache-first; pass [forceRefresh] to bypass the cache (pull-to-refresh).
  Future<Either<Failure, HomeFeed>> load({bool forceRefresh});
}
