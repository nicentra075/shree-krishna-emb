import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_ui_toolbox/flutter_ui_toolbox.dart' hide AppTextField;
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';
import 'package:shree_krishna_emb/core/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppSnackbar.showSuccess('Account created successfully!');
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    _buildHeader(context, strings),
                    const SizedBox(height: 40),
                    _buildSignupCard(context, strings),
                    const SizedBox(height: 24),
                    _buildSocialSignup(context, strings),
                    const SizedBox(height: 32),
                    _buildLoginLink(context, strings),
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
                color: AppTheme.secondaryLight.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, dynamic strings) {
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
            child: Icon(Icons.spa, size: 34, color: AppTheme.primaryDark),
          ).centered,
          const SizedBox(height: 16),

          Text(
            'Create Account',
            style: AppTextStyles.headlineLarge(color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),

          Text(
            'Join ${AppLocalization.strings.appName} community',
            style: AppTextStyles.bodyLarge(color: AppTheme.textBrown),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignupCard(BuildContext context, dynamic strings) {
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
              color: AppTheme.textDark.withValues(alpha: 0.06),
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
              _buildNameField(context),
              const SizedBox(height: 20),

              _buildEmailField(context),
              const SizedBox(height: 20),

              _buildPhoneField(context),
              const SizedBox(height: 20),

              _buildPasswordField(context),
              const SizedBox(height: 20),

              _buildConfirmPasswordField(context),
              const SizedBox(height: 24),

              _buildSignupButton(context, strings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(BuildContext context) {
    return AppTextField(
      label: 'Full Name',
      hint: 'John Doe',
      controller: _nameController,
      keyboardType: TextInputType.name,
      textInputAction: .next,
      validator: (value) => Validators.validateName(value),
      prefixIcon: Icon(
        Icons.person_outline,
        color: AppTheme.primaryDark.withValues(alpha: 0.5),
        size: 20,
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return AppTextField(
      label: 'Email Address',
      hint: 'you@example.com',
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: .next,
      validator: (value) => Validators.validateEmail(value),
      prefixIcon: Icon(
        Icons.mail_outline,
        color: AppTheme.primaryDark.withValues(alpha: 0.5),
        size: 20,
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    return AppTextField(
      label: 'Phone Number',
      hint: '98765 43210',
      controller: _phoneController,
      keyboardType: TextInputType.number,
      textInputAction: .next,
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
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return AppTextField(
      label: 'Password',
      hint: 'Enter your password',
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: .next,
      validator: (value) => Validators.validatePassword(value),
      prefixIcon: Icon(
        Icons.lock_outline,
        color: AppTheme.primaryDark.withValues(alpha: 0.5),
        size: 20,
      ),
      suffixIcon: GestureDetector(
        onTap: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        child: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: AppTheme.primaryDark.withValues(alpha: 0.5),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField(BuildContext context) {
    return AppTextField(
      label: 'Confirm Password',
      hint: 'Confirm your password',
      controller: _confirmPasswordController,
      textInputAction: .done,
      obscureText: _obscureConfirmPassword,
      validator: (value) =>
          Validators.validateConfirmPassword(_passwordController.text, value),
      prefixIcon: Icon(
        Icons.lock_outline,
        color: AppTheme.primaryDark.withValues(alpha: 0.5),
        size: 20,
      ),
      suffixIcon: GestureDetector(
        onTap: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
        child: Icon(
          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          color: AppTheme.primaryDark.withValues(alpha: 0.5),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSignupButton(BuildContext context, dynamic strings) {
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
                colors: [AppTheme.primaryDark, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _handleSignup(context),
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
                      child: AppLoader(size: 20, color: Colors.white),
                    )
                  : Text('Create Account', style: AppTextStyles.button()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialSignup(BuildContext context, dynamic strings) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      delay: const Duration(milliseconds: 400),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(color: AppTheme.borderLight, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or continue with',
                  style: AppTextStyles.bodySmall(
                    color: AppTheme.textBrown.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppTheme.borderLight, thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  icon: Icons.email_outlined,
                  label: 'Google',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSocialButton(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryDark),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelMedium(
                fontWeight: FontWeight.w600,
                color: AppTheme.textBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context, dynamic strings) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      delay: const Duration(milliseconds: 600),
      child: Center(
        child: RichText(
          text: TextSpan(
            text: "Already have an account? ",
            style: AppTextStyles.bodyMedium(color: AppTheme.textBrown),
            children: [
              TextSpan(
                text: 'Sign In',
                style: AppTextStyles.bodyMedium(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    AppRoutes.push(context, AppRoutes.login);
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSignup(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }


    context.read<AuthBloc>().add(
      SignUpEvent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '+91${_phoneController.text.trim()}',
        password: _passwordController.text,
      ),
    );
  }
}
