import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/settings/notification_settings_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/settings/notification_settings_state.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

/// Settings "Notifications" section: master push toggle, purchase/new-design
/// alert toggles, up to 4 daily send-time slots and timezone — all saved to
/// `config/notifications`.
///
/// Expects a [NotificationSettingsCubit] to already be provided above it in
/// the widget tree (owned by the parent settings screen so it survives tab
/// switches — see `settings_content_view.dart`).
class NotificationSettingsForm extends StatelessWidget {
  const NotificationSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
      listener: (context, state) {
        if (state.status == NotifSettingsStatus.saved) {
          ResponsiveSnackbar.showSuccess(strings.success, context);
        } else if (state.status == NotifSettingsStatus.error) {
          ResponsiveSnackbar.showError(state.error ?? strings.error, context);
        }
      },
      builder: (context, state) {
        if (state.status == NotifSettingsStatus.loading ||
            state.status == NotifSettingsStatus.initial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final cubit = context.read<NotificationSettingsCubit>();
        final cfg = state.settings;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: cfg.masterEnabled,
                  onChanged: cubit.toggleMaster,
                  title: Text(
                    strings.enablePushNotifications,
                    style: AppTextStyles.bodyMedium(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: cfg.purchaseAlertsEnabled,
                  onChanged: cfg.masterEnabled ? cubit.togglePurchase : null,
                  title: Text(
                    strings.purchaseAlerts,
                    style: AppTextStyles.bodyMedium(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: cfg.newDesignAlertsEnabled,
                  onChanged: cfg.masterEnabled ? cubit.toggleNewDesign : null,
                  title: Text(
                    strings.newDesignAlerts,
                    style: AppTextStyles.bodyMedium(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  strings.dailySendTimes,
                  style: AppTextStyles.labelMedium(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  strings.dailySendTimesHelp,
                  style: AppTextStyles.bodySmall(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slot in cfg.dailySlots)
                      Chip(
                        label: Text(
                          slot,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: cfg.masterEnabled
                            ? () => cubit.removeSlot(slot)
                            : null,
                      ),
                    if (cfg.dailySlots.length <
                        NotificationSettingsCubit.maxSlots)
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(
                          strings.addSendTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: !cfg.masterEnabled
                            ? null
                            : () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 10,
                                    minute: 0,
                                  ),
                                );
                                if (picked != null) {
                                  cubit.addSlot(
                                    '${picked.hour.toString().padLeft(2, '0')}:'
                                    '${picked.minute.toString().padLeft(2, '0')}',
                                  );
                                }
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  strings.maxFourSlots,
                  style: AppTextStyles.bodySmall(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                if (state.hasUnsavedChanges) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.tertiary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.unsavedChanges,
                            style: AppTextStyles.bodySmall(
                              color: colorScheme.onTertiaryContainer,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 10 : 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: strings.save,
                    isLoading: state.status == NotifSettingsStatus.saving,
                    onPressed: () {
                      final authState = context.read<AdminAuthBloc>().state;
                      final adminUid = authState is AdminAuthAuthenticated
                          ? authState.adminId
                          : '';
                      cubit.save(adminUid);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
