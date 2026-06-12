/// Firestore collection/document name constants shared by BOTH apps.
///
/// This is the single source of truth for collection names on the Dart side.
/// Cloud Functions mirror these strings in `functions/src/config/constants.ts`.
/// Full schema contract: docs/integration/FIRESTORE_SCHEMA.md
///
/// NEVER hardcode a collection name in app code — always reference this class.
class FirestoreCollections {
  FirestoreCollections._();

  // Top-level collections
  static const String users = 'users';
  static const String designs = 'designs';
  static const String categories = 'categories';
  static const String orders = 'orders';
  static const String carts = 'carts';
  static const String wishlists = 'wishlists';
  static const String config = 'config';
  static const String stats = 'stats';
  static const String statsDaily = 'statsDaily';
  static const String activity = 'activity';
  static const String adminOtps = 'adminOtps';
  static const String counters = 'counters';

  // Subcollections
  /// `users/{uid}/purchases/{designId}` — written only by Cloud Functions.
  static const String purchases = 'purchases';

  /// `designs/{designId}/reviews/{reviewerUid}` — doc id = reviewer uid.
  static const String reviews = 'reviews';

  // Fixed document ids
  static const String configPlatformDoc = 'platform';
  static const String configHomeFeedDoc = 'homeFeed';
  static const String statsGlobalDoc = 'global';
  static const String countersInvoicesDoc = 'invoices';
}

/// Callable Cloud Function names + deployment region.
///
/// Both apps must construct callables with [region], e.g.
/// `FirebaseFunctions.instanceFor(region: CloudFunctionNames.region)`.
class CloudFunctionNames {
  CloudFunctionNames._();

  static const String region = 'asia-south1';

  static const String createRazorpayOrder = 'createRazorpayOrder';
  static const String verifyRazorpayPayment = 'verifyRazorpayPayment';
  static const String getDesignDownloadUrl = 'getDesignDownloadUrl';
  static const String requestAdminOtp = 'requestAdminOtp';
  static const String verifyAdminOtp = 'verifyAdminOtp';
  static const String initiateRefund = 'initiateRefund';
}
