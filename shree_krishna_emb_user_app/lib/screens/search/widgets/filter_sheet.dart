import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_catalog_query_datasource.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

/// Bottom sheet with sort, category, price-range and free-only filters.
/// Pops with the chosen [SearchFilters], or null when dismissed.
class SearchFilterSheet extends StatefulWidget {
  final SearchFilters initial;
  final List<CategoryItem> categories;

  const SearchFilterSheet({
    required this.initial,
    required this.categories,
    super.key,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late String? _categoryId;
  late bool _freeOnly;
  late String _sort;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initial.categoryId;
    _freeOnly = widget.initial.freeOnly;
    _sort = widget.initial.sort;
    _minController = TextEditingController(
      text: widget.initial.minPrice?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initial.maxPrice?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    final min = int.tryParse(_minController.text.trim());
    final max = int.tryParse(_maxController.text.trim());
    Navigator.pop(
      context,
      SearchFilters(
        categoryId: _categoryId,
        minPrice: min,
        maxPrice: max,
        freeOnly: _freeOnly,
        sort: _sort,
      ),
    );
  }

  void _clear() {
    Navigator.pop(context, const SearchFilters());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final sortOptions = <(String, String)>[
      ('newest', strings.sortNewest),
      ('popularity', strings.sortPopular),
      ('priceAsc', strings.sortPriceLowHigh),
      ('priceDesc', strings.sortPriceHighLow),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.filters,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineMedium(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(strings.sortBy, colorScheme),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (value, label) in sortOptions)
                    _choiceChip(
                      label: label,
                      selected: _sort == value,
                      onTap: () => setState(() => _sort = value),
                    ),
                ],
              ),
              if (widget.categories.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionTitle(strings.categories, colorScheme),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _choiceChip(
                      label: strings.allCategories,
                      selected: _categoryId == null,
                      onTap: () => setState(() => _categoryId = null),
                    ),
                    for (final c in widget.categories)
                      _choiceChip(
                        label: c.name,
                        selected: _categoryId == c.id,
                        onTap: () => setState(() => _categoryId = c.id),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _sectionTitle(strings.priceRange, colorScheme),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: strings.minPrice,
                      hint: '0',
                      controller: _minController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: strings.maxPrice,
                      hint: '5000',
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.freeOnly,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Switch(
                    value: _freeOnly,
                    onChanged: (v) => setState(() => _freeOnly = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: strings.clearFilters,
                      onPressed: _clear,
                      variant: AppButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: strings.applyFilters,
                      onPressed: _apply,
                      variant: AppButtonVariant.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.labelMedium(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSmall(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
