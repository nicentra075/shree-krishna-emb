import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/categories_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/designs_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/home_layout_cubit.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/domain/entities/home_section.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/dialogs/section_edit_dialog.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

/// Admin-facing labels for section types (config tooling).
String sectionTypeLabel(HomeSectionType type) => switch (type) {
  HomeSectionType.banner => 'Home Banner',
  HomeSectionType.authorisedSellersHorizontal => 'Authorised Sellers (row)',
  HomeSectionType.designsHorizontal => 'Designs (horizontal)',
  HomeSectionType.designsVertical => 'Designs (vertical)',
  HomeSectionType.collectionsGrid => 'Collections (grid)',
  HomeSectionType.categoriesHorizontal => 'Categories (row)',
  HomeSectionType.recentlyViewed => 'Recently Viewed',
};

/// Icon shown next to each section type in the "Add Section" picker.
IconData sectionTypeIcon(HomeSectionType type) => switch (type) {
  HomeSectionType.banner => Icons.view_carousel_outlined,
  HomeSectionType.authorisedSellersHorizontal => Icons.storefront_outlined,
  HomeSectionType.designsHorizontal => Icons.view_array_outlined,
  HomeSectionType.designsVertical => Icons.grid_view_outlined,
  HomeSectionType.collectionsGrid => Icons.collections_outlined,
  HomeSectionType.categoriesHorizontal => Icons.category_outlined,
  HomeSectionType.recentlyViewed => Icons.history,
};

/// Short helper text describing what each section type renders on Home.
String sectionTypeDescription(HomeSectionType type) => switch (type) {
  HomeSectionType.banner => 'Full-width swipeable promo banners',
  HomeSectionType.authorisedSellersHorizontal =>
    'Scrolling row of authorised sellers',
  HomeSectionType.designsHorizontal => 'Scrolling row of designs',
  HomeSectionType.designsVertical => 'Stacked grid of designs',
  HomeSectionType.collectionsGrid => 'Grid of collections',
  HomeSectionType.categoriesHorizontal => 'Scrolling row of categories',
  HomeSectionType.recentlyViewed => "Designs the user recently opened",
};

class HomeLayoutView extends StatelessWidget {
  const HomeLayoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<HomeLayoutCubit>()..load(),
      child: const _HomeLayoutBody(),
    );
  }
}

