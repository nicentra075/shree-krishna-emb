import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/categories_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/designs_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/home_layout_cubit.dart';
import 'package:shree_krishna_emb_admin/data/models/category_model.dart';
import 'package:shree_krishna_emb_admin/data/models/collection_model.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';
import 'package:shree_krishna_emb_admin/domain/entities/home_section.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/collection_picker.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/image_picker_field.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/searchable_select.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

class SectionEditDialog extends StatefulWidget {
  final HomeSectionConfig section;
  const SectionEditDialog({super.key, required this.section});

  @override
  State<SectionEditDialog> createState() => _SectionEditDialogState();
}

class _SectionEditDialogState extends State<SectionEditDialog> {
  late final TextEditingController _title;
  late String _viewAllTarget;
  late final TextEditingController _limit;
  late bool _viewAllEnabled;
  late String _sort;
  String? _collectionId;
  String? _categoryId;
  late List<BannerItemConfig> _banners;
  late bool _manual;
  late List<String> _manualIds;

  HomeSectionType get _type => widget.section.type;
  bool get _isBanner => _type == HomeSectionType.banner;
  bool get _hasDesignFilters =>
      _type == HomeSectionType.designsHorizontal ||
      _type == HomeSectionType.designsVertical;
  bool get _hasCollectionFilter =>
      _type == HomeSectionType.categoriesHorizontal || _hasDesignFilters;
  bool get _hasLimit => !_isBanner;

  /// Section types that can either auto-resolve all active items or be
  /// hand-curated to a specific ordered set.
  bool get _supportsManual =>
      _type == HomeSectionType.collectionsGrid ||
      _type == HomeSectionType.categoriesHorizontal ||
      _hasDesignFilters;

  @override
  void initState() {
    super.initState();
    final s = widget.section;
    _title = TextEditingController(text: s.title ?? '');
    _viewAllTarget = s.viewAll.target ?? '';
    _limit = TextEditingController(text: s.source.limit.toString());
    _viewAllEnabled = s.viewAll.enabled;
    _sort = s.source.sort;
    _collectionId = s.source.collectionId;
    _categoryId = s.source.categoryId;
    _banners = List<BannerItemConfig>.from(s.source.items);
    _manual = s.source.manual;
    _manualIds = List<String>.from(s.source.manualIds);
  }

