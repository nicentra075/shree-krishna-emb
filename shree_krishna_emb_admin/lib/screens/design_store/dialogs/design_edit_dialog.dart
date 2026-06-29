import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/categories_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/designs_cubit.dart';
import 'package:shree_krishna_emb_admin/core/di/service_locator.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/data/models/category_model.dart';
import 'package:shree_krishna_emb_admin/data/models/collection_model.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';
import 'package:shree_krishna_emb_admin/domain/entities/design.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/user_list_repository.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/collection_picker.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/design_file_field.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/image_picker_field.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/searchable_select.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

class DesignEditDialog extends StatefulWidget {
  final DesignModel? design;
  const DesignEditDialog({super.key, this.design});

  @override
  State<DesignEditDialog> createState() => _DesignEditDialogState();
}

class _DesignEditDialogState extends State<DesignEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _author;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _color;
  late final TextEditingController _stitch;
  late final TextEditingController _height;
  late final TextEditingController _width;

  late List<String> _images;
  late List<String> _designFormats;
  late List<DesignFileRef> _designFiles;
  String? _collectionId;
  String? _categoryId;
  late bool _isFree;
  late String _status;

  // Author = a designer or admin (uid). Defaults to the current admin.
  String? _authorId;
  List<({String uid, String name, String role})> _authors = const [];

  static const _statuses = ['active', 'inactive'];

  @override
  void initState() {
    super.initState();
    final d = widget.design;
    _name = TextEditingController(text: d?.name ?? '');
    _code = TextEditingController(text: d?.code ?? '');
    _author = TextEditingController(text: d?.authorName ?? '');
    _description = TextEditingController(text: d?.description ?? '');
    _price = TextEditingController(text: (d?.price ?? 0).toString());
    _discount = TextEditingController(
      text: (d?.discountAmount ?? 0).toString(),
    );
    _color = TextEditingController(text: d?.colorOrNeedleCount ?? '');
    _stitch = TextEditingController(text: (d?.stitchCount ?? 0).toString());
    _height = TextEditingController(text: (d?.height ?? 0).toString());
    _width = TextEditingController(text: (d?.width ?? 0).toString());
    _images = List<String>.from(d?.images ?? const []);
    _designFormats = List<String>.from(d?.designFormats ?? const []);
    _designFiles = List<DesignFileRef>.from(d?.designFiles ?? const []);
    _collectionId = d?.collectionId;
    _categoryId = d?.categoryId;
    _isFree = d?.isFree ?? false;
    // Coerce any legacy/unknown status (e.g. 'pending') to 'active' so the
    // dropdown — which now only offers active/inactive — has a valid value.
    _status = _statuses.contains(d?.status) ? d!.status : 'active';
    _price.addListener(_refresh);
    _discount.addListener(_refresh);

    // Default author = current admin (for new designs) or the design's author.
    final auth = getIt<AdminAuthBloc>().state;
    if (d != null) {
      _authorId = d.authorId;
      if ((d.authorName ?? '').isEmpty && auth is AdminAuthAuthenticated) {
        _author.text = auth.name;
      }
    } else if (auth is AdminAuthAuthenticated) {
      _authorId = auth.adminId;
      _author.text = auth.name;
    }
    _loadAuthors();
  }

  /// Loads designers + admins to choose the author from.
  Future<void> _loadAuthors() async {
    final result = await getIt<UserListRepository>().getUsers(
      page: 1,
      pageSize: 500,
    );
    final list = result.fold(
      (_) => <({String uid, String name, String role})>[],
      (users) => users
          .where((u) => u.role == 'designer' || u.role == 'admin')
          .map((u) => (uid: u.id, name: u.name, role: u.role))
          .toList(),
    );
    // Make sure the current selection is always present (e.g. 'platform',
    // or the current admin even before the list resolves).
    if (_authorId != null && !list.any((a) => a.uid == _authorId)) {
      list.insert(0, (
        uid: _authorId!,
        name: _author.text.isEmpty ? 'Current user' : _author.text,
        role: _authorId == 'platform' ? 'platform' : 'admin',
      ));
    }
    if (mounted) setState(() => _authors = list);
  }

  void _refresh() => setState(() {});

  Widget _authorPicker(dynamic strings) {
    final options = _authors
        .map(
          (a) => SelectOption(
            a.uid,
            a.role == 'designer' ? '${a.name} (designer)' : '${a.name} (admin)',
          ),
        )
        .toList();
    return SearchableSelect(
      label: strings.authorName,
      hint: strings.authorName,
      value: _authorId,
      options: options,
      onSelected: (uid) {
        if (uid == null) return;
        final match = _authors.where((a) => a.uid == uid);
        setState(() {
          _authorId = uid;
          if (match.isNotEmpty) _author.text = match.first.name;
        });
      },
    );
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _code,
      _author,
      _description,
      _price,
      _discount,
      _color,
      _stitch,
      _height,
      _width,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _finalPrice => DesignEntity.computeFinalPrice(
    isFree: _isFree,
    price: int.tryParse(_price.text.trim()) ?? 0,
    discountAmount: int.tryParse(_discount.text.trim()) ?? 0,
  );

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final isCreate = widget.design == null;
    final collections = context.watch<CollectionsCubit>().state.collections;
    final allCategories = context.watch<CategoriesCubit>().state.categories;
    final categories = allCategories
        .where((c) => c.collectionId == _collectionId)
        .toList();

    final screenSize = MediaQuery.of(context).size;
    // Widen on desktop; clamp to the available screen width with margins.
    final dialogWidth = screenSize.width < 740
        ? screenSize.width - 32
        : (screenSize.width - 80).clamp(560.0, 820.0).toDouble();
    final maxHeight = screenSize.height * 0.85;

    return Dialog(
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCreate ? strings.addDesign : strings.editDesign,
              style: AppTextStyles.headlineMedium(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumn = constraints.maxWidth >= 700;
                    final left = _leftColumn(strings, colorScheme);
                    final right = _rightColumn(
                      strings,
                      colorScheme,
                      collections,
                      categories,
                    );
                    if (twoColumn) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(children: left)),
                          const SizedBox(width: 24),
                          Expanded(child: Column(children: right)),
                        ],
                      );
                    }
                    return Column(children: [...left, ...right]);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
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
    );
  }

  /// Left column: images, name, code + author, description.
  List<Widget> _leftColumn(dynamic strings, ColorScheme colorScheme) {
    return [
      // Images — upload / pick from library / manual
      AppMultiImagePicker(
        label: strings.designImages,
        values: _images,
        folder: 'designs',
        onChanged: (v) => setState(() => _images = v),
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: strings.designName,
        hint: strings.designName,
        controller: _name,
      ),
      const SizedBox(height: 16),
      // Code + Author — both use an external label above the field (matching
      // SearchableSelect) so the two columns line up cleanly at the top.
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.code,
                  style: AppTextStyles.labelSmall(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                AppTextField(hint: 'ABC-001', controller: _code),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _authorPicker(strings)),
        ],
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: strings.descriptionLabel,
        hint: strings.descriptionLabel,
        controller: _description,
        maxLines: 3,
      ),
    ];
  }

  /// Right column: collection → category, pricing, formats + files, specs,
  /// status.
  List<Widget> _rightColumn(
    dynamic strings,
    ColorScheme colorScheme,
    List<CollectionModel> collections,
    List<CategoryModel> categories,
  ) {
    return [
      // Collection -> Category
      CollectionPicker(
        collections: collections,
        value: _collectionId,
        label: strings.selectCollection,
        onChanged: (id) => setState(() {
          _collectionId = id;
          _categoryId = null; // reset dependent category
        }),
      ),
      const SizedBox(height: 16),
      CategoryPicker(
        categories: categories,
        value: _categoryId,
        label: strings.selectCategory,
        onChanged: (id) => setState(() => _categoryId = id),
      ),
      const SizedBox(height: 8),
      // Pricing
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          strings.isFree,
          style: AppTextStyles.labelMedium(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        value: _isFree,
        activeThumbColor: AppTheme.primaryDark,
        onChanged: (v) => setState(() => _isFree = v),
      ),
      if (!_isFree) ...[
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: strings.price,
                hint: '0',
                controller: _price,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: strings.discountAmount,
                hint: '0',
                controller: _discount,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${strings.finalPrice}: ',
              style: AppTextStyles.labelMedium(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '₹$_finalPrice',
              style: AppTextStyles.labelMedium(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      // Specs
      AppTextField(
        label: strings.colorOrNeedleCount,
        hint: '9 needle',
        controller: _color,
      ),
      const SizedBox(height: 16),
      // Design formats (multi-select) + a downloadable source file per
      // selected format (DST / EMB / DHE).
      DesignFilesField(
        formats: _designFormats,
        files: _designFiles,
        onFormatsChanged: (v) => setState(() => _designFormats = v),
        onFilesChanged: (v) => setState(() => _designFiles = v),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: AppTextField(
              label: strings.stitchCount,
              hint: '0',
              controller: _stitch,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              label: strings.heightLabel,
              hint: '0',
              controller: _height,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTextField(
              label: strings.widthLabel,
              hint: '0',
              controller: _width,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      // Status
      _statusDropdown(colorScheme, strings),
    ];
  }

  Widget _statusDropdown(ColorScheme colorScheme, dynamic strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.statusLabel,
          style: AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            value: _status,
            dropdownColor: colorScheme.surface,
            items: _statuses
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      s.replaceFirst(s[0], s[0].toUpperCase()),
                      style: AppTextStyles.bodyMedium(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (s) => setState(() => _status = s ?? 'active'),
          ),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, bool isCreate) async {
    final strings = AppLocalization.strings;
    if (_name.text.trim().isEmpty) {
      ResponsiveSnackbar.showError(strings.designName, context);
      return;
    }
    if (_collectionId == null) {
      ResponsiveSnackbar.showError(strings.selectCollection, context);
      return;
    }
    final cubit = context.read<DesignsCubit>();
    final existing = widget.design;
    final model = DesignModel(
      id: existing?.id ?? 'new',
      name: _name.text.trim(),
      code: _code.text.trim().isEmpty ? null : _code.text.trim(),
      images: _images,
      authorId: _authorId ?? existing?.authorId ?? 'platform',
      authorName: _author.text.trim().isEmpty ? null : _author.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      price: _isFree ? 0 : (int.tryParse(_price.text.trim()) ?? 0),
      discountAmount: _isFree ? 0 : (int.tryParse(_discount.text.trim()) ?? 0),
      isFree: _isFree,
      finalPrice: _finalPrice,
      colorOrNeedleCount: _color.text.trim().isEmpty
          ? null
          : _color.text.trim(),
      designFormat: _designFormats.isEmpty ? null : _designFormats.join(', '),
      designFormats: _designFormats,
      designFiles: _designFiles,
      stitchCount: int.tryParse(_stitch.text.trim()) ?? 0,
      height: int.tryParse(_height.text.trim()) ?? 0,
      width: int.tryParse(_width.text.trim()) ?? 0,
      collectionId: _collectionId,
      categoryId: _categoryId,
      status: _status,
      popularity: existing?.popularity ?? 0,
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
