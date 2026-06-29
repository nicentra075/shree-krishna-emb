import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Contract for the user's owned designs (purchases). Backend-agnostic.
abstract class PurchasesRepository {
  Future<Either<Failure, List<PurchaseModel>>> load();
}
