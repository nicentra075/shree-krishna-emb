import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
// Core exports its own ServerException/ServerFailure which clash with the
// admin app's; hide them so the admin's local versions are used.
import 'package:shree_krishna_core/shree_krishna_core.dart'
    hide ServerException;
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';

/// The full `config/platform` document as the admin app reads/writes it.
///
/// Wraps the shared [PlatformSettingsModel] (fee/gst/razorpayKeyId/seller/
/// invoice fields) PLUS the admin-only payment-mode fields that are NOT part
/// of the core model:
///   - `paymentTestMode` (bool, default true)
///   - `razorpayKeyIdTest`  (publishable Test key id)
///   - `razorpayKeyIdLive`  (publishable Live key id)
///
/// SECURITY: only the PUBLISHABLE Razorpay key ids live in Firestore. The
/// Razorpay *secrets* stay in Cloud Functions runtime config and are NEVER
/// written here.
class PlatformConfig {
  final PlatformSettingsModel settings;
  final bool paymentTestMode;
  final String razorpayKeyIdTest;
  final String razorpayKeyIdLive;

  /// Whether a Razorpay *secret* has been stored (encrypted, server-side) for
  /// each mode. These are non-sensitive booleans mirrored onto `config/platform`
  /// by the `setRazorpaySecret` function — the secret value itself is never
  /// readable by the client. The UI uses them to show a "saved" state.
  final bool razorpayKeySecretTestSet;
  final bool razorpayKeySecretLiveSet;

  const PlatformConfig({
    required this.settings,
    this.paymentTestMode = true,
    this.razorpayKeyIdTest = '',
    this.razorpayKeyIdLive = '',
    this.razorpayKeySecretTestSet = false,
    this.razorpayKeySecretLiveSet = false,
  });

  /// The publishable key id that is active for the current mode.
  String get activeRazorpayKeyId =>
      paymentTestMode ? razorpayKeyIdTest : razorpayKeyIdLive;

  PlatformConfig copyWith({
    PlatformSettingsModel? settings,
    bool? paymentTestMode,
    String? razorpayKeyIdTest,
    String? razorpayKeyIdLive,
    bool? razorpayKeySecretTestSet,
    bool? razorpayKeySecretLiveSet,
  }) {
    return PlatformConfig(
      settings: settings ?? this.settings,
      paymentTestMode: paymentTestMode ?? this.paymentTestMode,
      razorpayKeyIdTest: razorpayKeyIdTest ?? this.razorpayKeyIdTest,
      razorpayKeyIdLive: razorpayKeyIdLive ?? this.razorpayKeyIdLive,
      razorpayKeySecretTestSet:
          razorpayKeySecretTestSet ?? this.razorpayKeySecretTestSet,
      razorpayKeySecretLiveSet:
          razorpayKeySecretLiveSet ?? this.razorpayKeySecretLiveSet,
    );
  }
}

abstract class PlatformConfigDataSource {
  Future<PlatformConfig> getConfig();

  /// Writes the editable subset of `config/platform`. [updatedBy] is the admin
  /// id/email for audit. Only the fields supported by the UI are merged.
  Future<void> saveConfig({
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

  /// Stores a Razorpay key *secret* for [mode] ('test' | 'live') securely via
  /// the `setRazorpaySecret` Cloud Function (admin-only). The plaintext secret
  /// is encrypted server-side and NEVER written to a client-readable location.
  Future<void> setRazorpaySecret({
    required String mode,
    required String secret,
  });
}

class FirebasePlatformConfigDataSource implements PlatformConfigDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebasePlatformConfigDataSource({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  }) : _firestore = firestore,
       _functions = functions;

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(FirestoreCollections.config)
      .doc(FirestoreCollections.configPlatformDoc);

  @override
  Future<PlatformConfig> getConfig() async {
    try {
      final snap = await _doc.get();
      final data = snap.data() ?? const <String, dynamic>{};
      return PlatformConfig(
        settings: PlatformSettingsModel.fromFirebaseJson(data),
        // Default to Test mode when absent — safest default.
        paymentTestMode: data['paymentTestMode'] as bool? ?? true,
        razorpayKeyIdTest: data['razorpayKeyIdTest'] as String? ?? '',
        razorpayKeyIdLive: data['razorpayKeyIdLive'] as String? ?? '',
        razorpayKeySecretTestSet:
            data['razorpayKeySecretTestSet'] as bool? ?? false,
        razorpayKeySecretLiveSet:
            data['razorpayKeySecretLiveSet'] as bool? ?? false,
      );
    } on FirebaseException catch (e, s) {
      AppLogger.logError('getConfig', error: e, stackTrace: s);
      throw ServerException(
        message: e.message ?? 'Failed to load platform config',
      );
    } catch (e, s) {
      AppLogger.logError('getConfig', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> saveConfig({
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
      final payload = <String, dynamic>{
        'platformFeePercent': platformFeePercent,
        'gstPercent': gstPercent,
        'platformFeeEnabled': platformFeeEnabled,
        'gstEnabled': gstEnabled,
        'paymentTestMode': paymentTestMode,
        'razorpayKeyIdTest': razorpayKeyIdTest,
        'razorpayKeyIdLive': razorpayKeyIdLive,
        // The active publishable key mirrors the selected mode so both apps and
        // functions can read a single `razorpayKeyId` field if they prefer.
        'razorpayKeyId': paymentTestMode
            ? razorpayKeyIdTest
            : razorpayKeyIdLive,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': updatedBy,
      };
      if (supportEmail != null) payload['supportEmail'] = supportEmail;
      if (invoicePrefix != null) payload['invoicePrefix'] = invoicePrefix;
      if (sellerName != null) payload['sellerName'] = sellerName;
      if (sellerAddress != null) payload['sellerAddress'] = sellerAddress;
      if (sellerGstin != null) payload['sellerGstin'] = sellerGstin;

      await _doc.set(payload, SetOptions(merge: true));
    } on FirebaseException catch (e, s) {
      AppLogger.logError('saveConfig', error: e, stackTrace: s);
      throw ServerException(
        message: e.message ?? 'Failed to save platform config',
      );
    } catch (e, s) {
      AppLogger.logError('saveConfig', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> setRazorpaySecret({
    required String mode,
    required String secret,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        CloudFunctionNames.setRazorpaySecret,
      );
      await callable.call<Map<String, dynamic>>({
        'mode': mode,
        'secret': secret,
      });
    } on FirebaseFunctionsException catch (e, s) {
      AppLogger.logError(
        'setRazorpaySecret (${e.code})',
        error: e,
        stackTrace: s,
      );
      throw ServerException(message: _friendlyFunctionsError(e));
    } catch (e, s) {
      AppLogger.logError('setRazorpaySecret', error: e, stackTrace: s);
      throw ServerException(
        message:
            'Could not save the secret key due to an unexpected error. '
            'Please try again.',
      );
    }
  }

  /// Maps a callable-function error to a clear, admin-readable message. Prefers
  /// the server's own message for business errors (it is already human-written);
  /// supplies friendly text for transport/auth codes.
  String _friendlyFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'You appear to be signed out. Please sign in again and retry.';
      case 'permission-denied':
        return e.message ??
            'Your account does not have admin access to save payment keys.';
      case 'invalid-argument':
        return e.message ?? 'The secret key value was invalid.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Could not reach the server. Check your internet connection '
            'and try again.';
      case 'internal':
        return 'The server could not store the secret key. Make sure the '
            'SECRETS_ENCRYPTION_KEY is configured, then try again.';
      default:
        return e.message ?? 'Failed to save the secret key. Please try again.';
    }
  }
}
