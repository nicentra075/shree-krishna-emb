import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_ui_toolbox/flutter_ui_toolbox.dart' hide AppTextField;
import 'package:shree_krishna_core/models/user_model.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/core/utils/validators.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';

class CompleteProfileArgs {
  final String type; // 'google' or 'phone'
  final UserModel user;
  final String? phoneNumber;

  CompleteProfileArgs({
    required this.type,
    required this.user,
    this.phoneNumber,
  });
}

class CompleteProfileScreen extends StatefulWidget {
  final CompleteProfileArgs args;

  const CompleteProfileScreen({super.key, required this.args});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.args.user.name ?? '');
    _emailController = TextEditingController(text: widget.args.user.email);
    _phoneController = TextEditingController(
      text: widget.args.phoneNumber ?? widget.args.user.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGoogleFlow = widget.args.type == 'google';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppSnackbar.showSuccess('Profile completed successfully!');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                AppRoutes.navigateToHome(context);
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
                  children: [
                    const SizedBox(height: 48),
                    _buildHeader(context, isGoogleFlow),
                    const SizedBox(height: 40),
                    _buildProfileCard(context, isGoogleFlow),
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
    return Stack(
      children: [
        Positioned(
          right: -100,
          bottom: -100,
          child: FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        Positioned(
          left: -50,
          top: 100,
          child: FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8FA7FE).withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isGoogleFlow) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryLight.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.person_add,
              size: 34,
              color: AppTheme.primaryDark,
            ),
          ).centered,
          const SizedBox(height: 16),
          Text(
            isGoogleFlow ? 'Almost There!' : 'Complete Your Profile',
            style: AppTextStyles.headlineLarge(color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            isGoogleFlow
                ? 'Add your phone number to complete registration'
                : 'Add your name and email to complete registration',
            style: AppTextStyles.bodyLarge(color: AppTheme.textBrown),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, bool isGoogleFlow) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      delay: const Duration(milliseconds: 200),
      child: Container(
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGoogleFlow) ...[
                _buildReadOnlyField(
                  label: 'Full Name',
                  value: widget.args.user.name ?? 'User',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildReadOnlyField(
                  label: 'Email Address',
                  value: widget.args.user.email,
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Phone Number',
                  hint: '98765 43210',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) => Validators.validatePhone(value),
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        color: AppTheme.primaryDark.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+91',
                        style: AppTextStyles.bodyMedium(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ).paddingLeft(12),
                ),
              ] else ...[
                AppTextField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  validator: (value) => Validators.validateName(value),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryDark.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Email Address',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => Validators.validateEmail(value),
                  prefixIcon: Icon(
                    Icons.mail_outline,
                    color: AppTheme.primaryDark.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 20),
                _buildReadOnlyField(
                  label: 'Phone Number',
                  value: widget.args.phoneNumber ?? 'Phone',
                  icon: Icons.phone_outlined,
                ),
              ],
              const SizedBox(height: 32),
              _buildContinueButton(context, isGoogleFlow),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E3), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryDark.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.bodyMedium(color: AppTheme.textDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context, bool isGoogleFlow) {
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
              onPressed: isLoading
                  ? null
                  : () => _handleContinue(context, isGoogleFlow),
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
                  : Text('Continue', style: AppTextStyles.button()),
            ),
          ),
        );
      },
    );
  }

  void _handleContinue(BuildContext context, bool isGoogleFlow) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (isGoogleFlow) {
      context.read<AuthBloc>().add(
        CompleteGoogleProfileEvent(
          uid: widget.args.user.id,
          phoneNumber: '+91${_phoneController.text.trim()}',
        ),
      );
    } else {
      context.read<AuthBloc>().add(
        CompletePhoneProfileEvent(
          uid: widget.args.user.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        ),
      );
    }
  }
}
