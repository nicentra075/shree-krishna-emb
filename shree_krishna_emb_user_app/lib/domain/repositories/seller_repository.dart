import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/domain/entities/seller.dart';

abstract class SellerRepository {
  Future<Either<Failure, List<SellerEntity>>> getAuthorisedSellers({int limit});
}
