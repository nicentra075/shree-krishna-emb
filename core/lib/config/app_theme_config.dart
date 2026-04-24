import 'package:equatable/equatable.dart';

/// Theme configuration model that can be used locally or fetched from Firestore
///
/// This model holds all visual theme tokens (colors, fonts, spacing, radii)
/// as pure Dart data (no Flutter imports). Colors are stored as int (hex values)
/// to avoid Flutter dependencies in the core package.
///
/// The design_system package converts these int values to Flutter Color objects
/// when building widgets. This allows admin panel to push theme changes via
/// Firestore with complete type safety.
///
/// Usage:
/// ```dart
/// // Local default theme
/// final config = AppThemeConfig();
///
/// // Custom override
/// final customConfig = AppThemeConfig(
///   primaryDarkColor: 0xFF00AA00,
/// );
///
/// // From Firestore admin panel
/// final remoteConfig = AppThemeConfig.fromFirestoreJson(firestoreDoc);
/// ```
class AppThemeConfig extends Equatable {
  // ==== Colors (stored as int hex values, not Color) ====

  /// Primary color - dark variant (Royal Saffron Dark)
  /// Default: 0xFF8f4e00 (#8f4e00)
  final int primaryDarkColor;

  /// Primary color - light variant (Royal Saffron Light)
  /// Default: 0xFFff9933 (#ff9933)
  final int primaryLightColor;

  /// Secondary color - dark variant (Deep Blue Dark)
  /// Default: 0xFF4059aa (#4059aa)
  final int secondaryDarkColor;

  /// Secondary color - light variant (Deep Blue Light)
  /// Default: 0xFF8fa7fe (#8fa7fe)
  final int secondaryLightColor;

  // ==== Typography ====

  /// Font family for headlines (display, headline styles)
  /// Default: 'Plus Jakarta Sans'
  final String headlineFontFamily;

  /// Font family for body text and labels
  /// Default: 'Manrope'
  final String bodyFontFamily;

  // ==== Border Radius ====

  /// Border radius for primary buttons (pill-shaped)
  /// Default: 9999.0
  final double buttonBorderRadius;

  /// Border radius for cards and containers
  /// Default: 16.0
  final double cardBorderRadius;

  /// Border radius for input fields
  /// Default: 8.0
  final double inputBorderRadius;

  /// Border radius for bottom sheets
  /// Default: 24.0
  final double bottomSheetBorderRadius;

  // ==== Spacing/Padding ====

  /// Vertical padding for buttons
  /// Default: 12.0
  final double buttonVerticalPadding;

  /// Horizontal padding for buttons
  /// Default: 24.0
  final double buttonHorizontalPadding;

  // ==== Remote Config Tracking ====

  /// Version identifier for remote config (null = local config)
  /// Set when fetched from Firestore admin panel
  final String? sourceVersion;

  /// Timestamp when this config was fetched from remote (null = local config)
  final DateTime? fetchedAt;

  const AppThemeConfig({
    this.primaryDarkColor = 0xFF8f4e00,
    this.primaryLightColor = 0xFFff9933,
    this.secondaryDarkColor = 0xFF4059aa,
    this.secondaryLightColor = 0xFF8fa7fe,
    this.headlineFontFamily = 'Plus Jakarta Sans',
    this.bodyFontFamily = 'Manrope',
    this.buttonBorderRadius = 9999.0,
    this.cardBorderRadius = 16.0,
    this.inputBorderRadius = 8.0,
    this.bottomSheetBorderRadius = 24.0,
    this.buttonVerticalPadding = 12.0,
    this.buttonHorizontalPadding = 24.0,
    this.sourceVersion,
    this.fetchedAt,
  });

