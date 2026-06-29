import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/platform_config/platform_config_cubit.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

/// Settings "Payments" section: Test/Live mode toggle (with a clear warning
/// when Live is selected), Razorpay publishable test+live key fields, and
/// platform fee % / GST % — all saved to `config/platform`.
class PaymentsSection extends StatelessWidget {
  const PaymentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlatformConfigCubit>(
      create: (_) => GetIt.instance<PlatformConfigCubit>()..load(),
      child: const _PaymentsForm(),
    );
  }
}

class _PaymentsForm extends StatefulWidget {
  const _PaymentsForm();

  @override
  State<_PaymentsForm> createState() => _PaymentsFormState();
}

class _PaymentsFormState extends State<_PaymentsForm> {
  final _formKey = GlobalKey<FormState>();
  final _testKeyController = TextEditingController();
  final _liveKeyController = TextEditingController();
  final _testSecretController = TextEditingController();
  final _liveSecretController = TextEditingController();
  final _feeController = TextEditingController();
  final _gstController = TextEditingController();

  bool _testMode = true;
  bool _hydrated = false;
  bool _obscureSecret = true;
  bool _platformFeeEnabled = true;
  bool _gstEnabled = true;

  @override
  void dispose() {
    _testKeyController.dispose();
    _liveKeyController.dispose();
    _testSecretController.dispose();
    _liveSecretController.dispose();
    _feeController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  String? _validatePercent(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 0 || parsed > 100) {
      return AppLocalization.strings.feeValidationError;
    }
    return null;
  }

