import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_platform_config_datasource.dart';

/// Contract for reading the platform-wide settings (`config/platform`).
abstract class PlatformConfigRepository {
  Future<Either<Failure, PlatformConfig>> load();
}
