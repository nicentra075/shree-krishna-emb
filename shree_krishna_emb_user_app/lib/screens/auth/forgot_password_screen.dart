import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/core/utils/validators.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';

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
          'Reset Password',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF1A1C19),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSent) {
            AppSnackbar.showSuccess(
              'Password reset email sent! Check your inbox.',
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pop(this.context);
              }
            });
          } else if (state is AuthError) {
            AppSnackbar.showError(state.message);
          }
        },
        child: Stack(
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
      child: Icon(Icons.lock_outline, size: 50, color: AppTheme.primaryLight),
    );
  }

  Widget _buildTitle(dynamic strings) {
    return Column(
      children: [
        Text(
          'Forgot Password?',
          style: AppTextStyles.headlineLarge(color: AppTheme.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: AppTextStyles.bodyMedium(color: AppTheme.textBrown),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, dynamic strings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C19).withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          AppTextField(
            label: 'Email Address',
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Icons.mail_outline,
              color: AppTheme.primaryDark.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          const SizedBox(height: 24),
          _buildSendButton(context),
        ],
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryDark, const Color(0xFFFF9933)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _handleSendReset(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                          AppTheme.surfaceLight,
                        ),
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Send Reset Link', style: AppTextStyles.button()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackToLoginLink(BuildContext context, dynamic strings) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Text(
          'Back to Login',
          style: AppTextStyles.labelMedium(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleSendReset(BuildContext context) {
    final email = _emailController.text.trim();

    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      AppSnackbar.showError(emailError);
      return;
    }

    context.read<AuthBloc>().add(SendPasswordResetEmailEvent(email: email));
  }
}
