import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/models/home_feed_config_model.dart';

abstract class HomeConfigRepository {
  Future<Either<Failure, HomeFeedConfig>> read();
  Future<Either<Failure, void>> save(HomeFeedConfig config);
}
