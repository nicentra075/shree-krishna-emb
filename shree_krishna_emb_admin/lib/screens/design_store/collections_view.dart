import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/data/models/collection_model.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/cascade_delete_dialog.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/catalog_scaffold.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/image_picker_field.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

class CollectionsView extends StatelessWidget {
  const CollectionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return BlocBuilder<CollectionsCubit, CollectionsState>(
      builder: (context, state) {
        final all = state.collections;
        final pageSize = state.pageSize;
        final totalPages = all.isEmpty ? 1 : (all.length / pageSize).ceil();
        final page = state.page.clamp(1, totalPages).toInt();
        final items =
            all.skip((page - 1) * pageSize).take(pageSize).toList();
        return CatalogScaffold(
          addLabel: strings.addCollection,
          onAdd: () => _openDialog(context),
          status: state.status,
          isEmpty: all.isEmpty,
          emptyText: strings.noCollections,
          onRetry: () => context.read<CollectionsCubit>().load(forceRefresh: true),
          itemCount: items.length,
          currentPage: page,
          totalPages: totalPages,
          onPageChanged: (p) => context.read<CollectionsCubit>().setPage(p),
          pageSize: pageSize,
          onPageSizeChanged: (n) =>
              context.read<CollectionsCubit>().setPageSize(n),
          itemBuilder: (context, index) {
            final c = items[index];
            return CatalogListRow(
              imageUrl: c.imageUrl,
              title: c.name,
              subtitle: 'ID: ${c.id}',
              isActive: c.isActive,
              onEdit: () => _openDialog(context, collection: c),
              onDelete: () => _confirmDelete(context, c),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, CollectionModel c) async {
    final strings = AppLocalization.strings;
    final cubit = context.read<CollectionsCubit>();
    // Look up how many categories/designs hang off this collection.
    final counts = await cubit.childCounts(c.id);
    if (!context.mounted) return;
    final hasChildren = counts.categories > 0 || counts.designs > 0;
    final summary = hasChildren
        ? '${counts.categories} ${strings.categories} · '
            '${counts.designs} ${strings.designs}'
        : null;

    final result = await showCascadeDeleteDialog(
      context: context,
      itemName: c.name,
      childSummary: summary,
      cascadeOptionLabel: strings.alsoDeleteCategoriesDesigns,
      onlyNote: strings.deleteCollectionOnlyNote,
      cascadeNote: strings.deleteCollectionCascadeNote,
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

  void _openDialog(BuildContext context, {CollectionModel? collection}) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CollectionsCubit>(),
        child: _CollectionEditDialog(collection: collection),
      ),
    );
  }
}

class _CollectionEditDialog extends StatefulWidget {
  final CollectionModel? collection;
  const _CollectionEditDialog({this.collection});

  @override
  State<_CollectionEditDialog> createState() => _CollectionEditDialogState();
}

class _CollectionEditDialogState extends State<_CollectionEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _imageUrl;
  late final TextEditingController _position;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final c = widget.collection;
    _name = TextEditingController(text: c?.name ?? '');
    _description = TextEditingController(text: c?.description ?? '');
    _imageUrl = c?.imageUrl ?? '';
    _position = TextEditingController(text: (c?.position ?? 0).toString());
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final isCreate = widget.collection == null;

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
                isCreate ? strings.addCollection : strings.editCollection,
                style: AppTextStyles.headlineMedium(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                  label: strings.collectionName,
                  hint: strings.collectionName,
                  controller: _name),
              const SizedBox(height: 12),
              AppTextField(
                  label: strings.descriptionLabel,
                  hint: strings.descriptionLabel,
                  controller: _description,
                  maxLines: 3),
              const SizedBox(height: 12),
              AppImagePickerField(
                label: strings.imageUrl,
                value: _imageUrl,
                folder: 'collections',
                onChanged: (v) => setState(() => _imageUrl = v ?? ''),
              ),
              const SizedBox(height: 12),
              AppTextField(
                  label: strings.positionLabel,
                  hint: '0',
                  controller: _position,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.isActiveLabel,
                    style: AppTextStyles.labelMedium()),
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
    if (_name.text.trim().isEmpty) {
      ResponsiveSnackbar.showError(strings.collectionName, context);
      return;
    }
    final url = _imageUrl.trim();
    if (url.isNotEmpty && Uri.tryParse(url)?.hasScheme != true) {
      ResponsiveSnackbar.showError(strings.imageUrl, context);
      return;
    }
    final cubit = context.read<CollectionsCubit>();
    final existing = widget.collection;
    final model = CollectionModel(
      id: existing?.id ?? 'new',
      name: _name.text.trim(),
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      imageUrl: url.isEmpty ? null : url,
      isActive: _isActive,
      position: int.tryParse(_position.text.trim()) ?? 0,
      ownerId: existing?.ownerId ?? 'platform',
      ownerType: existing?.ownerType ?? 'platform',
      designCount: existing?.designCount ?? 0,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    final err =
        isCreate ? await cubit.create(model) : await cubit.update(model);
    if (!context.mounted) return;
    Navigator.pop(context);
    err == null
        ? ResponsiveSnackbar.showSuccess(strings.success, context)
        : ResponsiveSnackbar.showError(err, context);
  }
}
