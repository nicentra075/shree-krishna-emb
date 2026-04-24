import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

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

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(4, (_) => TextEditingController());
    _otpFocusNodes = List.generate(4, (_) => FocusNode());
    _stopwatch = Stopwatch()..start();
    _startTimer();
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
          strings.email ?? 'OTP Verification',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildSecurityIcon(),
              const SizedBox(height: 32),
              _buildTitle(strings),
              const SizedBox(height: 24),
              _buildOtpInput(context),
              const SizedBox(height: 32),
              AppButton(
                label: 'Verify & Proceed',
                onPressed: _handleVerifyOtp,
                isFullWidth: true,
              ),
              const SizedBox(height: 20),
              _buildTimerAndResend(strings),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF0F4FF),
      ),
      child: Icon(
        Icons.security_outlined,
        size: 64,
        color: AppTheme.secondaryDark,
      ),
    );
  }

  Widget _buildTitle(dynamic strings) {
    return Column(
      children: [
        Text(
          'Verify Your Identity',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1C19),
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 4-digit code sent to ${widget.phoneNumber ?? '+91 9XXXXXXXXX'}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF554336),
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildOtpInput(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDBC2B0),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDBC2B0),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryLight,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C19),
                  ),
              onChanged: (value) {
                if (value.isNotEmpty && index < 3) {
                  _otpFocusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _otpFocusNodes[index - 1].requestFocus();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerAndResend(dynamic strings) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: "Didn't receive the code? ",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF554336),
                ),
            children: [
              TextSpan(
                text:
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _canResendOtp ? _handleResendOtp : null,
          child: Text(
            'Resend OTP',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _canResendOtp
                      ? AppTheme.primaryLight
                      : const Color(0xFFB5B5B0),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Artisanal Atelier',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFB5B5B0),
                letterSpacing: 1.0,
              ),
        ),
      ],
    );
  }

  void _handleVerifyOtp() {
    final otp =
        _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 4) {
      AppSnackbar.showError('Please enter a valid OTP');
      return;
    }

    AppSnackbar.showSuccess('OTP verified successfully');
  }

  void _handleResendOtp() {
    _stopwatch.reset();
    _stopwatch.start();
    _remainingSeconds = 45;
    _canResendOtp = false;

    for (var controller in _otpControllers) {
      controller.clear();
    }

    _startTimer();
    AppSnackbar.showSuccess('OTP sent to your phone');
  }
}
