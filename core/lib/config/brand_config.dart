import 'dart:ui';

/// Single source of brand truth for white-label builds (Phase 1 decision D5).
///
/// A client rebrand should be: a new [BrandConfig] instance + a brand asset
/// folder + a Firebase project — no code edits. Display strings that need
/// translation (the app name shown in UI) still live in each app's locale
/// files; everything else brand-identifying belongs here.
///
/// Install a brand at startup with [BrandConfig.install] BEFORE `runApp`.
/// Reading [BrandConfig.current] always works — it defaults to the
/// Shree Krishna EMB brand.
class BrandConfig {
  /// Untranslated brand name (invoices, PDF headers, logs, store metadata).
  final String appName;

  final String companyName;

  /// Asset paths (declare them in the app's pubspec under assets/brand/).
  final String? logoAsset;
  final String? logoDarkAsset;

  /// Seed colors for the design-system theme.
  final Color primaryColor;
  final Color secondaryColor;

  /// Support & legal endpoints. Empty string = feature hidden in the UI
  /// (e.g. the WhatsApp row only renders when [supportWhatsApp] is set).
  final String supportEmail;
  final String supportWhatsApp;
  final String privacyPolicyUrl;
  final String termsUrl;

  /// Store identities (filled during release engineering).
  final String androidPackageId;
  final String iosBundleId;

  /// Android notification channel id — MUST stay stable per install.
  final String notificationChannelId;

  const BrandConfig({
    required this.appName,
    required this.companyName,
    this.logoAsset,
    this.logoDarkAsset,
    required this.primaryColor,
    required this.secondaryColor,
    this.supportEmail = '',
    this.supportWhatsApp = '',
    this.privacyPolicyUrl = '',
    this.termsUrl = '',
    this.androidPackageId = '',
    this.iosBundleId = '',
    this.notificationChannelId = 'brand_default_channel',
  });

  /// The Shree Krishna EMB house brand — the default for both apps.
  static const BrandConfig shreeKrishnaEmb = BrandConfig(
    appName: 'Shree Krishna Embroidery',
    companyName: 'Shree Krishna Embroidery',
    primaryColor: Color(0xFF8B4513),
    secondaryColor: Color(0xFFFF9933),
    // TODO(owner): real support contacts before store submission (DEC-3).
    supportEmail: '',
    supportWhatsApp: '',
    privacyPolicyUrl: 'https://shree-krishna-emb.web.app/privacy.html',
    termsUrl: 'https://shree-krishna-emb.web.app/terms.html',
    androidPackageId: 'com.nicentra.shree_krishna_emb',
    iosBundleId: 'com.nicentra.shreeKrishnaEmb',
    notificationChannelId: 'ske_default_channel',
  );

  static BrandConfig _current = shreeKrishnaEmb;

  static BrandConfig get current => _current;

  /// Call once in main() before runApp. Later calls override (hot-restart).
  static void install(BrandConfig brand) => _current = brand;
}
