import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart'
    show CatalogStatus, kDefaultCatalogPageSize, kCatalogPageSizeOptions;
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

/// Shared list scaffold for the Design Store tabs: an "Add" header, then a
/// status-driven body (loading / error+retry / empty / list).
class CatalogScaffold extends StatelessWidget {
  final String addLabel;
  final VoidCallback onAdd;
  final CatalogStatus status;
  final bool isEmpty;
  final String emptyText;
  final VoidCallback onRetry;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Optional extra controls placed in the header (e.g. filters/search).
  final List<Widget> headerLeading;

  /// Optional pagination — when [totalPages] > 1 a pagination bar is shown.
  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageChanged;

  /// Optional rows-per-page selector. When [onPageSizeChanged] is provided a
  /// "Per page" dropdown is shown in the footer.
  final int pageSize;
  final ValueChanged<int>? onPageSizeChanged;

  const CatalogScaffold({
    super.key,
    required this.addLabel,
    required this.onAdd,
    required this.status,
    required this.isEmpty,
    required this.emptyText,
    required this.onRetry,
    required this.itemCount,
    required this.itemBuilder,
    this.headerLeading = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
    this.pageSize = kDefaultCatalogPageSize,
    this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              // Leading controls (search/sort/filters) wrap onto a new line on
              // narrow widths instead of overflowing.
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: headerLeading,
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: addLabel,
                leadingIcon: Icons.add,
                onPressed: onAdd,
                size: AppButtonSize.medium,
              ),
            ],
          ),
        ),
        Expanded(child: _body(context, colorScheme)),
        if (status == CatalogStatus.loaded && !isEmpty)
          _FooterBar(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
            pageSize: pageSize,
            onPageSizeChanged: onPageSizeChanged,
          ),
      ],
    );
  }

  Widget _body(BuildContext context, ColorScheme colorScheme) {
    if (status == CatalogStatus.loading || status == CatalogStatus.initial) {
      return const Center(child: AppLoader());
    }
    if (status == CatalogStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalization.strings.error,
              style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: AppLocalization.strings.retry,
              onPressed: onRetry,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      );
    }
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              emptyText,
              style: AppTextStyles.bodyMedium(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: itemBuilder,
    );
  }
}

/// A single catalog row: thumbnail + title/subtitle + active badge + actions.
class CatalogListRow extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final bool isActive;

  /// Null hides the corresponding action (e.g. designers cannot edit/delete
  /// the shared taxonomy — D2).
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? trailingInfo;

  const CatalogListRow({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    this.subtitle,
    this.trailingInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const activeColor = Color(0xFF4CAF50);
    const inactiveColor = Color(0xFFFF6B6B);
    final statusColor = isActive ? activeColor : inactiveColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          AppNetworkImage(
            imageUrl: imageUrl,
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (trailingInfo != null) ...[
                  const SizedBox(height: 4),
                  trailingInfo!,
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isActive
                  ? AppLocalization.strings.active
                  : AppLocalization.strings.inactive,
              style: AppTextStyles.labelSmall(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: AppLocalization.strings.edit,
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppTheme.primaryDark,
              ),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              tooltip: AppLocalization.strings.delete,
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Color(0xFFFF6B6B),
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// Footer with a "Per page" selector (left) and pagination (center).
class _FooterBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageChanged;
  final int pageSize;
  final ValueChanged<int>? onPageSizeChanged;

  const _FooterBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.pageSize,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showPager = totalPages > 1 && onPageChanged != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Row(
        children: [
          if (onPageSizeChanged != null)
            _PageSizeSelector(
              pageSize: pageSize,
              onChanged: onPageSizeChanged!,
            ),
          Expanded(
            child: showPager
                ? _PaginationBar(
                    currentPage: currentPage,
                    totalPages: totalPages,
                    onPageChanged: onPageChanged!,
                  )
                : const SizedBox.shrink(),
          ),
          // Balances the per-page selector so the pager stays centred.
          if (onPageSizeChanged != null && showPager)
            const SizedBox(width: 120),
        ],
      ),
    );
  }
}

/// "Per page" rows-per-page dropdown.
class _PageSizeSelector extends StatelessWidget {
  final int pageSize;
  final ValueChanged<int> onChanged;
  const _PageSizeSelector({required this.pageSize, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final value = kCatalogPageSizeOptions.contains(pageSize)
        ? pageSize
        : kDefaultCatalogPageSize;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${AppLocalization.strings.perPage}: ',
            style: AppTextStyles.labelSmall(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          DropdownButton<int>(
            value: value,
            underline: const SizedBox(),
            isDense: true,
            dropdownColor: colorScheme.surface,
            style: AppTextStyles.labelMedium(color: colorScheme.onSurface),
            items: kCatalogPageSizeOptions
                .map(
                  (n) => DropdownMenuItem(
                    value: n,
                    child: Text(
                      '$n',
                      style: AppTextStyles.labelMedium(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (n) {
              if (n != null) onChanged(n);
            },
          ),
        ],
      ),
    );
  }
}

/// Prev / numbered pages / next bar for catalog lists.
class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final start = (currentPage - 2).clamp(1, totalPages);
    final end = (start + 4).clamp(1, totalPages);
    final pages = [for (var p = start; p <= end; p++) p];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous',
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
        ),
        ...pages.map((p) {
          final selected = p == currentPage;
          return GestureDetector(
            onTap: () => onPageChanged(p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryDark : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$p',
                style: AppTextStyles.labelSmall(
                  color: selected ? Colors.white : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
        IconButton(
          tooltip: 'Next',
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}
