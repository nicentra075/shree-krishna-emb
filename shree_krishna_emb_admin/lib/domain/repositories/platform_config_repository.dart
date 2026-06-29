import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_platform_config_datasource.dart';

/// Backend-agnostic contract for the `config/platform` document
/// (fee/gst, payment Test/Live mode, Razorpay publishable keys, seller info).
abstract class PlatformConfigRepository {
  Future<Either<Failure, PlatformConfig>> getConfig();

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
  });

  /// Stores a Razorpay key secret for [mode] ('test' | 'live') securely
  /// (encrypted server-side via Cloud Function).
  Future<Either<Failure, void>> setRazorpaySecret({
    required String mode,
    required String secret,
  });
}
