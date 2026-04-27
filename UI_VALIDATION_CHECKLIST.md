# UI Component & Localization Validation Checklist

## ⚠️ CRITICAL: Every UI change MUST pass both checks

This document serves as your validation agent. Before ANY UI screen is considered complete, it MUST satisfy ALL items below.

---

## Check 1: Design System Components Usage

### Inspect for Custom UI Components

```bash
# NO results should be found in screens/
grep -r "TextField(" lib/screens/
grep -r "ElevatedButton(" lib/screens/
grep -r "OutlineInputBorder(" lib/screens/
```

### Requirements

- ✅ All text inputs use `AppTextField` (from `shree_krishna_design_system`)
- ✅ All buttons use `AppButton` (from design system)
- ✅ All snackbars use `AppSnackbar.show()` (NOT `ScaffoldMessenger`)
- ✅ All dialogs use `AppDialog` (NOT custom widgets)
- ✅ All colors use `AppTheme` (NOT hardcoded colors)
- ✅ All text styles use `AppTextStyles` (NOT inline `copyWith()`)
- ✅ Import aliases correct: `import 'package:flutter_ui_toolbox/flutter_ui_toolbox.dart' hide AppTextField;`

### Design System Components Reference

**AppTextField** (for all text inputs):
```dart
AppTextField(
  label: 'Field Label',
  hint: 'Placeholder text',
  controller: _controller,
  keyboardType: TextInputType.email,
  prefixIcon: Icon(Icons.mail_outline),
  obscureText: false,
)
```

**Other Components:**
- `AppButton` - buttons
- `AppSnackbar.show()` - notifications
- `AppDialog` - dialogs
- `AppLoader` - loading spinners
- `AppShimmer` - skeleton loaders

---

## Check 2: Localization (NO Hardcoded Strings)

### Inspect for Hardcoded Strings

```bash
# Check for strings in Text() without AppLocalization.strings
grep -r "Text('" lib/screens/ | grep -v "AppLocalization.strings"
```

### Requirements

- ✅ NO string literals in `Text()`, `hint`, `label`, or button text
- ✅ ALL labels use `AppLocalization.strings.yourKey`
- ✅ ALL hints use `AppLocalization.strings.yourKey`
- ✅ ALL button text use `AppLocalization.strings.yourKey`
- ✅ ALL error messages use `AppLocalization.strings.yourKey`
- ✅ New strings added to BOTH `en_us.dart` AND `hi_in.dart`

### Localization Pattern

**In UI Screen:**
```dart
AppTextField(
  label: AppLocalization.strings.fullName,
  hint: AppLocalization.strings.fullNameHint,
)
```

**Add to locale_base.dart:**
```dart
String get fullName;
String get fullNameHint;
```

**Add to en_us.dart:**
```dart
@override
String get fullName => 'Full Name';
@override
String get fullNameHint => 'Enter your full name';
```

**Add to hi_in.dart:**
```dart
@override
String get fullName => 'पूरा नाम';
@override
String get fullNameHint => 'अपना पूरा नाम दर्ज करें';
```

---

## Validation Checklist Template

Use this checklist for EVERY new/updated screen:

### Design System Check
- [ ] No custom `TextField` widgets - use `AppTextField`
- [ ] No hardcoded `InputDecoration` - use `AppTextField` styling
- [ ] No custom button decorations - use `AppButton`
- [ ] No `ScaffoldMessenger.showSnackBar` - use `AppSnackbar.show()`
- [ ] All colors from `AppTheme`
- [ ] All text styles from `AppTextStyles`
- [ ] Imports correct: `hide AppTextField` from flutter_ui_toolbox

### Localization Check
- [ ] No `Text('string')` without `AppLocalization.strings`
- [ ] All labels localized
- [ ] All hints localized
- [ ] All button text localized
- [ ] All error messages localized
- [ ] New strings in locale_base.dart
- [ ] New strings in en_us.dart
- [ ] New strings in hi_in.dart

### Code Quality Check
- [ ] `flutter analyze` shows no errors
- [ ] Follows Clean Architecture pattern
- [ ] No Firebase imports in presentation layer

---

## Common Mistakes & Fixes

### ❌ Mistake 1: Custom TextField

```dart
// WRONG
TextField(
  decoration: InputDecoration(
    hintText: 'Email',
    border: OutlineInputBorder(...),
  ),
)
```

✅ **Fix:**
```dart
// RIGHT
AppTextField(
  label: AppLocalization.strings.email,
  hint: AppLocalization.strings.emailHint,
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
)
```

### ❌ Mistake 2: Hardcoded String

```dart
// WRONG
Text('Create Account')
```

✅ **Fix:**
```dart
// RIGHT
Text(AppLocalization.strings.createAccount)
```

### ❌ Mistake 3: ScaffoldMessenger

```dart
// WRONG
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Success!')),
)
```

✅ **Fix:**
```dart
// RIGHT - Once AppSnackbar is available
AppSnackbar.show(
  context: context,
  message: AppLocalization.strings.successMessage,
)
```

---

## Files to Review

- **Design System:** `/design_system/lib/src/components/`
- **Localization Files:**
  - `/lib/localisations/app_localization.dart`
  - `/lib/localisations/locales/locale_base.dart`
  - `/lib/localisations/locales/en_us.dart`
  - `/lib/localisations/locales/hi_in.dart`
- **Design System Guide:** `DESIGN_SYSTEM_GUIDE.md`
- **CLAUDE.md:** Design System & Localization sections

---

## When Adding a New Screen

1. **Design System First:**
   - Use only `AppTextField`, `AppButton`, etc.
   - Never create custom decorations

2. **Localization Second:**
   - Identify all user-visible strings
   - Add string keys to `locale_base.dart`
   - Implement in both `en_us.dart` and `hi_in.dart`
   - Use `AppLocalization.strings.key` in UI

3. **Code Quality:**
   - Run `flutter analyze` - should be clean
   - Check import statements
   - Follow Clean Architecture

4. **Testing:**
   - Test in both English and Hindi locales
   - Verify design matches with other screens

---

**Last Updated:** April 2026  
**Maintained By:** Claude  
**Critical Rules:** Design System + Localization (100% required)
