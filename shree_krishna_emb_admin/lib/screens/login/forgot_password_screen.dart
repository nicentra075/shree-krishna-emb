import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/password_reset_cubit.dart';
import 'package:shree_krishna_emb_admin/core/di/service_locator.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  void _submit(BuildContext context) {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      ResponsiveSnackbar.showError(
        AppLocalization.strings.invalidEmail,
        context,
      );
      return;
    }
    context.read<PasswordResetCubit>().sendResetEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PasswordResetCubit>(
      create: (_) => getIt<PasswordResetCubit>(),
      child: BlocConsumer<PasswordResetCubit, PasswordResetState>(
        listener: (context, state) {
          if (state is PasswordResetSent) {
            ResponsiveSnackbar.showSuccess(
              AppLocalization.strings.resetLinkSentMessage,
              context,
            );
            Navigator.pop(context);
          } else if (state is PasswordResetError) {
            ResponsiveSnackbar.showError(state.message, context);
          }
        },
        builder: (context, state) {
          final isSending = state is PasswordResetSending;
          return Scaffold(
            appBar: AppAppBar(
              title: AppLocalization.strings.resetPassword,
              onBack: () => Navigator.pop(context),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalization.strings.enterYourEmail,
                      style: AppTextStyles.headlineMedium(
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalization.strings.resetLinkMessage,
                      style: AppTextStyles.bodyMedium(
                        color: AppTheme.textBrown,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: AppLocalization.strings.adminEmail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        color: AppTheme.primaryDark.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: AppLocalization.strings.sendResetLink,
                      onPressed: isSending ? null : () => _submit(context),
                      isLoading: isSending,
                      variant: AppButtonVariant.primary,
                      isFullWidth: true,
                      size: AppButtonSize.large,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
