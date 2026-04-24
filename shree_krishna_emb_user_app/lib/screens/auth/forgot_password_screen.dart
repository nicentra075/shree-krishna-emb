import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController _emailOrPhoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailOrPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C19)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          strings.forgotPassword ?? 'Reset Password',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1A1C19),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundDecoration(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildSecurityIcon(),
                  const SizedBox(height: 32),
                  _buildTitle(strings),
                  const SizedBox(height: 32),
                  _buildForm(context, strings),
                  const SizedBox(height: 32),
                  _buildBackToLoginLink(context, strings),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned(
      right: -100,
      bottom: -150,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildSecurityIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF0F4FF),
      ),
      child: Icon(
        Icons.lock_outline,
        size: 56,
        color: AppTheme.secondaryDark,
      ),
    );
  }

  Widget _buildTitle(dynamic strings) {
    return Column(
      children: [
        Text(
          strings.forgotPassword ?? 'Forgot Password?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1C19),
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'No worries! Enter your email or phone number and we\'ll send you a link to reset your password.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF554336),
                height: 1.6,
              ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, dynamic strings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C19).withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.email ?? 'Email or Phone Number',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C19),
                ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            hint: 'name@example.com or +91 9876543210',
            controller: _emailOrPhoneController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Send Reset Link →',
            onPressed: _isLoading ? null : _handleSendResetLink,
            isLoading: _isLoading,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginLink(BuildContext context, dynamic strings) {
    return TextButton(
      onPressed: () {
        AppRoutes.pushReplacementAll(context, AppRoutes.login);
      },
      child: Text(
        '← ${strings.back ?? 'Back'} to ${strings.signIn ?? 'Login'}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  void _handleSendResetLink() async {
    if (_emailOrPhoneController.text.isEmpty) {
      AppSnackbar.showError(
        AppLocalization.strings.fieldRequired,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        AppSnackbar.showSuccess(
          'Password reset link sent to your email',
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            AppRoutes.pushReplacementAll(context, AppRoutes.login);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError('Failed to send reset link');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
