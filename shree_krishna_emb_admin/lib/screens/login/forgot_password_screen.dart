import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  // TODO: Implement forgot password logic
                  AppSnackbar.showSuccess(AppLocalization.strings.resetLinkSentMessage);
                  Navigator.pop(context);
                },
                variant: AppButtonVariant.primary,
                isFullWidth: true,
                size: AppButtonSize.large,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
