import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/notification_prefs/notification_prefs_cubit.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

/// Notification preference toggles (WS-B4): master push switch + category
/// switches, persisted to users/{uid}.notificationPrefs.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late final NotificationPrefsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<NotificationPrefsCubit>();
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppAppBar(
          title: strings.notificationPreferences,
          onBack: () => Navigator.pop(context),
        ),
        body: BlocConsumer<NotificationPrefsCubit, NotificationPrefsState>(
          listener: (context, state) {
            if (state.saveResult == PrefsSaveResult.saved) {
              AppSnackbar.showSuccess(strings.preferencesSaved);
            } else if (state.saveResult == PrefsSaveResult.failed) {
              AppSnackbar.showError(state.error ?? strings.somethingWentWrong);
            }
          },
          builder: (context, state) {
            switch (state.status) {
              case NotificationPrefsStatus.initial:
              case NotificationPrefsStatus.loading:
                return const Center(child: AppLoader());
              case NotificationPrefsStatus.error:
                return AppEmptyState(
                  icon: Icons.error_outline,
                  message: strings.somethingWentWrong,
                  actionLabel: strings.retry,
                  onAction: _cubit.load,
                );
              case NotificationPrefsStatus.loaded:
                final prefs = state.prefs;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _prefTile(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title: strings.pushNotifications,
                      subtitle: strings.pushNotificationsDesc,
                      value: prefs.pushEnabled,
                      onChanged: (v) =>
                          _cubit.update(prefs.copyWith(pushEnabled: v)),
                    ),
                    const SizedBox(height: 10),
                    _prefTile(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: strings.purchaseAlerts,
                      subtitle: strings.purchaseAlertsDesc,
                      value: prefs.purchaseAlerts,
                      enabled: prefs.pushEnabled,
                      onChanged: (v) =>
                          _cubit.update(prefs.copyWith(purchaseAlerts: v)),
                    ),
                    const SizedBox(height: 10),
                    _prefTile(
                      context,
                      icon: Icons.auto_awesome_outlined,
                      title: strings.newDesignAlerts,
                      subtitle: strings.newDesignAlertsDesc,
                      value: prefs.newDesignAlerts,
                      enabled: prefs.pushEnabled,
                      onChanged: (v) =>
                          _cubit.update(prefs.copyWith(newDesignAlerts: v)),
                    ),
                    const SizedBox(height: 10),
                    _prefTile(
                      context,
                      icon: Icons.campaign_outlined,
                      title: strings.promotionalNotifications,
                      subtitle: strings.promotionalNotificationsDesc,
                      value: prefs.promotions,
                      enabled: prefs.pushEnabled,
                      onChanged: (v) =>
                          _cubit.update(prefs.copyWith(promotions: v)),
                    ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }

  Widget _prefTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: enabled ? colorScheme.primary : colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium(
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.outline,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}
