import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ui_toolbox/flutter_ui_toolbox.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';
import 'package:shree_krishna_emb/screens/auth/complete_profile_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;

  const OtpVerificationScreen({super.key, this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;
  int _remainingSeconds = 45;
  bool _canResendOtp = false;
  late Stopwatch _stopwatch;
  String? _verificationId;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    _stopwatch = Stopwatch()..start();
    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        _verificationId = args['verificationId'] as String?;
        _phoneNumber = args['phoneNumber'] as String?;
      }
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _remainingSeconds = 45 - _stopwatch.elapsed.inSeconds;
          if (_remainingSeconds <= 0) {
            _canResendOtp = true;
          } else {
            _startTimer();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppAppBar(
        title: 'Verify Phone Number',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            AppSnackbar.showSuccess('Phone verified successfully!');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                // ignore: use_build_context_synchronously
                AppRoutes.navigateToHome(context);
              }
            });
          } else if (state is AuthNewPhoneUser) {
            AppRoutes.navigateToCompleteProfile(
              context,
              CompleteProfileArgs(
                type: 'phone',
                user: state.user,
                phoneNumber: state.phoneNumber,
              ),
            );
          } else if (state is AuthError) {
            AppSnackbar.showError(state.message);
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildOtpInputBoxes(),
                const SizedBox(height: 30),
                _buildVerifyButton(context),
                const SizedBox(height: 20),
                _buildResendSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.phone_iphone, color: colorScheme.primary, size: 30),
        ),
        const SizedBox(height: 20),
        Text(
          'Enter Verification Code',
          style: AppTextStyles.headlineLarge(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to\n${_phoneNumber ?? 'your phone'}',
          style: AppTextStyles.bodyMedium(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtpInputBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              height: 56,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  // Keep only digits and limit to 1 character
                  final filteredValue = value.replaceAll(RegExp(r'[^0-9]'), '');

                  // Always update controller to have only 1 digit or empty
                  final finalValue = filteredValue.isEmpty
                      ? ''
                      : filteredValue[0];
                  _otpControllers[index].text = finalValue;

                  // Position cursor at the end
                  if (finalValue.isNotEmpty) {
                    _otpControllers[index].selection =
                        TextSelection.fromPosition(TextPosition(offset: 1));
                  }

                  // Auto-move to next field when 1 digit is entered
                  if (finalValue.isNotEmpty && index < 5) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _otpFocusNodes[index + 1].requestFocus();
                    });
                  } else if (finalValue.isEmpty && index > 0) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _otpFocusNodes[index - 1].requestFocus();
                    });
                  }
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton(BuildContext context) {
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
              onPressed: isLoading ? null : () => _handleVerifyOtp(context),
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
                  : Text('Verify OTP', style: AppTextStyles.button()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        if (!_canResendOtp)
          Text(
            'Resend code in $_remainingSeconds seconds',
            style: AppTextStyles.bodySmall(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          GestureDetector(
            onTap: () {
              setState(() {
                _remainingSeconds = 45;
                _canResendOtp = false;
                _stopwatch.reset();
                _stopwatch.start();
                _startTimer();
                for (var controller in _otpControllers) {
                  controller.clear();
                }
              });
              if (_phoneNumber != null) {
                context.read<AuthBloc>().add(
                  SendPhoneOtpEvent(phoneNumber: _phoneNumber!),
                );
              }
            },
            child: Text(
              'Resend Code',
              style: AppTextStyles.labelMedium(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  void _handleVerifyOtp(BuildContext context) {
    final otp = _otpControllers.map((controller) => controller.text).join();
    log('🔵 [OtpVerificationScreen] OTP entered: $otp (length: ${otp.length})');

    if (otp.length != 6) {
      AppSnackbar.showError('Please enter a valid 6-digit code');
      return;
    }

    if (_verificationId == null || _phoneNumber == null) {
      log('🔴 [OtpVerificationScreen] Missing verificationId or phoneNumber');
      AppSnackbar.showError('Verification ID or phone number is missing');
      return;
    }

    log(
      '🔵 [OtpVerificationScreen] Dispatching VerifyPhoneOtpEvent - OTP: $otp, VerificationId: $_verificationId, Phone: $_phoneNumber',
    );
    context.read<AuthBloc>().add(
      VerifyPhoneOtpEvent(
        verificationId: _verificationId!,
        smsCode: otp,
        phoneNumber: _phoneNumber!,
      ),
    );
  }
}
