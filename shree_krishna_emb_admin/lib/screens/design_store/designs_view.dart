import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/categories_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/designs_cubit.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_catalog_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/dialogs/design_edit_dialog.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/catalog_scaffold.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/collection_picker.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

class DesignsView extends StatefulWidget {
  const DesignsView({super.key});

  @override
  State<DesignsView> createState() => _DesignsViewState();
}

class _DesignsViewState extends State<DesignsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<DesignsCubit, DesignsState>(
      builder: (context, state) {
        final all = state.designs;
        final pageSize = state.pageSize;
        final totalPages = all.isEmpty ? 1 : (all.length / pageSize).ceil();
        final page = state.page.clamp(1, totalPages).toInt();
        final items =
            all.skip((page - 1) * pageSize).take(pageSize).toList();
        return CatalogScaffold(
          addLabel: strings.addDesign,
          onAdd: () => _openDialog(context),
          status: state.status,
          isEmpty: all.isEmpty,
          emptyText: strings.noDesigns,
          onRetry: () => context.read<DesignsCubit>().load(forceRefresh: true),
          itemCount: items.length,
          currentPage: page,
          totalPages: totalPages,
          onPageChanged: (p) => context.read<DesignsCubit>().setPage(p),
          pageSize: pageSize,
          onPageSizeChanged: (n) =>
              context.read<DesignsCubit>().setPageSize(n),
          headerLeading: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => context.read<DesignsCubit>().setSearch(v),
                style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: strings.search,
                  hintStyle: AppTextStyles.bodyMedium(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 180,
              child: _SortDropdown(
                value: state.sort,
                onChanged: (s) => context.read<DesignsCubit>().setSort(s),
              ),
            ),
            SizedBox(
              width: 200,
              child: CollectionPicker(
                collections:
                    context.watch<CollectionsCubit>().state.collections,
                value: state.collectionId,
                includeAll: true,
                onChanged: (id) =>
                    context.read<DesignsCubit>().setCollectionFilter(id),
              ),
            ),
            SizedBox(
              width: 200,
              child: CategoryPicker(
                categories: context
                    .watch<CategoriesCubit>()
                    .state
                    .categories
                    .where((c) =>
                        state.collectionId == null ||
                        c.collectionId == state.collectionId)
                    .toList(),
                value: state.categoryId,
                includeAll: true,
                onChanged: (id) =>
                    context.read<DesignsCubit>().setCategoryFilter(id),
              ),
            ),
            if (state.hasFilters)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  context.read<DesignsCubit>().clearFilters();
                },
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Clear filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryDark,
                  side: BorderSide(
                      color: AppTheme.primaryDark.withValues(alpha: 0.4)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
          ],
          itemBuilder: (context, index) {
            final d = items[index];
            final priceText = d.isFree ? strings.free : '₹${d.finalPrice}';
            final subtitle = [
              if ((d.code ?? '').isNotEmpty) d.code,
              priceText,
            ].whereType<String>().join('  •  ');
            return CatalogListRow(
              imageUrl: d.firstImageUrl,
              title: d.name,
              subtitle: subtitle,
              isActive: d.status == 'active',
              onEdit: () => _openDialog(context, design: d),
              onDelete: () => _confirmDelete(context, d),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DesignModel d) {
    final cubit = context.read<DesignsCubit>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalization.strings.delete),
        content: Text(
          '${AppLocalization.strings.confirmDeleteMessage}\n\n${d.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalization.strings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final err = await cubit.remove(d.id);
              if (context.mounted) {
                err == null
                    ? ResponsiveSnackbar.showSuccess(
                        AppLocalization.strings.deleteSuccess,
                        context,
                      )
                    : ResponsiveSnackbar.showError(err, context);
              }
            },
            child: Text(
              AppLocalization.strings.delete,
              style: const TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  void _openDialog(BuildContext context, {DesignModel? design}) {
    // Pass through the three cubits so the dialog has collections + categories
    // for its pickers and the designs cubit to save.
    showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<DesignsCubit>()),
          BlocProvider.value(value: context.read<CollectionsCubit>()),
          BlocProvider.value(value: context.read<CategoriesCubit>()),
        ],
        child: DesignEditDialog(design: design),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final DesignSort value;
  final ValueChanged<DesignSort> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    String label(DesignSort s) => switch (s) {
      DesignSort.popularity => strings.sortPopularity,
      DesignSort.newest => strings.sortNewest,
      DesignSort.priceAsc => strings.sortPriceLowHigh,
      DesignSort.priceDesc => strings.sortPriceHighLow,
    };
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DropdownButton<DesignSort>(
          value: value,
          underline: const SizedBox(),
          isDense: true,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          icon: Icon(Icons.sort, size: 18, color: colorScheme.onSurfaceVariant),
          items: DesignSort.values
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    label(s),
                    style: AppTextStyles.bodyMedium(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (s) {
            if (s != null) onChanged(s);
          },
        ),
      ),
    );
  }
}
