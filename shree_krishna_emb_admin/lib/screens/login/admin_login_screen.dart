import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _resetEmailController;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _showResetPassword = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _resetEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 768;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1200;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocListener<AdminAuthBloc, AdminAuthState>(
        listener: (context, state) {
          if (state is AdminAuthAuthenticated) {
            ResponsiveSnackbar.showSuccess(
              AppLocalization.strings.adminWelcomeSuccess,
              context,
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && context.mounted) {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            });
          } else if (state is AdminAuthError) {
            ResponsiveSnackbar.showError(state.message, context);
          }
        },
        child: isSmallScreen
            ? _buildMobileLayout(context)
            : isTablet
            ? _buildTabletLayout(context)
            : _buildDesktopLayout(context),
      ),
    );
  }

  // Desktop: Full split layout
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left panel - Branding
        Expanded(flex: 60, child: _buildBrandingPanel()),
        // Right panel - Login form
        Expanded(flex: 40, child: _buildLoginPanel(context)),
      ],
    );
  }

  // Tablet: Stacked layout
  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildBrandingPanel(compact: true),
          const SizedBox(height: 40),
          _buildLoginPanel(context, compact: true),
        ],
      ),
    );
  }

  // Mobile: Center layout
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: _buildLoginPanel(context, compact: true, mobileFull: true),
    );
  }

  // Branding panel (left side on desktop)
  Widget _buildBrandingPanel({bool compact = false}) {
    final strings = AppLocalization.strings;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primaryDark.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Floating decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLight.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Content
          Align(
            alignment: .center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                ZoomIn(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    width: compact ? 80 : 100,
                    height: compact ? 80 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryLight.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryLight.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppTheme.primaryLight.withValues(alpha: 0.6),
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.spa,
                          size: compact ? 40 : 50,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 32 : 48),
                // Title
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        strings.adminLoginTitle,
                        style: AppTextStyles.displayMedium(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.adminLoginSubtitle,
                        style: AppTextStyles.headlineMedium(
                          color: AppTheme.primaryLight.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 32 : 48),
                // Tagline
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    strings.adminLoginTagline,
                    style: AppTextStyles.bodyMedium(
                      color: AppTheme.primaryLight.withValues(alpha: 0.85),
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Login form panel (right side on desktop)
  Widget _buildLoginPanel(
    BuildContext context, {
    bool compact = false,
    bool mobileFull = false,
  }) {
    final strings = AppLocalization.strings;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mobileFull ? 24 : (compact ? 32 : 48),
            vertical: compact ? 40 : 60,
          ),
          child: _showResetPassword
              ? _buildResetPasswordForm(context, strings, compact)
              : _buildLoginForm(context, strings, compact),
        ),
      ),
    );
  }

  // Build login form
  Widget _buildLoginForm(BuildContext context, dynamic strings, bool compact) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.adminLoginWelcome,
                style: AppTextStyles.displayMedium(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                strings.adminLoginDescription,
                style: AppTextStyles.bodyLarge(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 32 : 48),
        // Email field
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 200),
          child: AppTextField(
            label: 'Email',
            hint: 'admin@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(
              Icons.mail_outline,
              color: AppTheme.primaryDark.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
        ),
        SizedBox(height: compact ? 20 : 24),
        // Password field
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 300),
          child: AppTextField(
            label: 'Password',
            hint: strings.adminPasswordHint,
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
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
          ),
        ),
        SizedBox(height: compact ? 16 : 20),
        // Remember me + Forgot password
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 400),
          child: Row(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (val) {
                      setState(() {
                        _rememberMe = val ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _rememberMe = !_rememberMe;
                      });
                    },
                    child: Text(
                      strings.adminRememberMe,
                      style: AppTextStyles.bodySmall(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showResetPassword = true;
                    _emailController.clear();
                    _passwordController.clear();
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                ),
                child: Text(
                  strings.adminForgotPassword,
                  style: AppTextStyles.labelMedium(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 28 : 32),
        // Sign in button
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 500),
          child: _buildSignInButton(context),
        ),
        SizedBox(height: compact ? 32 : 48),
        // Copyright
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 600),
          child: Center(
            child: Text(
              strings.adminCopyright,
              style: AppTextStyles.bodySmall(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // Build reset password form
  Widget _buildResetPasswordForm(
    BuildContext context,
    dynamic strings,
    bool compact,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _showResetPassword = false;
                _resetEmailController.clear();
              });
            },
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to Sign In'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Header
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.resetPassword,
                style: AppTextStyles.displayMedium(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                strings.resetLinkMessage,
                style: AppTextStyles.bodyLarge(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 32 : 48),
        // Email field
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 200),
          child: AppTextField(
            label: 'Email',
            hint: 'admin@example.com',
            controller: _resetEmailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Icons.mail_outline,
              color: AppTheme.primaryDark.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
        ),
        SizedBox(height: compact ? 28 : 32),
        // Send button
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 300),
          child: SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDark, const Color(0xFFFF9933)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_resetEmailController.text.isEmpty) {
                    ResponsiveSnackbar.showError(
                      strings.fieldRequired,
                      context,
                    );
                    return;
                  }
                  if (!_resetEmailController.text.contains('@')) {
                    ResponsiveSnackbar.showError(strings.invalidEmail, context);
                    return;
                  }
                  // TODO: Call reset password API
                  ResponsiveSnackbar.showSuccess(
                    strings.resetLinkSentMessage,
                    context,
                  );
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() {
                        _showResetPassword = false;
                        _resetEmailController.clear();
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  strings.sendResetLink,
                  style: AppTextStyles.button(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 32 : 48),
        // Copyright
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 600),
          child: Center(
            child: Text(
              strings.adminCopyright,
              style: AppTextStyles.bodySmall(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // Sign in button with loading state
  Widget _buildSignInButton(BuildContext context) {
    final strings = AppLocalization.strings;

    return BlocBuilder<AdminAuthBloc, AdminAuthState>(
      builder: (context, state) {
        final isLoading = state is AdminAuthLoading;

        return SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryDark, const Color(0xFFFF9933)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _handleSignIn(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: AppLoader(size: 20, color: Colors.white),
                    )
                  : Text(
                      strings.adminSignIn,
                      style: AppTextStyles.button(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        );
      },
    );
  }

  void _handleSignIn(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final strings = AppLocalization.strings;

    if (email.isEmpty) {
      ResponsiveSnackbar.showError(strings.fieldRequired, context);
      return;
    }

    if (!email.contains('@')) {
      ResponsiveSnackbar.showError(strings.invalidEmail, context);
      return;
    }

    if (password.isEmpty) {
      ResponsiveSnackbar.showError(strings.fieldRequired, context);
      return;
    }

    context.read<AdminAuthBloc>().add(
      AdminSignInEvent(email: email, password: password),
    );
  }
}