  /// Create a copy of this config with optional field overrides
  AppThemeConfig copyWith({
    int? primaryDarkColor,
    int? primaryLightColor,
    int? secondaryDarkColor,
    int? secondaryLightColor,
    String? headlineFontFamily,
    String? bodyFontFamily,
    double? buttonBorderRadius,
    double? cardBorderRadius,
    double? inputBorderRadius,
    double? bottomSheetBorderRadius,
    double? buttonVerticalPadding,
    double? buttonHorizontalPadding,
    String? sourceVersion,
    DateTime? fetchedAt,
  }) {
    return AppThemeConfig(
      primaryDarkColor: primaryDarkColor ?? this.primaryDarkColor,
      primaryLightColor: primaryLightColor ?? this.primaryLightColor,
      secondaryDarkColor: secondaryDarkColor ?? this.secondaryDarkColor,
      secondaryLightColor: secondaryLightColor ?? this.secondaryLightColor,
      headlineFontFamily: headlineFontFamily ?? this.headlineFontFamily,
      bodyFontFamily: bodyFontFamily ?? this.bodyFontFamily,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      inputBorderRadius: inputBorderRadius ?? this.inputBorderRadius,
      bottomSheetBorderRadius:
          bottomSheetBorderRadius ?? this.bottomSheetBorderRadius,
      buttonVerticalPadding:
          buttonVerticalPadding ?? this.buttonVerticalPadding,
      buttonHorizontalPadding:
          buttonHorizontalPadding ?? this.buttonHorizontalPadding,
      sourceVersion: sourceVersion ?? this.sourceVersion,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  /// Parse theme config from Firestore JSON document
  /// Used when admin panel pushes remote theme config
  factory AppThemeConfig.fromFirestoreJson(Map<String, dynamic> json) {
    return AppThemeConfig(
      primaryDarkColor:
          json['primaryDarkColor'] as int? ?? 0xFF8f4e00,
      primaryLightColor:
          json['primaryLightColor'] as int? ?? 0xFFff9933,
      secondaryDarkColor:
          json['secondaryDarkColor'] as int? ?? 0xFF4059aa,
      secondaryLightColor:
          json['secondaryLightColor'] as int? ?? 0xFF8fa7fe,
      headlineFontFamily:
          json['headlineFontFamily'] as String? ?? 'Plus Jakarta Sans',
      bodyFontFamily: json['bodyFontFamily'] as String? ?? 'Manrope',
      buttonBorderRadius:
          (json['buttonBorderRadius'] as num?)?.toDouble() ?? 9999.0,
      cardBorderRadius:
          (json['cardBorderRadius'] as num?)?.toDouble() ?? 16.0,
      inputBorderRadius:
          (json['inputBorderRadius'] as num?)?.toDouble() ?? 8.0,
      bottomSheetBorderRadius:
          (json['bottomSheetBorderRadius'] as num?)?.toDouble() ?? 24.0,
      buttonVerticalPadding:
          (json['buttonVerticalPadding'] as num?)?.toDouble() ?? 12.0,
      buttonHorizontalPadding:
          (json['buttonHorizontalPadding'] as num?)?.toDouble() ?? 24.0,
      sourceVersion: json['sourceVersion'] as String?,
      fetchedAt: json['fetchedAt'] != null
          ? DateTime.parse(json['fetchedAt'] as String)
          : null,
    );
  }

  /// Serialize to Firestore JSON format
  /// Used by admin panel to save theme changes
  Map<String, dynamic> toFirestoreJson() {
    return {
      'primaryDarkColor': primaryDarkColor,
      'primaryLightColor': primaryLightColor,
      'secondaryDarkColor': secondaryDarkColor,
      'secondaryLightColor': secondaryLightColor,
      'headlineFontFamily': headlineFontFamily,
      'bodyFontFamily': bodyFontFamily,
      'buttonBorderRadius': buttonBorderRadius,
      'cardBorderRadius': cardBorderRadius,
      'inputBorderRadius': inputBorderRadius,
      'bottomSheetBorderRadius': bottomSheetBorderRadius,
      'buttonVerticalPadding': buttonVerticalPadding,
      'buttonHorizontalPadding': buttonHorizontalPadding,
      'sourceVersion': sourceVersion,
      'fetchedAt': fetchedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        primaryDarkColor,
        primaryLightColor,
        secondaryDarkColor,
        secondaryLightColor,
        headlineFontFamily,
        bodyFontFamily,
        buttonBorderRadius,
        cardBorderRadius,
        inputBorderRadius,
        bottomSheetBorderRadius,
        buttonVerticalPadding,
        buttonHorizontalPadding,
        sourceVersion,
        fetchedAt,
      ];
}
