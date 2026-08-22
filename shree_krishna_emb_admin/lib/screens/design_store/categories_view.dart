import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/categories_cubit.dart';
import 'package:shree_krishna_emb_admin/core/auth/access_policy.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/data/models/category_model.dart';
import 'package:shree_krishna_emb_admin/data/models/collection_model.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/cascade_delete_dialog.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/catalog_scaffold.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/image_picker_field.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/collection_picker.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final collections = context.watch<CollectionsCubit>().state.collections;
        final all = state.visibleCategories;
        final pageSize = state.pageSize;
        final totalPages = all.isEmpty ? 1 : (all.length / pageSize).ceil();
        final page = state.page.clamp(1, totalPages).toInt();
        final items = all.skip((page - 1) * pageSize).take(pageSize).toList();
        return CatalogScaffold(
          addLabel: strings.addCategory,
          onAdd: collections.isEmpty
              ? () =>
                    ResponsiveSnackbar.showError(strings.noCollections, context)
              : () => _openDialog(context, collections),
          status: state.status,
          isEmpty: all.isEmpty,
          emptyText: strings.noCategories,
          onRetry: () => context.read<CategoriesCubit>().load(
            collectionId: state.collectionId,
            forceRefresh: true,
          ),
          itemCount: items.length,
          currentPage: page,
          totalPages: totalPages,
          onPageChanged: (p) => context.read<CategoriesCubit>().setPage(p),
          pageSize: pageSize,
          onPageSizeChanged: (n) =>
              context.read<CategoriesCubit>().setPageSize(n),
          headerLeading: [
            SizedBox(
              width: 240,
              child: CollectionPicker(
                collections: collections,
                value: state.collectionId,
                includeAll: true,
                onChanged: (id) =>
                    context.read<CategoriesCubit>().load(collectionId: id),
              ),
            ),
            SizedBox(
              width: 180,
              child: _StatusFilterDropdown(
                value: state.statusFilter,
                onChanged: (f) =>
                    context.read<CategoriesCubit>().setStatusFilter(f),
              ),
            ),
          ],
          itemBuilder: (context, index) {
            final c = items[index];
            final collectionName = collections
                .where((col) => col.id == c.collectionId)
                .map((col) => col.name)
                .join();
            // Designers can add categories but not mutate the shared
            // taxonomy (D2 — rules enforce this server-side too).
            final canMutate = currentAccessPolicy().canMutateTaxonomy;
            return CatalogListRow(
              imageUrl: c.imageUrl,
              title: c.name,
              subtitle: collectionName.isEmpty
                  ? 'ID: ${c.id}'
                  : '$collectionName · ID: ${c.id}',
              isActive: c.isActive,
              onEdit: canMutate
                  ? () => _openDialog(context, collections, category: c)
                  : null,
              onDelete: canMutate ? () => _confirmDelete(context, c) : null,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, CategoryModel c) async {
    final strings = AppLocalization.strings;
    final cubit = context.read<CategoriesCubit>();
    final designs = await cubit.designCount(c.id);
    if (!context.mounted) return;
    final summary = designs > 0 ? '$designs ${strings.designs}' : null;

    final result = await showCascadeDeleteDialog(
      context: context,
      itemName: c.name,
      childSummary: summary,
      cascadeOptionLabel: strings.alsoDeleteDesigns,
      onlyNote: strings.deleteCategoryOnlyNote,
      cascadeNote: strings.deleteCategoryCascadeNote,
    );
    if (result == null || result == CascadeDeleteResult.cancel) return;

    final err = result == CascadeDeleteResult.cascade
        ? await cubit.removeCascade(c.id)
        : await cubit.remove(c.id);
    if (!context.mounted) return;
    err == null
        ? ResponsiveSnackbar.showSuccess(strings.deleteSuccess, context)
        : ResponsiveSnackbar.showError(err, context);
  }

  void _openDialog(
    BuildContext context,
    List<CollectionModel> collections, {
    CategoryModel? category,
  }) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoriesCubit>(),
        child: _CategoryEditDialog(
          category: category,
          collections: collections,
        ),
      ),
    );
  }
}

