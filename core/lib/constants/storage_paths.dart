/// Firebase Storage path builders shared by BOTH apps and mirrored in
/// Cloud Functions. Layout contract: docs/integration/FIRESTORE_SCHEMA.md §3.
///
/// PRIVATE paths (`source/`, `original/`) are never readable by clients —
/// design files are delivered only via the `getDesignDownloadUrl` callable.
class StoragePaths {
  StoragePaths._();

  /// PRIVATE — EMB/DST/pattern source file. Admin write only.
  static String designSource(String designId, String fileName) =>
      'designs/$designId/source/$fileName';

  /// PRIVATE — pristine un-watermarked image. Admin only.
  static String designOriginal(String designId, String fileName) =>
      'designs/$designId/original/$fileName';

  /// PUBLIC — watermarked 1200px preview, written by Cloud Function.
  static String designPreview(String designId) =>
      'designs/$designId/public/preview.jpg';

  /// PUBLIC — 400px thumbnail, written by Cloud Function.
  static String designThumb(String designId) =>
      'designs/$designId/public/thumb.jpg';

  /// PUBLIC — home banner image. Admin write.
  static String banner(String bannerId) => 'banners/$bannerId.jpg';

  /// PUBLIC read — user profile photo. Owner write.
  static String userProfile(String uid) => 'users/$uid/profile.jpg';
}
