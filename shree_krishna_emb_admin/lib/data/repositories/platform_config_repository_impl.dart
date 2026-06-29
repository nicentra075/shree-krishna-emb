import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_platform_config_datasource.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/platform_config_repository.dart';

class PlatformConfigRepositoryImpl implements PlatformConfigRepository {
  final PlatformConfigDataSource _dataSource;

  PlatformConfigRepositoryImpl({required PlatformConfigDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, PlatformConfig>> getConfig() async {
    try {
      return Right(await _dataSource.getConfig());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveConfig({
    required double platformFeePercent,
    required double gstPercent,
    required bool paymentTestMode,
    required bool platformFeeEnabled,
    required bool gstEnabled,
    required String razorpayKeyIdTest,
    required String razorpayKeyIdLive,
    String? supportEmail,
    String? invoicePrefix,
    String? sellerName,
    String? sellerAddress,
    String? sellerGstin,
    required String updatedBy,
  }) async {
    try {
      await _dataSource.saveConfig(
        platformFeePercent: platformFeePercent,
        gstPercent: gstPercent,
        paymentTestMode: paymentTestMode,
        platformFeeEnabled: platformFeeEnabled,
        gstEnabled: gstEnabled,
        razorpayKeyIdTest: razorpayKeyIdTest,
        razorpayKeyIdLive: razorpayKeyIdLive,
        supportEmail: supportEmail,
        invoicePrefix: invoicePrefix,
        sellerName: sellerName,
        sellerAddress: sellerAddress,
        sellerGstin: sellerGstin,
        updatedBy: updatedBy,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setRazorpaySecret({
    required String mode,
    required String secret,
  }) async {
    try {
      await _dataSource.setRazorpaySecret(mode: mode, secret: secret);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
