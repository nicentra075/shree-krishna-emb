import 'package:flutter/material.dart';
import '../../theme/design_system_theme.dart';
import '../../tokens/app_border_radius.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Reusable text field component with consistent styling
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final AppThemeConfig? themeConfig;
  final TextInputAction? textInputAction;

  const AppTextField({
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.themeConfig,
    this.textInputAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final focusColor = DesignSystemTheme.primaryDark(themeConfig);

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      enabled: enabled,
      maxLines: maxLines,
      minLines: maxLines == 1 ? null : 1,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: BorderSide(color: focusColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }
}
