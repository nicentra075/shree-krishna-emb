import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_ui_toolbox/flutter_ui_toolbox.dart' hide AppTextField;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/core/constants/app_constants.dart';
import 'package:shree_krishna_emb/core/utils/validators.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';
import 'package:shree_krishna_emb/screens/auth/complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool(AppConstants.prefKeyRememberMe) ?? false;
    if (remembered) {
      setState(() {
        _rememberMe = true;
        _emailController.text =
            prefs.getString(AppConstants.prefKeySavedEmail) ?? '';
        _passwordController.text =
            prefs.getString(AppConstants.prefKeySavedPassword) ?? '';
      });
    }
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
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppSnackbar.showSuccess('Signed in successfully!');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                AppRoutes.navigateToHome(context);
              }
            });
          } else if (state is AuthNewGoogleUser) {
            AppRoutes.navigateToCompleteProfile(
              context,
              CompleteProfileArgs(type: 'google', user: state.user),
            );
          } else if (state is AuthPhoneOtpSent) {
            AppRoutes.push(
              context,
              AppRoutes.otpVerification,
              arguments: {
                'verificationId': state.verificationId,
                'phoneNumber': state.phoneNumber,
              },
            );
          } else if (state is AuthSuspended) {
            AppSnackbar.showError(
              AppLocalization.strings.accountSuspendedMessage,
            );
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
            'Welcome Back',
            style: AppTextStyles.headlineLarge(color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to your ${AppLocalization.strings.appName} account',
            style: AppTextStyles.bodyLarge(color: AppTheme.textBrown),
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
            _buildEmailField(context),
            const SizedBox(height: 20),
            _buildPasswordField(context),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRememberMeRow(context).expanded(),
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
              ],
            ),
            const SizedBox(height: 24),
            _buildLoginButton(context, strings),
          ],
        ),
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
      prefixIcon: Icon(
        Icons.mail_outline,
        color: AppTheme.primaryDark.withValues(alpha: 0.5),
        size: 20,
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return AppTextField(
      label: 'Password',
      hint: 'Enter your password',
      controller: _passwordController,
      obscureText: _obscurePassword,
      prefixIcon: Icon(
        Icons.lock_outline,
        color: AppTheme.primaryDark.withValues(alpha: 0.5),
        size: 20,
      ),
      textInputAction: .done,
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

  Widget _buildRememberMeRow(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (val) => setState(() => _rememberMe = val ?? false),
          activeColor: AppTheme.primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Text(
            AppLocalization.strings.rememberMe,
            style: AppTextStyles.bodySmall(color: AppTheme.textBrown),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, dynamic strings) {
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
              onPressed: isLoading ? null : () => _handleEmailSignIn(context),
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
                      child: AppLoader(size: 20, color: AppTheme.surfaceLight),
                    )
                  : Text('Sign In', style: AppTextStyles.button()),
            ),
          ),
        );
      },
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
                  onTap: () => _handleGoogleSignIn(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSocialButton(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  onTap: () => _showPhoneInputDialog(context),
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
            style: AppTextStyles.bodyMedium(color: const Color(0xFF554336)),
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

  void _handleEmailSignIn(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      AppSnackbar.showError(emailError);
      return;
    }

    if (password.isEmpty) {
      AppSnackbar.showError('Password is required');
      return;
    }

    final authBloc = context.read<AuthBloc>();
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(AppConstants.prefKeyRememberMe, true);
      await prefs.setString(AppConstants.prefKeySavedEmail, email);
      await prefs.setString(AppConstants.prefKeySavedPassword, password);
    } else {
      await prefs.remove(AppConstants.prefKeyRememberMe);
      await prefs.remove(AppConstants.prefKeySavedEmail);
      await prefs.remove(AppConstants.prefKeySavedPassword);
    }

    if (!mounted) return;

    authBloc.add(SignInEvent(email: email, password: password));
  }

  void _handleGoogleSignIn(BuildContext context) {
    context.read<AuthBloc>().add(const SignInWithGoogleEvent());
  }

  void _showPhoneInputDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final authBloc = context.read<AuthBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Phone Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '98765 43210',
            prefix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('+91'),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              final phoneError = Validators.validatePhone(phone);
              if (phoneError != null) {
                AppSnackbar.showError(phoneError);
                return;
              }
              final fullPhoneNumber = '+91$phone';
              print('🔵 [LoginScreen] Phone Dialog - User entered: $phone');
              print(
                '🔵 [LoginScreen] Phone Dialog - Sending to Firebase: $fullPhoneNumber',
              );
              Navigator.pop(dialogContext);
              authBloc.add(SendPhoneOtpEvent(phoneNumber: fullPhoneNumber));
              print(
                '🔵 [LoginScreen] Phone Dialog - SendPhoneOtpEvent dispatched',
              );
            },
            child: const Text('Send OTP'),
          ),
        ],
      ),
    );
  }
}