/// Active / inactive / all status filter for the categories list.
class _StatusFilterDropdown extends StatelessWidget {
  final CatalogStatusFilter value;
  final ValueChanged<CatalogStatusFilter> onChanged;
  const _StatusFilterDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    String label(CatalogStatusFilter f) => switch (f) {
      CatalogStatusFilter.all => strings.allLabel,
      CatalogStatusFilter.active => strings.active,
      CatalogStatusFilter.inactive => strings.inactive,
    };
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DropdownButton<CatalogStatusFilter>(
          value: value,
          underline: const SizedBox(),
          isDense: true,
          isExpanded: true,
          dropdownColor: colorScheme.surface,
          icon: Icon(
            Icons.filter_list,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          items: CatalogStatusFilter.values
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(
                    '${strings.statusLabel}: ${label(f)}',
                    style: AppTextStyles.bodyMedium(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (f) {
            if (f != null) onChanged(f);
          },
        ),
      ),
    );
  }
}

class _CategoryEditDialog extends StatefulWidget {
  final CategoryModel? category;
  final List<CollectionModel> collections;
  const _CategoryEditDialog({this.category, required this.collections});

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  late final TextEditingController _name;
  late String _imageUrl;
  late final TextEditingController _position;
  String? _collectionId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _imageUrl = c?.imageUrl ?? '';
    _position = TextEditingController(text: (c?.position ?? 0).toString());
    _collectionId =
        c?.collectionId ??
        (widget.collections.isNotEmpty ? widget.collections.first.id : null);
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final isCreate = widget.category == null;

    return Dialog(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCreate ? strings.addCategory : strings.editCategory,
                style: AppTextStyles.headlineMedium(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              CollectionPicker(
                collections: widget.collections,
                value: _collectionId,
                label: strings.selectCollection,
                onChanged: (id) => setState(() => _collectionId = id),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: strings.categoryName,
                hint: strings.categoryName,
                controller: _name,
              ),
              const SizedBox(height: 12),
              AppImagePickerField(
                label: strings.imageUrl,
                value: _imageUrl,
                folder: 'categories',
                onChanged: (v) => setState(() => _imageUrl = v ?? ''),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: strings.positionLabel,
                hint: '0',
                controller: _position,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  strings.isActiveLabel,
                  style: AppTextStyles.labelMedium(),
                ),
                value: _isActive,
                activeThumbColor: AppTheme.primaryDark,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(strings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: isCreate ? strings.create : strings.save,
                      onPressed: () => _save(context, isCreate),
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

  Future<void> _save(BuildContext context, bool isCreate) async {
    final strings = AppLocalization.strings;
    if (_collectionId == null || _collectionId!.isEmpty) {
      ResponsiveSnackbar.showError(strings.selectCollection, context);
      return;
    }
    if (_name.text.trim().isEmpty) {
      ResponsiveSnackbar.showError(strings.categoryName, context);
      return;
    }
    final url = _imageUrl.trim();
    if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme != true) {
      ResponsiveSnackbar.showError(strings.imageUrl, context);
      return;
    }
    final cubit = context.read<CategoriesCubit>();
    final existing = widget.category;
    final model = CategoryModel(
      id: existing?.id ?? 'new',
      collectionId: _collectionId!,
      name: _name.text.trim(),
      imageUrl: url.isEmpty ? null : url,
      isActive: _isActive,
      position: int.tryParse(_position.text.trim()) ?? 0,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    final err = isCreate
        ? await cubit.create(model)
        : await cubit.update(model);
    if (!context.mounted) return;
    Navigator.pop(context);
    err == null
        ? ResponsiveSnackbar.showSuccess(strings.success, context)
        : ResponsiveSnackbar.showError(err, context);
  }
}
