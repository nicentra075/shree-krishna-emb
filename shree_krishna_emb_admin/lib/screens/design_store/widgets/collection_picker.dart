import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/data/models/category_model.dart';
import 'package:shree_krishna_emb_admin/data/models/collection_model.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

/// Theme-aware dropdown for picking a collection. `includeAll` adds an
/// "All Collections" option mapped to a null value (for filtering).
class CollectionPicker extends StatelessWidget {
  final List<CollectionModel> collections;
  final String? value;
  final String? label;
  final bool includeAll;
  final ValueChanged<String?> onChanged;

  const CollectionPicker({
    super.key,
    required this.collections,
    required this.value,
    required this.onChanged,
    this.label,
    this.includeAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ids = collections.map((c) => c.id).toSet();
    final safeValue = (value != null && ids.contains(value)) ? value : null;

    return _PickerBox(
      label: label,
      child: DropdownButton<String?>(
        isExpanded: true,
        underline: const SizedBox(),
        value: safeValue,
        dropdownColor: colorScheme.surface,
        hint: Text(
          includeAll
              ? '${AppLocalization.strings.collections}: ${AppLocalization.strings.active}'
              : AppLocalization.strings.selectCollection,
          style: AppTextStyles.bodyMedium(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        items: [
          if (includeAll)
            DropdownMenuItem<String?>(
              value: null,
              child: Text('${AppLocalization.strings.collections} — ${AppLocalization.strings.active}',
                  style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ...collections.map(
            (c) => DropdownMenuItem<String?>(
              value: c.id,
              child: Text(c.name,
                  style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Theme-aware dropdown for picking a category (already scoped to a collection
/// by the caller).
class CategoryPicker extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? value;
  final String? label;
  final bool includeAll;
  final ValueChanged<String?> onChanged;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.value,
    required this.onChanged,
    this.label,
    this.includeAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ids = categories.map((c) => c.id).toSet();
    final safeValue = (value != null && ids.contains(value)) ? value : null;

    return _PickerBox(
      label: label,
      child: DropdownButton<String?>(
        isExpanded: true,
        underline: const SizedBox(),
        value: safeValue,
        dropdownColor: colorScheme.surface,
        hint: Text(
          includeAll
              ? 'All ${AppLocalization.strings.categories}'
              : AppLocalization.strings.selectCategory,
          style: AppTextStyles.bodyMedium(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        items: [
          if (includeAll)
            DropdownMenuItem<String?>(
              value: null,
              child: Text('All ${AppLocalization.strings.categories}',
                  style:
                      AppTextStyles.bodyMedium(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ...categories.map(
            (c) => DropdownMenuItem<String?>(
              value: c.id,
              child: Text(c.name,
                  style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _PickerBox extends StatelessWidget {
  final String? label;
  final Widget child;
  const _PickerBox({required this.child, this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style:
                  AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
        ],
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ],
    );
  }
}