  @override
  void dispose() {
    _title.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final collections = context.watch<CollectionsCubit>().state.collections;
    final allCategories = context.watch<CategoriesCubit>().state.categories;
    final allDesigns = context.watch<DesignsCubit>().state.designs;
    final categories = allCategories
        .where((c) => _collectionId == null || c.collectionId == _collectionId)
        .toList();

    // Friendly options for what the section's "View All" button opens.
    final viewAllOptions = <SelectOption>[
      const SelectOption('', 'Default (based on section type)'),
      const SelectOption('designs?sort=popularity', 'All designs · Popularity'),
      const SelectOption('designs?sort=newest', 'All designs · Newest'),
      const SelectOption(
          'designs?sort=priceAsc', 'All designs · Price: Low to High'),
      const SelectOption(
          'designs?sort=priceDesc', 'All designs · Price: High to Low'),
      const SelectOption('collections', 'All collections'),
      const SelectOption('sellers', 'All sellers'),
      ...collections
          .map((c) => SelectOption('collection:${c.id}', 'Collection · ${c.name}')),
      ...allCategories
          .map((c) => SelectOption('category:${c.id}', 'Category · ${c.name}')),
    ];

    return Dialog(
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Section',
                  style: AppTextStyles.headlineMedium(
                      color: AppTheme.primaryDark, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              AppTextField(
                  label: 'Title', hint: 'Section title', controller: _title),
              const SizedBox(height: 12),

              // How this section renders in the user app.
              _helpBanner(colorScheme),
              const SizedBox(height: 12),

              if (_isBanner) _bannerEditor(colorScheme, strings),

              // Auto vs hand-picked source toggle.
              if (_supportsManual) ...[
                _manualToggle(colorScheme),
                const SizedBox(height: 8),
              ],

              // ---- Hand-picked mode: choose exactly which items show ----
              if (_supportsManual && _manual) ...[
                if (_hasDesignFilters || _hasCollectionFilter) ...[
                  if (_type != HomeSectionType.collectionsGrid)
                    CollectionPicker(
                      collections: collections,
                      value: _collectionId,
                      label: 'Narrow choices by collection (optional)',
                      includeAll: true,
                      onChanged: (id) => setState(() {
                        _collectionId = id;
                        _categoryId = null;
                      }),
                    ),
                  if (_type != HomeSectionType.collectionsGrid)
                    const SizedBox(height: 12),
                ],
                _manualPicker(colorScheme, collections, categories, allDesigns),
                const SizedBox(height: 12),
              ],

              // ---- Auto mode: filters that drive the query ----
              if (!_manual) ...[
                if (_hasCollectionFilter) ...[
                  CollectionPicker(
                    collections: collections,
                    value: _collectionId,
                    label: strings.selectCollection,
                    includeAll: true,
                    onChanged: (id) => setState(() {
                      _collectionId = id;
                      _categoryId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_hasDesignFilters) ...[
                  CategoryPicker(
                    categories: categories,
                    value: _categoryId,
                    label: strings.selectCategory,
                    onChanged: (id) => setState(() => _categoryId = id),
                  ),
                  const SizedBox(height: 12),
                  _sortDropdown(colorScheme, strings),
                  const SizedBox(height: 12),
                ],
                if (_hasLimit) ...[
                  AppTextField(
                      label: 'Limit',
                      hint: '10',
                      controller: _limit,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                ],
              ],

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Show "View All"',
                    style: AppTextStyles.labelMedium()),
                value: _viewAllEnabled,
                activeThumbColor: AppTheme.primaryDark,
                onChanged: (v) => setState(() => _viewAllEnabled = v),
              ),
              if (_viewAllEnabled)
                SearchableSelect(
                  label: 'View All opens',
                  hint: 'Default (based on section type)',
                  value: _viewAllTarget,
                  options: viewAllOptions,
                  onSelected: (v) => setState(() => _viewAllTarget = v ?? ''),
                ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(strings.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(label: strings.save, onPressed: _save),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  /// Plain-language description of how this section type appears in the user
  /// app, so the admin understands the effect of these settings.
  String get _helpText => switch (_type) {
        HomeSectionType.banner =>
          'Shows full-width swipeable banners at the top of Home. Each banner '
              'can link to a collection or category when tapped.',
        HomeSectionType.authorisedSellersHorizontal =>
          'Shows a horizontal scrolling row of authorised sellers.',
        HomeSectionType.designsHorizontal =>
          'Shows a horizontal scrolling row of design cards. Tapping a design '
              'opens its detail page. "View All" opens the full design list.',
        HomeSectionType.designsVertical =>
          'Shows designs stacked in a vertical grid. Tapping a design opens its '
              'detail page. "View All" opens the full design list.',
        HomeSectionType.collectionsGrid =>
          'Shows a grid of collections. Tapping a collection opens its '
              'categories, then a category opens its designs. "View All" opens '
              'all collections.',
        HomeSectionType.categoriesHorizontal =>
          'Shows a horizontal row of categories. Tapping a category opens its '
              'designs. "View All" opens this collection\'s categories.',
        HomeSectionType.recentlyViewed =>
          'Shows designs the user recently opened (saved on their device).',
      };

  Widget _helpBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppTheme.primaryDark.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppTheme.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _helpText,
              style: AppTextStyles.bodySmall(color: colorScheme.onSurface),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _manualToggle(ColorScheme colorScheme) {
    final what = switch (_type) {
      HomeSectionType.collectionsGrid => 'collections',
      HomeSectionType.categoriesHorizontal => 'categories',
      _ => 'designs',
    };
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Hand-pick $what',
          style: AppTextStyles.labelMedium()),
      subtitle: Text(
        _manual
            ? 'Showing only the $what you select below, in this order.'
            : 'Auto: shows all active $what (sorted). Turn on to choose your own.',
        style: AppTextStyles.bodySmall(color: colorScheme.onSurfaceVariant),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      value: _manual,
      activeThumbColor: AppTheme.primaryDark,
      onChanged: (v) => setState(() => _manual = v),
    );
  }

  Widget _manualPicker(
    ColorScheme colorScheme,
    List<CollectionModel> collections,
    List<CategoryModel> categories,
    List<DesignModel> designs,
  ) {
    // Candidate items for the current section type: (id, name, imageUrl).
    // Only active items are offered — inactive items never show in the user
    // app, so they must not be hand-pickable here either.
    final List<({String id, String name, String? imageUrl})> candidates;
    switch (_type) {
      case HomeSectionType.collectionsGrid:
        candidates = collections
            .where((c) => c.isActive)
            .map((c) => (id: c.id, name: c.name, imageUrl: c.imageUrl))
            .toList();
      case HomeSectionType.categoriesHorizontal:
        candidates = categories
            .where((c) => c.isActive)
            .map((c) => (id: c.id, name: c.name, imageUrl: c.imageUrl))
            .toList();
      default: // designs
        candidates = designs
            .where((d) =>
                d.status == 'active' &&
                (_collectionId == null || d.collectionId == _collectionId))
            .map((d) => (id: d.id, name: d.name, imageUrl: d.firstImageUrl))
            .toList();
    }

    if (candidates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text('Nothing available to pick yet.',
            style:
                AppTextStyles.bodySmall(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_manualIds.length} selected',
            style:
                AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: candidates.length,
            itemBuilder: (context, i) {
              final c = candidates[i];
              final selected = _manualIds.contains(c.id);
              final order = _manualIds.indexOf(c.id);
              return CheckboxListTile(
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppTheme.primaryDark,
                value: selected,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    if (!_manualIds.contains(c.id)) _manualIds.add(c.id);
                  } else {
                    _manualIds.remove(c.id);
                  }
                }),
                title: Text(
                  selected ? '${order + 1}. ${c.name}' : c.name,
                  style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: AppNetworkImage(
                  imageUrl: c.imageUrl,
                  width: 36,
                  height: 36,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sortDropdown(ColorScheme colorScheme, dynamic strings) {
    const options = {
      'popularity': 'Popularity',
      'newest': 'Newest',
      'priceAsc': 'Price: Low to High',
      'priceDesc': 'Price: High to Low',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.sortBy,
          style: AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
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
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            value: options.containsKey(_sort) ? _sort : 'newest',
            dropdownColor: colorScheme.surface,
            items: options.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value,
                          style: AppTextStyles.bodyMedium(
                              color: colorScheme.onSurface)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _sort = v ?? 'newest'),
          ),
        ),
      ],
    );
  }

  Widget _bannerEditor(ColorScheme colorScheme, dynamic strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Banners',
            style:
                AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        ..._banners.asMap().entries.map((entry) {
          final i = entry.key;
          final b = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              AppNetworkImage(
                  imageUrl: b.imageUrl,
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(6)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title ?? b.label ?? 'Banner',
                        style: AppTextStyles.labelSmall(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(b.imageUrl,
                        style: AppTextStyles.bodySmall(
                            color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppLocalization.strings.edit,
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppTheme.primaryDark),
                onPressed: () => _bannerForm(existing: b, index: i),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFFF6B6B)),
                onPressed: () => setState(() => _banners.removeAt(i)),
              ),
            ]),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: strings.add,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () => _bannerForm(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Add a new banner (existing == null) or edit the one at [index].
  void _bannerForm({BannerItemConfig? existing, int? index}) {
    var imageUrl = existing?.imageUrl ?? '';
    final label = TextEditingController(text: existing?.label ?? '');
    final title = TextEditingController(text: existing?.title ?? '');
    var ctaValue = existing?.ctaTarget ?? '';
    final isEdit = existing != null && index != null;

    // Capture catalog from a context that has the providers (the nested dialog
    // is pushed on the root overlay and would not see them).
    final collections = context.read<CollectionsCubit>().state.collections;
    final categories = context.read<CategoriesCubit>().state.categories;
    final options = <SelectOption>[
      const SelectOption('', 'None (no link)'),
      ...collections.map((c) =>
          SelectOption('collection:${c.id}', 'Collection · ${c.name}  ·  ${c.id}')),
      ...categories.map((c) =>
          SelectOption('category:${c.id}', 'Category · ${c.name}  ·  ${c.id}')),
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setLocal) => AlertDialog(
          title: Text(isEdit ? 'Edit Banner' : 'Add Banner'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Same 3-way image picker (upload / URL / media library) used
                // for designs — shows a thumbnail instead of a long raw URL.
                AppImagePickerField(
                  label: 'Banner Image',
                  value: imageUrl.isEmpty ? null : imageUrl,
                  folder: 'banners',
                  onChanged: (v) => setLocal(() => imageUrl = v ?? ''),
                ),
                const SizedBox(height: 12),
                AppTextField(
                    label: 'Label', hint: 'Limited Edition', controller: label),
                const SizedBox(height: 8),
                AppTextField(
                    label: 'Title',
                    hint: 'Exclusive Collections',
                    controller: title),
                const SizedBox(height: 12),
                SearchableSelect(
                  label: 'Links to',
                  hint: 'Search a collection or category…',
                  value: ctaValue,
                  options: options,
                  onSelected: (v) => setLocal(() => ctaValue = v ?? ''),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(AppLocalization.strings.cancel)),
            TextButton(
              onPressed: () {
                final url = imageUrl.trim();
                if (url.isEmpty || Uri.tryParse(url)?.hasScheme != true) {
                  Navigator.pop(dialogCtx);
                  return;
                }
                final banner = BannerItemConfig(
                  imageUrl: url,
                  label: label.text.trim().isEmpty ? null : label.text.trim(),
                  title: title.text.trim().isEmpty ? null : title.text.trim(),
                  ctaTarget: ctaValue.trim().isEmpty ? null : ctaValue.trim(),
                );
                setState(() {
                  if (isEdit) {
                    _banners[index] = banner;
                  } else {
                    _banners.add(banner);
                  }
                });
                Navigator.pop(dialogCtx);
              },
              child: Text(isEdit
                  ? AppLocalization.strings.save
                  : AppLocalization.strings.add),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final updated = widget.section.copyWith(
      title: _title.text.trim(),
      viewAll: HomeViewAll(
        enabled: _viewAllEnabled,
        target: _viewAllTarget.trim().isEmpty ? null : _viewAllTarget.trim(),
      ),
      // Build explicitly so null collection/category (the "All" option) is
      // persisted as null rather than retaining the previous value.
      source: HomeSourceConfig(
        kind: widget.section.source.kind,
        items: _isBanner ? _banners : widget.section.source.items,
        collectionId: _collectionId,
        categoryId: _categoryId,
        sort: _sort,
        onlyActive: widget.section.source.onlyActive,
        limit:
            int.tryParse(_limit.text.trim()) ?? widget.section.source.limit,
        // Hand-pick only applies to supported section types.
        manual: _supportsManual && _manual,
        manualIds: _supportsManual && _manual ? _manualIds : const [],
      ),
    );
    context.read<HomeLayoutCubit>().editSection(updated);
    Navigator.pop(context);
  }
}
