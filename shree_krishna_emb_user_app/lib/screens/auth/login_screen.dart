import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_ui_toolbox/flutter_ui_toolbox.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF5),
      body: Stack(
        children: [
          // Decorative background
          _buildBackgroundDecoration(),

          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  _buildHeader(context, strings),
                  const SizedBox(height: 40),
                  _buildLoginCard(context, strings),
                  const SizedBox(height: 24),
                  _buildSocialLogin(context, strings),
                  const SizedBox(height: 32),
                  _buildSignUpLink(context, strings),
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

  Widget _buildHeader(BuildContext context, dynamic strings) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Brand Logo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryLight.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.spa, size: 34, color: AppTheme.primaryDark),
          ).centered,
          const SizedBox(height: 16),

          // Title
          Text(
            'Welcome Back',
            style: AppTextStyles.headlineLarge(
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Sign in to your ${AppLocalization.strings.appName} account',
            style: AppTextStyles.bodyLarge(
              color: AppTheme.textBrown,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, dynamic strings) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Field
            _buildEmailField(context),
            const SizedBox(height: 20),

            // Password Field
            _buildPasswordField(context),
            const SizedBox(height: 12),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  AppRoutes.push(context, AppRoutes.forgotPassword);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                ),
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.labelMedium(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login Button
            _buildLoginButton(context, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: AppTextStyles.labelMedium(
            fontWeight: FontWeight.w600,
            color: AppTheme.textBrown,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'you@example.com',
            hintStyle: AppTextStyles.bodyMedium(
              color: AppTheme.textBrown.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.mail_outline,
              color: AppTheme.primaryDark.withValues(alpha: 0.5),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.borderLight,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primaryDark, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.borderLight,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF554336),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: AppTextStyles.bodyMedium(
              color: AppTheme.textBrown.withValues(alpha: 0.5),
            ),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.borderLight,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primaryDark, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.borderLight,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, dynamic strings) {
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
          onPressed: () {
            // TODO: Implement login logic
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Sign In',
            style: AppTextStyles.button(),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLogin(BuildContext context, dynamic strings) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      delay: const Duration(milliseconds: 400),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(color: const Color(0xFFE8E8E3), thickness: 1),
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
                child: Divider(color: const Color(0xFFE8E8E3), thickness: 1),
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
          border: Border.all(color: const Color(0xFFE8E8E3), width: 1.5),
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

  Widget _buildSignUpLink(BuildContext context, dynamic strings) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      delay: const Duration(milliseconds: 600),
      child: Center(
        child: RichText(
          text: TextSpan(
            text: "Don't have an account? ",
            style: AppTextStyles.bodyMedium(
              color: const Color(0xFF554336),
            ),
            children: [
              TextSpan(
                text: 'Sign Up',
                style: AppTextStyles.bodyMedium(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    AppRoutes.push(context, AppRoutes.signup);
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
