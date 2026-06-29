import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/media/design_file_library_cubit.dart';
import 'package:shree_krishna_emb_admin/data/models/design_file_asset_model.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/upload_zone_dialog.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

/// Per-page options for the Design File Library list.
const List<int> _kFilePageSizes = [12, 24, 48];

/// Opens the Design File Library. In [pickMode] it returns the chosen
/// asset(s); with [multiSelect] the user can tick several and confirm. Returns
/// null when cancelled.
Future<List<DesignFileAssetModel>?> showDesignFileLibrary(
  BuildContext context, {
  bool pickMode = false,
  bool multiSelect = false,
}) {
  return showDialog<List<DesignFileAssetModel>>(
    context: context,
    builder: (_) => BlocProvider<DesignFileLibraryCubit>(
      create: (_) => GetIt.instance<DesignFileLibraryCubit>()..load(),
      child: _DesignFileLibraryDialog(
        pickMode: pickMode,
        multiSelect: multiSelect,
      ),
    ),
  );
}

class _DesignFileLibraryDialog extends StatefulWidget {
  final bool pickMode;
  final bool multiSelect;
  const _DesignFileLibraryDialog({
    required this.pickMode,
    required this.multiSelect,
  });

  @override
  State<_DesignFileLibraryDialog> createState() =>
      _DesignFileLibraryDialogState();
}

class _DesignFileLibraryDialogState extends State<_DesignFileLibraryDialog> {
  bool _dragging = false;
  int _page = 1;
  int _pageSize = 12;
  final Set<String> _selected = {}; // selected asset ids (multi-select)

  Future<void> _uploadFiles(List<dynamic> files) async {
    final uploads = <PendingFileUpload>[];
    for (final f in files) {
      uploads.add(
        PendingFileUpload(bytes: await f.readAsBytes(), filename: f.name),
      );
    }
    if (!mounted || uploads.isEmpty) return;
    setState(() => _page = 1);
    await context.read<DesignFileLibraryCubit>().uploadMany(
      uploads,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _openUploadZone() async {
    final files = await showFileUploadSheet(context, multiple: true);
    if (files != null) await _uploadFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.designFileLibrary,
                      style: AppTextStyles.headlineMedium(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppButton(
                    label: strings.uploadDesignFiles,
                    leadingIcon: Icons.upload,
                    size: AppButtonSize.small,
                    onPressed: _openUploadZone,
                  ),
                  IconButton(
                    tooltip: strings.cancel,
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DropTarget(
                onDragEntered: (_) => setState(() => _dragging = true),
                onDragExited: (_) => setState(() => _dragging = false),
                onDragDone: (detail) {
                  setState(() => _dragging = false);
                  _uploadFiles(detail.files);
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _dragging
                          ? AppTheme.primaryDark
                          : colorScheme.outline.withValues(alpha: 0.3),
                      width: _dragging ? 2 : 1,
                    ),
                    color: _dragging
                        ? AppTheme.primaryDark.withValues(alpha: 0.06)
                        : null,
                  ),
                  child: _list(colorScheme, strings),
                ),
              ),
            ),
            if (widget.pickMode && widget.multiSelect)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_selected.length} ${strings.selected}',
                      style: AppTextStyles.labelSmall(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: strings.useFile,
                      onPressed: _selected.isEmpty
                          ? () {}
                          : () => _confirmMulti(context),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmMulti(BuildContext context) {
    final all = context.read<DesignFileLibraryCubit>().state.assets;
    final chosen = all.where((a) => _selected.contains(a.id)).toList();
    Navigator.pop(context, chosen);
  }

  Widget _list(ColorScheme colorScheme, dynamic strings) {
    return BlocBuilder<DesignFileLibraryCubit, DesignFileLibraryState>(
      builder: (context, state) {
        if (state.status == DesignFileStatus.loading && state.assets.isEmpty) {
          return const Center(child: AppLoader());
        }
        final all = state.assets;
        final totalPages = all.isEmpty ? 1 : (all.length / _pageSize).ceil();
        final page = _page.clamp(1, totalPages);
        final items = all.skip((page - 1) * _pageSize).take(_pageSize).toList();
        return Column(
          children: [
            if (state.isUploading)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.uploadingBatch(
                        state.uploadingDone + 1,
                        state.uploadingTotal,
                        (state.batchProgress * 100).round(),
                      ),
                      style: AppTextStyles.labelSmall(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.batchProgress,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: all.isEmpty
                  ? _emptyHint(colorScheme, strings)
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _row(context, items[i], colorScheme, strings),
                    ),
            ),
            if (all.isNotEmpty) _footer(colorScheme, strings, page, totalPages),
          ],
        );
      },
    );
  }

  Widget _footer(
    ColorScheme colorScheme,
    dynamic strings,
    int page,
    int totalPages,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Text(
            '${strings.perPage}: ',
            style: AppTextStyles.labelSmall(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          DropdownButton<int>(
            value: _pageSize,
            underline: const SizedBox(),
            isDense: true,
            dropdownColor: colorScheme.surface,
            items: _kFilePageSizes
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
            onChanged: (n) => setState(() {
              if (n != null) {
                _pageSize = n;
                _page = 1;
              }
            }),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1 ? () => setState(() => _page = page - 1) : null,
          ),
          Text(
            '$page / $totalPages',
            style: AppTextStyles.labelSmall(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page < totalPages
                ? () => setState(() => _page = page + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(ColorScheme colorScheme, dynamic strings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 44,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            strings.dragDropHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    DesignFileAssetModel asset,
    ColorScheme colorScheme,
    dynamic strings,
  ) {
    final multi = widget.pickMode && widget.multiSelect;
    final selected = _selected.contains(asset.id);
    return Material(
      color: selected
          ? AppTheme.primaryDark.withValues(alpha: 0.10)
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.pickMode
            ? () {
                if (multi) {
                  setState(
                    () => selected
                        ? _selected.remove(asset.id)
                        : _selected.add(asset.id),
                  );
                } else {
                  Navigator.pop(context, [asset]);
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (multi)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? AppTheme.primaryDark
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              Icon(
                Icons.insert_drive_file_outlined,
                color: AppTheme.primaryDark,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: AppTextStyles.bodyMedium(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (asset.sizeBytes > 0)
                      Text(
                        _humanSize(asset.sizeBytes),
                        style: AppTextStyles.labelSmall(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (asset.format.isNotEmpty) _formatBadge(asset.format),
              IconButton(
                tooltip: strings.delete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Color(0xFFFF6B6B),
                ),
                onPressed: () => _confirmDelete(context, asset, strings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatBadge(String format) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        format,
        style: AppTextStyles.labelSmall(
          color: AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _confirmDelete(
    BuildContext context,
    DesignFileAssetModel asset,
    dynamic strings,
  ) {
    final cubit = context.read<DesignFileLibraryCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(strings.delete),
        content: Text(
          strings.confirmDeleteMessage,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _selected.remove(asset.id);
              cubit.remove(asset);
            },
            child: Text(
              strings.delete,
              style: const TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }
}
