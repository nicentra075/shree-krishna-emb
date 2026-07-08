import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';

import '../../bloc/notifications/admin_notifications_cubit.dart';
import '../../l10n/app_localization.dart';
import 'admin_notifications_screen.dart' show AdminNotificationTile;

/// Anchored preview popup opened from the dashboard header bell — shows the
/// latest [previewCount] admin notifications with a "View more" action that
/// switches the dashboard sidebar over to the full Notifications section.
class AdminNotificationsPopup extends StatelessWidget {
  static const int previewCount = 5;

  /// Closes the popup overlay (removes it from the Overlay).
  final VoidCallback onClose;

  /// Switches the dashboard's selected sidebar section to 'notifications'.
  final VoidCallback onViewMore;

  const AdminNotificationsPopup({
    super.key,
    required this.onClose,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final popupWidth = screenWidth < 400 ? screenWidth - 24 : 340.0;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surface,
      child: Container(
        width: popupWidth,
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: BlocBuilder<AdminNotificationsCubit, AdminNotificationsState>(
          bloc: GetIt.instance<AdminNotificationsCubit>(),
          builder: (context, state) {
            final items = state.items.take(previewCount).toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    s.adminNotificationsTitle,
                    style: AppTextStyles.labelMedium(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              s.noAdminNotifications,
                              style: AppTextStyles.bodyMedium(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) => AdminNotificationTile(
                            notification: items[i],
                            colorScheme: colorScheme,
                          ),
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        onClose();
                        onViewMore();
                      },
                      child: Text(
                        s.viewMore,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
