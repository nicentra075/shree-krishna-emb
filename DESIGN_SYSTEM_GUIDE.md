# Design System Components Guide

## Overview

This guide ensures consistent use of design system components across all apps (User App, Admin App). All UI elements must use components from `shree_krishna_design_system` package instead of building custom widgets.

---

## Core Principle

**NEVER build custom UI components when a design system component exists.**

Instead of:
```dart
// ❌ Bad - Custom TextField
TextField(
  controller: controller,
  decoration: InputDecoration(...),
)
```

Use:
```dart
// ✅ Good - Design system component
AppTextField(
  controller: controller,
  hint: 'Enter email',
)
```

---

## Available Components

### Input Components

#### AppTextField
Reusable text field with consistent styling.

```dart
AppTextField(
  label: 'Email Address',
  hint: 'you@example.com',
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icon(Icons.mail_outline),
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
)
```

**Parameters:**
- `label` - Label text above the field
- `hint` - Placeholder text
- `controller` - TextEditingController
- `validator` - Form validation function
- `keyboardType` - Type of keyboard (text, email, phone, etc.)
- `obscureText` - Hide input (for passwords)
- `enabled` - Enable/disable the field
- `maxLines` - Number of lines (default: 1)
- `prefixIcon` - Icon before text
- `suffixIcon` - Icon after text
- `onChanged` - Callback on text change
- `themeConfig` - Optional theme override

**Usage Examples:**

Email field:
```dart
AppTextField(
  label: 'Email',
  hint: 'you@example.com',
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icon(Icons.mail_outline),
)
```

Password field (with visibility toggle):
```dart
AppTextField(
  label: 'Password',
  hint: 'Enter password',
  controller: _passwordController,
  obscureText: _obscurePassword,
  prefixIcon: Icon(Icons.lock_outline),
  suffixIcon: GestureDetector(
    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
    child: Icon(
      _obscurePassword ? Icons.visibility_off : Icons.visibility,
    ),
  ),
)
```

Phone field:
```dart
AppTextField(
  label: 'Phone Number',
  hint: '+91 98765 43210',
  controller: _phoneController,
  keyboardType: TextInputType.phone,
  prefixIcon: Icon(Icons.phone_outlined),
)
```

Name field:
```dart
AppTextField(
  label: 'Full Name',
  hint: 'John Doe',
  controller: _nameController,
  keyboardType: TextInputType.name,
  prefixIcon: Icon(Icons.person_outline),
)
```

---

## Do's & Don'ts

### Do's ✅
- Use AppTextField for all text inputs
- Import from `shree_krishna_design_system`
- Keep icons from Material Design (Icons.*)
- Use AppTextStyles from design system for text
- Respect AppTheme colors

### Don'ts ❌
- Don't create custom TextField decorations
- Don't hardcode colors (use AppTheme)
- Don't create custom buttons when AppButton exists
- Don't use ScaffoldMessenger for snackbars (use AppSnackbar)
- Don't build custom dialogs (use AppDialog)

---

## When Claude Adds Features

1. Check this guide for existing components
2. Use design system components first
3. Never create custom widgets for common UI patterns
4. Update this guide if new components are added

---

**Last Updated:** April 2026
**Design System Package:** shree_krishna_design_system
