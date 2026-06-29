import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// The resolved `config/platform` document for the user app.
///
/// Wraps [PlatformSettingsModel] (fee%, gst%, seller info, support email)
/// and adds the runtime fields the model does not expose:
/// [paymentTestMode] and the active Razorpay publishable key for the mode.
class PlatformConfig {
  final PlatformSettingsModel settings;

  /// When true (default) the app uses the demo/test checkout path; when false
  /// it uses the production server-trusted Razorpay path.
  final bool paymentTestMode;

  /// The Razorpay publishable key id matching [paymentTestMode]
  /// (test key in test mode, live key in live mode), falling back to the
  /// generic `razorpayKeyId` when the mode-specific key is absent.
  final String activeRazorpayKeyId;

  const PlatformConfig({
    required this.settings,
    required this.paymentTestMode,
    required this.activeRazorpayKeyId,
  });

  double get platformFeePercent => settings.platformFeePercent;
  double get gstPercent => settings.gstPercent;
}

/// Reads the singleton `config/platform` document. Both apps share this doc;
/// the user app only reads it.
abstract class PlatformConfigDataSource {
  Future<PlatformConfig> getPlatformConfig();
}

class FirebasePlatformConfigDataSource implements PlatformConfigDataSource {
  final FirebaseFirestore _firestore;

  FirebasePlatformConfigDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<PlatformConfig> getPlatformConfig() async {
    try {
      final snap = await _firestore
          .collection(FirestoreCollections.config)
          .doc(FirestoreCollections.configPlatformDoc)
          .get();

      final data = snap.data();
      if (!snap.exists || data == null) {
        // Doc absent → safe defaults (fee 12, gst 18 are applied by the cubit;
        // here we just return an empty model in test mode).
        return const PlatformConfig(
          settings: PlatformSettingsModel(),
          paymentTestMode: true,
          activeRazorpayKeyId: '',
        );
      }

      final settings = PlatformSettingsModel.fromFirebaseJson(data);

      // Fields not exposed by the model — read straight from the raw doc.
      final testMode = data['paymentTestMode'] as bool? ?? true;
      final keyTest = (data['razorpayKeyIdTest'] as String?)?.trim() ?? '';
      final keyLive = (data['razorpayKeyIdLive'] as String?)?.trim() ?? '';
      final fallbackKey = settings.razorpayKeyId.trim();

      final activeKey = testMode
          ? (keyTest.isNotEmpty ? keyTest : fallbackKey)
          : (keyLive.isNotEmpty ? keyLive : fallbackKey);

      return PlatformConfig(
        settings: settings,
        paymentTestMode: testMode,
        activeRazorpayKeyId: activeKey,
      );
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load settings');
    }
  }
}
