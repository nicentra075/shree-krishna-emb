import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

/// Result of the cascade-delete confirmation.
enum CascadeDeleteResult {
  /// User cancelled.
  cancel,

  /// Delete only the item (children kept, but unlinked).
  onlyThis,

  /// Delete the item together with all its children.
  cascade,
}

/// A delete confirmation that — when the item has children — lets the admin
/// optionally delete those children too, and ALWAYS shows a prominent, dynamic
/// note explaining exactly what the chosen action will do.
///
/// [childSummary] is a short human description of the children (e.g.
/// "3 categories · 12 designs"); pass null/empty when there are no children
/// (the dialog then behaves like a plain delete confirmation).
Future<CascadeDeleteResult?> showCascadeDeleteDialog({
  required BuildContext context,
  required String itemName,
  required String? childSummary,
  required String cascadeOptionLabel,
  required String onlyNote,
  required String cascadeNote,
}) {
  final strings = AppLocalization.strings;
  final hasChildren = childSummary != null && childSummary.trim().isNotEmpty;
  return showDialog<CascadeDeleteResult>(
    context: context,
    builder: (dialogCtx) {
      final colorScheme = Theme.of(dialogCtx).colorScheme;
      var cascade = false;
      return StatefulBuilder(
        builder: (ctx, setState) {
          // The note reflects the CURRENT choice so the impact is never a
          // surprise. Amber for "only this", red for the destructive cascade.
          final note = !hasChildren
              ? null
              : (cascade ? cascadeNote : onlyNote);
          final noteColor =
              cascade ? const Color(0xFFD64545) : const Color(0xFFE6A23C);

          return AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: noteColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(strings.delete,
                      style: AppTextStyles.headlineMedium(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${strings.confirmDeleteMessage}\n\n$itemName',
                    style: AppTextStyles.bodyMedium(
                        color: colorScheme.onSurface),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis),
                if (hasChildren) ...[
                  const SizedBox(height: 8),
                  Text(childSummary,
                      style: AppTextStyles.labelSmall(
                          color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  // The optional cascade toggle.
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFFD64545),
                      value: cascade,
                      onChanged: (v) => setState(() => cascade = v ?? false),
                      title: Text(cascadeOptionLabel,
                          style: AppTextStyles.labelMedium(
                              color: colorScheme.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // The all-important impact note — color + text track the
                  // current choice.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: noteColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: noteColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: noteColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(strings.deleteImpactTitle,
                                  style: AppTextStyles.labelSmall(
                                      color: noteColor,
                                      fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(note ?? '',
                                  style: AppTextStyles.bodySmall(
                                      color: colorScheme.onSurface),
                                  maxLines: 6,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogCtx, CascadeDeleteResult.cancel),
                child: Text(strings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                    dialogCtx,
                    cascade
                        ? CascadeDeleteResult.cascade
                        : CascadeDeleteResult.onlyThis),
                child: Text(
                  strings.delete,
                  style: TextStyle(
                      color: cascade
                          ? const Color(0xFFD64545)
                          : AppTheme.primaryDark,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
