import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    show AppNotificationModel, AppNotificationType;
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';

import '../../bloc/notifications/admin_notifications_cubit.dart';
import '../../core/di/service_locator.dart';
import '../../l10n/app_localization.dart';

/// Shared admin inbox: purchase alerts + broadcast confirmations written to
/// `admin_notifications`. Unread items are highlighted; tapping an item marks
/// it read (order/design deep-link navigation is a future enhancement — for
/// now the item's data is display-only to avoid an extra per-item fetch).
class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider<AdminNotificationsCubit>.value(
      value: getIt<AdminNotificationsCubit>(),
      child: Scaffold(
        appBar: AppAppBar(
          title: s.adminNotificationsTitle,
          onBack: () => Navigator.of(context).pop(),
          actions: [
            BlocBuilder<AdminNotificationsCubit, AdminNotificationsState>(
              builder: (context, state) {
                final hasUnread = state.unreadCount > 0;
                return TextButton(
                  onPressed: hasUnread
                      ? () => context.read<AdminNotificationsCubit>().markAllRead()
                      : null,
                  child: Text(
                    s.markAllRead,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<AdminNotificationsCubit, AdminNotificationsState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return AppEmptyState(message: s.noAdminNotifications);
            }
            return ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = state.items[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(
                      Icons.delete_outline,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) =>
                      context.read<AdminNotificationsCubit>().delete(n.id),
                  child: _NotificationTile(notification: n, colorScheme: colorScheme),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final ColorScheme colorScheme;

  const _NotificationTile({required this.notification, required this.colorScheme});

  IconData get _icon => switch (notification.type) {
        AppNotificationType.purchase => Icons.shopping_bag_outlined,
        AppNotificationType.broadcast => Icons.campaign_outlined,
        AppNotificationType.newDesign => Icons.brush_outlined,
      };

  String _timestamp() =>
      DateFormat('dd MMM, hh:mm a').format(notification.createdAt);

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return ListTile(
      leading: Icon(
        _icon,
        color: n.read ? colorScheme.outline : colorScheme.primary,
      ),
      title: Text(
        n.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        n.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Text(
        _timestamp(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
      ),
      tileColor: n.read ? null : colorScheme.primaryContainer.withValues(alpha: 0.18),
      onTap: n.read
          ? null
          : () => context.read<AdminNotificationsCubit>().markRead(n.id),
    );
  }
}