class _HomeLayoutBody extends StatelessWidget {
  const _HomeLayoutBody();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<HomeLayoutCubit, HomeLayoutState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          strings.homeLayout,
                          style: AppTextStyles.labelMedium(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Live vs. unpublished status chip.
                        _StatusChip(dirty: state.dirty),
                      ],
                    ),
                  ),
                  AppButton(
                    label: strings.addSection,
                    leadingIcon: Icons.add,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _addSection(context),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: strings.publish,
                    leadingIcon: Icons.publish_outlined,
                    isLoading: state.saving,
                    onPressed: state.dirty ? () => _save(context) : () {},
                  ),
                ],
              ),
            ),
            // Persistent banner reminding the admin to publish.
            if (state.dirty) _UnpublishedBanner(onPublish: () => _save(context)),
            Expanded(child: _body(context, state, colorScheme)),
          ],
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    HomeLayoutState state,
    ColorScheme colorScheme,
  ) {
    if (state.status == HomeLayoutStatus.loading ||
        state.status == HomeLayoutStatus.initial) {
      return const Center(child: AppLoader());
    }
    if (state.status == HomeLayoutStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.error ?? AppLocalization.strings.error,
              style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: AppLocalization.strings.retry,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.read<HomeLayoutCubit>().load(),
            ),
          ],
        ),
      );
    }
    final sections = state.sections;
    // Captured from a context that has the providers; the dragged item is
    // rendered in an Overlay outside this tree, so re-provide them via
    // proxyDecorator.
    final layoutCubit = context.read<HomeLayoutCubit>();
    final collectionsCubit = context.read<CollectionsCubit>();
    final categoriesCubit = context.read<CategoriesCubit>();
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: sections.length,
      onReorder: layoutCubit.reorder,
      // We render our own drag handle on the left; hide the default right one.
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: layoutCubit),
          BlocProvider.value(value: collectionsCubit),
          BlocProvider.value(value: categoriesCubit),
        ],
        child: Material(color: Colors.transparent, child: child),
      ),
      itemBuilder: (context, index) {
        final s = sections[index];
        return _SectionCard(key: ValueKey(s.id), index: index, section: s);
      },
    );
  }

  void _addSection(BuildContext context) {
    final cubit = context.read<HomeLayoutCubit>();
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.addSection,
                            style: AppTextStyles.headlineMedium(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.addSectionSubtitle,
                            style: AppTextStyles.bodySmall(
                                color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: strings.cancel,
                      icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: HomeSectionType.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final t = HomeSectionType.values[index];
                    return _SectionTypeOption(
                      type: t,
                      onTap: () {
                        cubit.addSection(t);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final err = await context.read<HomeLayoutCubit>().save();
    if (!context.mounted) return;
    err == null
        ? ResponsiveSnackbar.showSuccess(
            AppLocalization.strings.success,
            context,
          )
        : ResponsiveSnackbar.showError(err, context);
  }
}

/// Small pill showing whether the layout is live or has unpublished edits.
class _StatusChip extends StatelessWidget {
  final bool dirty;
  const _StatusChip({required this.dirty});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    const liveColor = Color(0xFF4CAF50);
    const dirtyColor = Color(0xFFE6A23C);
    final color = dirty ? dirtyColor : liveColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(dirty ? Icons.edit_note : Icons.check_circle,
              size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            dirty ? strings.unpublishedChanges : strings.published,
            style: AppTextStyles.labelSmall(
                color: color, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Full-width banner reminding the admin that edits are not yet live.
class _UnpublishedBanner extends StatelessWidget {
  final VoidCallback onPublish;
  const _UnpublishedBanner({required this.onPublish});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    const accent = Color(0xFFE6A23C);
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.unpublishedBannerMessage,
              style: AppTextStyles.bodySmall(
                  color: Theme.of(context).colorScheme.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onPublish,
            child: Text(
              strings.publishNow,
              style: AppTextStyles.labelMedium(
                  color: AppTheme.primaryDark, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// A selectable row in the "Add Section" dialog: icon + label + description.
class _SectionTypeOption extends StatelessWidget {
  final HomeSectionType type;
  final VoidCallback onTap;
  const _SectionTypeOption({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(sectionTypeIcon(type),
                    size: 20, color: AppTheme.primaryDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTypeLabel(type),
                      style: AppTextStyles.labelMedium(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sectionTypeDescription(type),
                      style: AppTextStyles.bodySmall(
                          color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add_circle_outline,
                  size: 20, color: AppTheme.primaryDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  final int index;
  final HomeSectionConfig section;

  const _SectionCard({super.key, required this.index, required this.section});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;

  HomeSectionConfig get section => widget.section;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cubit = context.read<HomeLayoutCubit>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: Icon(Icons.drag_handle,
                    color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              // Tap the title area to expand/collapse (view the binding).
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title?.isNotEmpty == true
                            ? section.title!
                            : sectionTypeLabel(section.type),
                        style: AppTextStyles.labelMedium(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _summaryLine(context),
                        style: AppTextStyles.bodySmall(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: _expanded ? 'Hide details' : 'View details',
                icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
              Switch(
                value: section.enabled,
                activeThumbColor: AppTheme.primaryDark,
                onChanged: (_) => cubit.toggleSection(section.id),
              ),
              IconButton(
                tooltip: AppLocalization.strings.edit,
                icon: Icon(Icons.edit_outlined,
                    size: 20, color: AppTheme.primaryDark),
                onPressed: () => _edit(context),
              ),
              IconButton(
                tooltip: AppLocalization.strings.delete,
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: Color(0xFFFF6B6B)),
                onPressed: () => cubit.removeSection(section.id),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _detailsPanel(context, colorScheme),
          ),
        ],
      ),
    );
  }

  /// One-line summary shown under the title (collapsed state).
  String _summaryLine(BuildContext context) {
    final type = sectionTypeLabel(section.type);
    final s = section.source;
    switch (section.type) {
      case HomeSectionType.banner:
        return '$type · ${s.items.length} banner(s)';
      case HomeSectionType.authorisedSellersHorizontal:
        return '$type · limit ${s.limit}';
      case HomeSectionType.collectionsGrid:
        return '$type · limit ${s.limit}';
      case HomeSectionType.recentlyViewed:
        return '$type · limit ${s.limit}';
      case HomeSectionType.categoriesHorizontal:
        return '$type · ${_collectionName(context, s.collectionId)} · limit ${s.limit}';
      case HomeSectionType.designsHorizontal:
      case HomeSectionType.designsVertical:
        return '$type · ${_sortLabel(s.sort)} · limit ${s.limit}';
    }
  }

  Widget _detailsPanel(BuildContext context, ColorScheme colorScheme) {
    final rows = _detailRows(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 8, 8, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(r.$1,
                          style: AppTextStyles.labelSmall(
                              color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: Text(r.$2,
                          style: AppTextStyles.bodySmall(
                              color: colorScheme.onSurface),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            AppButton(
              label: 'Edit this section',
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              leadingIcon: Icons.tune,
              onPressed: () => _edit(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Detailed label/value rows describing exactly what the section pulls.
  List<(String, String)> _detailRows(BuildContext context) {
    final s = section.source;
    final rows = <(String, String)>[
      ('Content type', sectionTypeLabel(section.type)),
    ];
    switch (section.type) {
      case HomeSectionType.banner:
        rows.add(('Banners', '${s.items.length}'));
        for (var i = 0; i < s.items.length; i++) {
          final b = s.items[i];
          rows.add(('• Banner ${i + 1}', b.title ?? b.label ?? b.imageUrl));
        }
        break;
      case HomeSectionType.authorisedSellersHorizontal:
        rows.add(('Shows', 'Authorised seller designers'));
        rows.add(('Limit', '${s.limit}'));
        break;
      case HomeSectionType.designsHorizontal:
      case HomeSectionType.designsVertical:
        if (s.manual) {
          rows.add(('Shows', '${s.manualIds.length} hand-picked designs'));
        } else {
          rows.add(('Shows', 'Active designs'));
          rows.add(('Collection', _collectionName(context, s.collectionId)));
          rows.add(('Category', _categoryName(context, s.categoryId)));
          rows.add(('Sort', _sortLabel(s.sort)));
          rows.add(('Limit', '${s.limit}'));
        }
        break;
      case HomeSectionType.collectionsGrid:
        if (s.manual) {
          rows.add(('Shows', '${s.manualIds.length} hand-picked collections'));
        } else {
          rows.add(('Shows', 'Active collections'));
          rows.add(('Limit', '${s.limit}'));
        }
        break;
      case HomeSectionType.categoriesHorizontal:
        if (s.manual) {
          rows.add(('Shows', '${s.manualIds.length} hand-picked categories'));
        } else {
          rows.add(('Shows', 'Active categories'));
          rows.add(('Collection', _collectionName(context, s.collectionId)));
          rows.add(('Limit', '${s.limit}'));
        }
        break;
      case HomeSectionType.recentlyViewed:
        rows.add(('Shows', "Each user's recently viewed designs"));
        rows.add(('Limit', '${s.limit}'));
        break;
    }
    rows.add((
      'View All',
      section.viewAll.enabled
          ? 'On → ${section.viewAll.target ?? '(default)'}'
          : 'Off',
    ));
    return rows;
  }

  String _collectionName(BuildContext context, String? id) {
    if (id == null || id.isEmpty) return 'All collections';
    final list = context.read<CollectionsCubit>().state.collections;
    final match = list.where((c) => c.id == id);
    return match.isEmpty ? id : match.first.name;
  }

  String _categoryName(BuildContext context, String? id) {
    if (id == null || id.isEmpty) return 'All categories';
    final list = context.read<CategoriesCubit>().state.categories;
    final match = list.where((c) => c.id == id);
    return match.isEmpty ? id : match.first.name;
  }

  String _sortLabel(String sort) => switch (sort) {
        'popularity' => 'Popularity',
        'priceAsc' => 'Price: low → high',
        'priceDesc' => 'Price: high → low',
        _ => 'Newest',
      };

  void _edit(BuildContext context) {
    final layoutCubit = context.read<HomeLayoutCubit>();
    final collectionsCubit = context.read<CollectionsCubit>();
    final categoriesCubit = context.read<CategoriesCubit>();
    final designsCubit = context.read<DesignsCubit>();
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: layoutCubit),
          BlocProvider.value(value: collectionsCubit),
          BlocProvider.value(value: categoriesCubit),
          BlocProvider.value(value: designsCubit),
        ],
        child: SectionEditDialog(section: section),
      ),
    );
  }
}
