import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

class SelectOption {
  final String value;
  final String label;
  const SelectOption(this.value, this.label);
}

/// A tappable field that opens a dialog with a **search box** + filtered list.
/// Use where a plain dropdown is too long to scan (collections/categories,
/// authors, etc.).
class SearchableSelect extends StatelessWidget {
  final String? label;
  final String hint;
  final String? value;
  final List<SelectOption> options;
  final ValueChanged<String?> onSelected;

  const SearchableSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onSelected,
    required this.hint,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = options.where((o) => o.value == value);
    final display = selected.isNotEmpty ? selected.first.label : null;

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
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openPicker(context),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    display ?? hint,
                    style: AppTextStyles.bodyMedium(
                      color: display != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, setState) {
            final filtered = query.isEmpty
                ? options
                : options
                    .where((o) =>
                        o.label.toLowerCase().contains(query.toLowerCase()))
                    .toList();
            return Dialog(
              child: Container(
                width: 440,
                constraints: const BoxConstraints(maxHeight: 520),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => query = v),
                      style:
                          AppTextStyles.bodyMedium(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: AppLocalization.strings.search,
                        hintStyle: AppTextStyles.bodyMedium(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.search,
                            size: 18, color: colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(AppLocalization.strings.noData,
                                  style: AppTextStyles.bodyMedium(
                                      color: colorScheme.onSurfaceVariant)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final o = filtered[i];
                                final isSel = o.value == value;
                                return ListTile(
                                  dense: true,
                                  selected: isSel,
                                  selectedTileColor: colorScheme.primary
                                      .withValues(alpha: 0.08),
                                  title: Text(o.label,
                                      style: AppTextStyles.bodyMedium(
                                          color: colorScheme.onSurface),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  trailing: isSel
                                      ? Icon(Icons.check,
                                          size: 18, color: colorScheme.primary)
                                      : null,
                                  onTap: () {
                                    onSelected(o.value);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
