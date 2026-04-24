# Design System Usage Guide

This guide explains how to use the shared design system components in both the User App and Admin App.

---

## Overview

The design system (`design_system/` package) provides:
- **15+ reusable UI components** with consistent theming
- **Tokens** for colors, typography, and spacing
- **Centralized config** for easy brand color/font updates
- **Shared across both apps** — User App and Admin App

---

## 1. Basic Setup

### Import the Design System
```dart
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
```

### Access Theme Configuration
```dart
import 'package:shree_krishna_core/shree_krishna_core.dart';

// Use default theme
const defaultTheme = AppThemeConfig();

// Or custom theme
final customTheme = AppThemeConfig(
  primaryDarkColor: 0xFF00AA00,
  buttonBorderRadius: 12.0,
);
```

---

## 2. Colors (DesignSystemTheme)

Convert `AppThemeConfig` int colors to Flutter `Color` objects:

```dart
import 'package:shree_krishna_design_system/src/theme/design_system_theme.dart';

// Use in widgets
Container(
  color: DesignSystemTheme.primaryDark(themeConfig),
  child: Text(
    'Styled text',
    style: TextStyle(
      color: DesignSystemTheme.primaryLight(themeConfig),
    ),
  ),
);
```

**Available Colors:**
- `primaryDark()` — Main brand color (dark variant)
- `primaryLight()` — Main brand color (light variant)
- `secondaryDark()` — Secondary color (dark variant)
- `secondaryLight()` — Secondary color (light variant)
- `surfaceDark()` — Background for dark mode
- `surfaceLight()` — Background for light mode
- `backgroundDark()` / `backgroundLight()`
- `errorColor()` — For error states
- `successColor()` — For success states
- `warningColor()` — For warnings
- `infoColor()` — For information

---

## 3. Typography (AppTextStyles)

Get themed `TextStyle` objects:

```dart
import 'package:shree_krishna_design_system/src/tokens/app_text_styles.dart';

Text(
  'Headline Text',
  style: AppTextStyles.headline(context, config: themeConfig),
)

// Available styles:
// - displayLarge(context, {config})
// - displayMedium(context, {config})
// - headline(context, {config})
// - body(context, {config})
// - bodySmall(context, {config})
// - label(context, {config})
// - button(context, {config})
```

---

## 4. Border Radius (AppBorderRadius)

Static constants matching theme config:

```dart
import 'package:shree_krishna_design_system/src/tokens/app_border_radius.dart';

Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppBorderRadius.pill),
  ),
)

// Available:
// - xs = 4.0
// - sm = 8.0
// - md = 12.0
// - lg = 16.0
// - xl = 24.0
// - pill = 9999.0
```

---

## 5. Buttons (AppButton)

Primary button with variants:

```dart
AppButton(
  label: 'Continue',
  onPressed: () { },
  variant: AppButtonVariant.primary,  // primary | secondary | outlined | ghost | destructive
  size: AppButtonSize.medium,         // small | medium | large
  leadingIcon: Icons.arrow_forward,
  isLoading: false,
  themeConfig: appThemeConfig,
)
```

**Variants:**
- `primary` — Filled with primary color (default)
- `secondary` — Filled with secondary color
- `outlined` — Border only, transparent fill
- `ghost` — Text only, no border/fill
- `destructive` — Red button for delete/cancel actions

**Sizes:**
- `small` — Compact for secondary actions
- `medium` — Standard size
- `large` — Full-width or prominent actions

---

## 6. Text Input (AppTextField)

Themed text field with validation:

```dart
AppTextField(
  label: 'Email',
  hint: 'user@example.com',
  keyboardType: TextInputType.emailAddress,
  controller: emailController,
  validator: AppValidators.email,
  prefixIcon: Icons.email,
  themeConfig: appThemeConfig,
  onChanged: (value) { },
)
```

---

## 7. Dialogs (AppDialog)

Pre-built dialog helpers:

```dart
// Confirmation dialog
final result = await AppDialog.showConfirm(
  context,
  title: 'Confirm Action',
  message: 'Are you sure?',
  confirmLabel: 'Yes',
  cancelLabel: 'No',
  themeConfig: appThemeConfig,
);
// Returns true if confirmed, false if cancelled, null if dismissed

// Delete confirmation (pre-built)
await AppDialog.showDeleteConfirm(
  context,
  itemName: 'Product',
  themeConfig: appThemeConfig,
);

// Info dialog
await AppDialog.showInfo(
  context,
  title: 'Success',
  message: 'Item created successfully',
  dismissLabel: 'OK',
);
```

---

## 8. Loaders (AppLoader & Shimmer)

### Circular Loader
```dart
AppLoader.circular(
  color: DesignSystemTheme.primaryDark(themeConfig),
  size: 40.0,
  themeConfig: themeConfig,
)
```

### Shimmer (Skeleton Loading)
```dart
AppShimmer(
  child: Column(
    children: [
      Container(height: 72, color: Colors.grey.shade300),
      SizedBox(height: 8),
      Container(height: 72, color: Colors.grey.shade300),
    ],
  ),
  enabled: isLoading,  // Show skeleton while loading
  themeConfig: themeConfig,
)
```