  /// A charge row: a title + on/off [Switch], and — only when enabled — the
  /// percentage input. When the switch is off the charge is not applied or
  /// shown in the user app. The percent value is preserved across toggles.
  Widget _chargeToggleField({
    required dynamic strings,
    required ColorScheme colorScheme,
    required String title,
    required String fieldLabel,
    required String hint,
    required TextEditingController controller,
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.labelMedium(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch(value: enabled, onChanged: onToggle),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: controller,
            label: fieldLabel,
            hint: hint,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: enabled ? _validatePercent : null,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<PlatformConfigCubit, PlatformConfigState>(
      listener: (context, state) {
        if (state.status == PlatformConfigStatus.loaded &&
            state.config != null &&
            !_hydrated) {
          final c = state.config!;
          _testMode = c.paymentTestMode;
          _testKeyController.text = c.razorpayKeyIdTest;
          _liveKeyController.text = c.razorpayKeyIdLive;
          _feeController.text = c.settings.platformFeePercent.toString();
          _gstController.text = c.settings.gstPercent.toString();
          _platformFeeEnabled = c.settings.platformFeeEnabled;
          _gstEnabled = c.settings.gstEnabled;
          _hydrated = true;
          setState(() {});
        }
      },
      builder: (context, state) {
        if (state.status == PlatformConfigStatus.loading ||
            state.status == PlatformConfigStatus.initial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: AppLoader()),
          );
        }
        if (state.config == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.error ?? strings.error,
                style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: strings.retry,
                variant: AppButtonVariant.secondary,
                onPressed: () => context.read<PlatformConfigCubit>().load(),
              ),
            ],
          );
        }

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.paymentMode,
                style: AppTextStyles.labelMedium(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _modeToggle(strings),
              if (!_testMode) ...[
                const SizedBox(height: 12),
                _liveWarning(colorScheme, strings),
              ],
              const SizedBox(height: 16),
              // Only the active mode's credentials are shown — Test fields when
              // Test is selected, Live fields when Live is selected.
              if (_testMode)
                ..._modeCredentialFields(
                  strings: strings,
                  colorScheme: colorScheme,
                  keyController: _testKeyController,
                  secretController: _testSecretController,
                  keyLabel: strings.razorpayTestKey,
                  keyHint: strings.razorpayTestKeyHint,
                  secretLabel: strings.razorpayTestSecretKey,
                  secretAlreadySet: state.config!.razorpayKeySecretTestSet,
                )
              else
                ..._modeCredentialFields(
                  strings: strings,
                  colorScheme: colorScheme,
                  keyController: _liveKeyController,
                  secretController: _liveSecretController,
                  keyLabel: strings.razorpayLiveKey,
                  keyHint: strings.razorpayLiveKeyHint,
                  secretLabel: strings.razorpayLiveSecretKey,
                  secretAlreadySet: state.config!.razorpayKeySecretLiveSet,
                ),
              const SizedBox(height: 16),
              _chargeToggleField(
                strings: strings,
                colorScheme: colorScheme,
                title: strings.platformFee,
                fieldLabel: strings.platformFeePercent,
                hint: '12',
                controller: _feeController,
                enabled: _platformFeeEnabled,
                onToggle: (v) => setState(() => _platformFeeEnabled = v),
              ),
              const SizedBox(height: 16),
              _chargeToggleField(
                strings: strings,
                colorScheme: colorScheme,
                title: strings.gst,
                fieldLabel: strings.gstPercent,
                hint: '18',
                controller: _gstController,
                enabled: _gstEnabled,
                onToggle: (v) => setState(() => _gstEnabled = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: strings.save,
                  leadingIcon: Icons.save_outlined,
                  isLoading: state.status == PlatformConfigStatus.saving,
                  onPressed: () => _save(context, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modeToggle(dynamic strings) {
    return SegmentedButton<bool>(
      segments: [
        ButtonSegment<bool>(
          value: true,
          icon: const Icon(Icons.science_outlined, size: 18),
          label: Text(
            strings.testMode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ButtonSegment<bool>(
          value: false,
          icon: const Icon(Icons.bolt, size: 18),
          label: Text(
            strings.liveMode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      selected: {_testMode},
      onSelectionChanged: (selection) {
        setState(() => _testMode = selection.first);
      },
    );
  }

  /// Key ID + (masked) Secret Key fields for a single mode, plus the security
  /// note. The Secret Key is write-only: when one is already stored server-side
  /// the field stays empty and shows a "saved — leave blank to keep" hint.
  List<Widget> _modeCredentialFields({
    required dynamic strings,
    required ColorScheme colorScheme,
    required TextEditingController keyController,
    required TextEditingController secretController,
    required String keyLabel,
    required String keyHint,
    required String secretLabel,
    required bool secretAlreadySet,
  }) {
    return [
      AppTextField(
        controller: keyController,
        label: keyLabel,
        hint: keyHint,
      ),
      const SizedBox(height: 16),
      AppTextField(
        controller: secretController,
        label: secretLabel,
        hint: secretAlreadySet
            ? strings.razorpaySecretSavedHint
            : strings.razorpaySecretHint,
        obscureText: _obscureSecret,
        prefixIcon: const Icon(Icons.key_outlined),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscureSecret = !_obscureSecret),
          child: Icon(
            _obscureSecret ? Icons.visibility_off : Icons.visibility,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.razorpaySecretNote,
              style: AppTextStyles.bodySmall(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _liveWarning(ColorScheme colorScheme, dynamic strings) {
    const warnColor = Color(0xFFFF6B6B);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warnColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warnColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: warnColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.liveModeWarning,
              style: AppTextStyles.bodySmall(color: warnColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, PlatformConfigState state) async {
    final strings = AppLocalization.strings;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final config = state.config!;
    final cubit = context.read<PlatformConfigCubit>();

    final authState = context.read<AdminAuthBloc>().state;
    final updatedBy = authState is AdminAuthAuthenticated
        ? authState.adminId
        : 'admin';

    // When a charge is toggled off its field is hidden — fall back to 0 / the
    // last known value rather than parsing an empty/absent field.
    final feePercent = _platformFeeEnabled
        ? (double.tryParse(_feeController.text.trim()) ?? 0)
        : config.settings.platformFeePercent;
    final gstPercent = _gstEnabled
        ? (double.tryParse(_gstController.text.trim()) ?? 0)
        : config.settings.gstPercent;

    final ok = await cubit.save(
      platformFeePercent: feePercent,
      gstPercent: gstPercent,
      paymentTestMode: _testMode,
      platformFeeEnabled: _platformFeeEnabled,
      gstEnabled: _gstEnabled,
      razorpayKeyIdTest: _testKeyController.text.trim(),
      razorpayKeyIdLive: _liveKeyController.text.trim(),
      // Preserve the seller/invoice fields managed elsewhere.
      supportEmail: config.settings.supportEmail,
      invoicePrefix: config.settings.invoicePrefix,
      sellerName: config.settings.sellerName,
      sellerAddress: config.settings.sellerAddress,
      sellerGstin: config.settings.sellerGstin,
      updatedBy: updatedBy,
    );
    if (!context.mounted) return;
    if (!ok) {
      ResponsiveSnackbar.showError(cubit.state.error ?? strings.error, context);
      return;
    }

    // If the admin entered a Secret Key for the active mode, store it securely
    // via the Cloud Function (encrypted server-side, never persisted client-side).
    final secretController = _testMode
        ? _testSecretController
        : _liveSecretController;
    final secret = secretController.text.trim();
    if (secret.isNotEmpty) {
      final secretOk = await cubit.setRazorpaySecret(
        mode: _testMode ? 'test' : 'live',
        secret: secret,
      );
      if (!context.mounted) return;
      if (secretOk) {
        secretController.clear();
        ResponsiveSnackbar.showSuccess(strings.razorpaySecretSaved, context);
      } else {
        ResponsiveSnackbar.showError(
          cubit.state.error ?? strings.error,
          context,
        );
      }
      return;
    }

    ResponsiveSnackbar.showSuccess(strings.settingsSaved, context);
  }
}
