import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/platform_config/platform_config_cubit.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

/// Edit the platform fee % + GST % (and show seller/invoice info), saved to
/// `config/platform`. Validation: 0–100.
class PlatformFeesContentView extends StatelessWidget {
  const PlatformFeesContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlatformConfigCubit>(
      create: (_) => GetIt.instance<PlatformConfigCubit>()..load(),
      child: const _PlatformFeesBody(),
    );
  }
}

class _PlatformFeesBody extends StatefulWidget {
  const _PlatformFeesBody();

  @override
  State<_PlatformFeesBody> createState() => _PlatformFeesBodyState();
}

class _PlatformFeesBodyState extends State<_PlatformFeesBody> {
  final _formKey = GlobalKey<FormState>();
  final _feeController = TextEditingController();
  final _gstController = TextEditingController();
  bool _hydrated = false;

  @override
  void dispose() {
    _feeController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  String? _validatePercent(String? value) {
    final strings = AppLocalization.strings;
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 0 || parsed > 100) {
      return strings.feeValidationError;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: BlocConsumer<PlatformConfigCubit, PlatformConfigState>(
        listener: (context, state) {
          if (state.status == PlatformConfigStatus.loaded &&
              state.config != null &&
              !_hydrated) {
            _feeController.text = state.config!.settings.platformFeePercent
                .toString();
            _gstController.text = state.config!.settings.gstPercent.toString();
            _hydrated = true;
          }
        },
        builder: (context, state) {
          if (state.status == PlatformConfigStatus.loading ||
              state.status == PlatformConfigStatus.initial) {
            return const Center(child: AppLoader());
          }
          if (state.status == PlatformConfigStatus.error &&
              state.config == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.error ?? strings.error,
                    style: AppTextStyles.bodyMedium(
                      color: colorScheme.onSurface,
                    ),
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
              ),
            );
          }

          final settings = state.config!.settings;
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 480;
                    final padding = isSmall ? 12.0 : 24.0;
                    return Padding(
                      padding: EdgeInsets.all(padding),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.platformFees,
                              style: AppTextStyles.headlineMedium(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmall ? 16 : 24),
                            _card(
                              colorScheme,
                              icon: Icons.percent,
                              title: strings.platformFees,
                              child: Column(
                                children: [
                                  AppTextField(
                                    controller: _feeController,
                                    label: strings.platformFeePercent,
                                    hint: '12',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: _validatePercent,
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    controller: _gstController,
                                    label: strings.gstPercent,
                                    hint: '18',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: _validatePercent,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmall ? 12 : 16),
                            _card(
                              colorScheme,
                              icon: Icons.store_outlined,
                              title: strings.sellerInfo,
                              child: Column(
                                children: [
                                  _readOnlyRow(
                                    colorScheme,
                                    strings.sellerName,
                                    settings.sellerName,
                                  ),
                                  _readOnlyRow(
                                    colorScheme,
                                    strings.invoicePrefix,
                                    settings.invoicePrefix,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmall ? 16 : 24),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: strings.save,
                                leadingIcon: Icons.save_outlined,
                                isLoading:
                                    state.status == PlatformConfigStatus.saving,
                                onPressed: () => _save(context, state),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelMedium(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _readOnlyRow(ColorScheme colorScheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value.isEmpty ? '—' : value,
            style: AppTextStyles.bodyMedium(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

    final ok = await cubit.save(
      platformFeePercent: double.parse(_feeController.text.trim()),
      gstPercent: double.parse(_gstController.text.trim()),
      // Preserve the payment-mode + key fields + fee/gst enable flags
      // (edited in Settings → Payments).
      paymentTestMode: config.paymentTestMode,
      platformFeeEnabled: config.settings.platformFeeEnabled,
      gstEnabled: config.settings.gstEnabled,
      razorpayKeyIdTest: config.razorpayKeyIdTest,
      razorpayKeyIdLive: config.razorpayKeyIdLive,
      supportEmail: config.settings.supportEmail,
      invoicePrefix: config.settings.invoicePrefix,
      sellerName: config.settings.sellerName,
      sellerAddress: config.settings.sellerAddress,
      sellerGstin: config.settings.sellerGstin,
      updatedBy: updatedBy,
    );
    if (!context.mounted) return;
    if (ok) {
      ResponsiveSnackbar.showSuccess(strings.settingsSaved, context);
    } else {
      ResponsiveSnackbar.showError(cubit.state.error ?? strings.error, context);
    }
  }
}