### List Skeleton (Ready-made)
```dart
AppShimmerListSkeleton(
  itemCount: 6,
  itemHeight: 72.0,
  padding: EdgeInsets.all(16),
  themeConfig: themeConfig,
)
```

---

## 9. Empty States (AppEmptyState)

Animated empty state widget:

```dart
AppEmptyState(
  message: 'No products found',
  subtitle: 'Try adjusting your search',
  icon: Icons.inbox_outlined,
  onAction: () { /* Refresh */ },
  actionLabel: 'Refresh',
  themeConfig: themeConfig,
)
```

---

## 10. Snackbars (AppSnackbar)

Themed toast messages:

```dart
// Success
AppSnackbar.showSuccess(context, 'Profile updated successfully');

// Error
AppSnackbar.showError(context, 'Failed to upload image');

// Info
AppSnackbar.showInfo(context, 'Check your email for confirmation');

// Warning
AppSnackbar.showWarning(context, 'Unsaved changes will be lost');
```

---

## 11. Image Picker (AppImagePicker)

Select images from gallery or camera:

```dart
// From gallery
final image = await AppImagePicker.fromGallery(
  imageQuality: 85,
  maxWidth: 1200,
  maxHeight: 1200,
);

// From camera
final photo = await AppImagePicker.fromCamera(imageQuality: 85);

// Show picker sheet (gallery + camera options)
final selected = await AppImagePicker.showPickerSheet(
  context,
  themeConfig: themeConfig,
);
```

---

## 12. Bottom Sheet (AppBottomSheet)

Themed modal bottom sheet:

```dart
await AppBottomSheet.show<String>(
  context,
  title: 'Choose Option',
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        title: Text('Option 1'),
        onTap: () => Navigator.pop(context, 'Option 1'),
      ),
      ListTile(
        title: Text('Option 2'),
        onTap: () => Navigator.pop(context, 'Option 2'),
      ),
    ],
  ),
  themeConfig: themeConfig,
);
```

---

## 13. Connectivity Banner (AppConnectivityBanner)

Show offline indicator:

```dart
AppConnectivityBanner(
  child: YourScreenWidget(),
  themeConfig: themeConfig,
)
```

Automatically shows banner when offline, hides when online.

---

## 14. Pull to Refresh (AppPullToRefresh)

Themed refresh indicator:

```dart
AppPullToRefresh(
  onRefresh: () async {
    await Future.delayed(Duration(seconds: 2));
    // Refresh data here
  },
  child: ListView(children: [...]),
  themeConfig: themeConfig,
)
```

---

## 15. Theme Configuration (AppThemeConfig)

Update colors, fonts, and spacing globally:

```dart
final config = AppThemeConfig(
  primaryDarkColor: 0xFF8f4e00,      // Your brand color
  primaryLightColor: 0xFFff9933,
  headlineFontFamily: 'Plus Jakarta Sans',
  bodyFontFamily: 'Manrope',
  buttonBorderRadius: 9999.0,
  cardBorderRadius: 16.0,
  inputBorderRadius: 8.0,
);

// Use in components
AppButton(label: 'Click', onPressed: () {}, themeConfig: config)
```

---

## Usage Pattern in Screens

### 1. Import what you need
```dart
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/l10n/app_localization.dart'; // For strings
```

### 2. Use in build() method
```dart
@override
Widget build(BuildContext context) {
  final strings = AppLocalization.of(context);
  
  return Scaffold(
    body: AppLoader.circular(),  // While loading
  );
}

// After loading
return Column(
  children: [
    Text(strings.appTitle, style: AppTextStyles.headline(context)),
    AppButton(
      label: strings.continueButton,
      onPressed: () { },
    ),
  ],
);
```

---

## Best Practices

1. **Always pass `themeConfig`** to components for consistency
2. **Use localization strings** instead of hardcoded English text
3. **Use AppButton variants** instead of custom buttons
4. **Use AppLoader/AppShimmer** for loading states
5. **Use AppSnackbar** instead of ScaffoldMessenger directly
6. **Update AppThemeConfig defaults** to change brand colors globally
7. **Use AppTextStyles** for typography consistency

---

## Common Patterns

### Loading State
```dart
if (isLoading) {
  return AppLoader.circular();
}
```

### Empty State
```dart
if (items.isEmpty) {
  return AppEmptyState(
    message: strings.noItemsFound,
    onAction: refreshData,
    actionLabel: strings.refresh,
  );
}
```

### Success Message
```dart
AppSnackbar.showSuccess(context, strings.savedSuccessfully);
```

### Confirmation Before Delete
```dart
final confirmed = await AppDialog.showDeleteConfirm(
  context,
  itemName: item.name,
);
if (confirmed) {
  deleteItem();
}
```

---

**For more examples, check:**
- Design system components: `design_system/lib/src/components/`
- Usage in screens: `shree_krishna_emb_user_app/lib/screens/`
