import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/media/media_library_cubit.dart';
import 'package:shree_krishna_emb_admin/data/models/media_asset_model.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/upload_zone_dialog.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

/// Per-page options for the Media Library grid.
const List<int> _kMediaPageSizes = [12, 24, 48];

/// Opens the Media Library. In [pickMode] it returns the chosen image URL(s);
/// with [multiSelect] the user can tick several and confirm. Returns null when
/// cancelled, or an empty/non-empty list of URLs.
Future<List<String>?> showMediaLibrary(
  BuildContext context, {
  bool pickMode = false,
  bool multiSelect = false,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => BlocProvider<MediaLibraryCubit>(
      create: (_) => GetIt.instance<MediaLibraryCubit>()..load(),
      child: _MediaLibraryDialog(pickMode: pickMode, multiSelect: multiSelect),
    ),
  );
}

class _MediaLibraryDialog extends StatefulWidget {
  final bool pickMode;
  final bool multiSelect;
  const _MediaLibraryDialog({required this.pickMode, required this.multiSelect});

  @override
  State<_MediaLibraryDialog> createState() => _MediaLibraryDialogState();
}

class _MediaLibraryDialogState extends State<_MediaLibraryDialog> {
  bool _dragging = false;
  int _page = 1;
  int _pageSize = 12;
  final Set<String> _selected = {}; // selected URLs (multi-select)

  Future<void> _uploadFiles(List<dynamic> files) async {
    final uploads = <PendingUpload>[];
    for (final f in files) {
      uploads.add(PendingUpload(bytes: await f.readAsBytes(), filename: f.name));
    }
    if (!mounted || uploads.isEmpty) return;
    setState(() => _page = 1);
    await context
        .read<MediaLibraryCubit>()
        .uploadMany(uploads, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _openUploadZone() async {
    final files = await showImageUploadSheet(context, multiple: true);
    if (files != null) await _uploadFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(strings.mediaLibrary,
                        style: AppTextStyles.headlineMedium(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  AppButton(
                    label: strings.uploadImages,
                    leadingIcon: Icons.upload,
                    size: AppButtonSize.small,
                    onPressed: _openUploadZone,
                  ),
                  IconButton(
                    tooltip: strings.cancel,
                    icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
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
                  child: _grid(colorScheme, strings),
                ),
              ),
            ),
            // Confirm bar for multi-select pick mode.
            if (widget.pickMode && widget.multiSelect)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${_selected.length} ${strings.selected}',
                        style: AppTextStyles.labelSmall(
                            color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(width: 12),
                    AppButton(
                      label: strings.useImage,
                      onPressed: _selected.isEmpty
                          ? () {}
                          : () => Navigator.pop(context, _selected.toList()),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _grid(ColorScheme colorScheme, dynamic strings) {
    return BlocBuilder<MediaLibraryCubit, MediaLibraryState>(
      builder: (context, state) {
        if (state.status == MediaStatus.loading && state.assets.isEmpty) {
          return const Center(child: AppLoader());
        }
        final all = state.assets;
        final totalPages = all.isEmpty ? 1 : (all.length / _pageSize).ceil();
        final page = _page.clamp(1, totalPages);
        final items =
            all.skip((page - 1) * _pageSize).take(_pageSize).toList();
        return Column(
          children: [
            if (state.isUploading)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 10),
                    Text('${strings.uploading} (${state.uploadingCount})',
                        style: AppTextStyles.labelSmall(
                            color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            Expanded(
              child: all.isEmpty
                  ? _emptyHint(colorScheme, strings)
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemBuilder: (context, i) =>
                          _tile(context, items[i], colorScheme, strings),
                    ),
            ),
            if (all.isNotEmpty)
              _footer(colorScheme, strings, page, totalPages),
          ],
        );
      },
    );
  }

  Widget _footer(
      ColorScheme colorScheme, dynamic strings, int page, int totalPages) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          // Per-page selector.
          Text('${strings.perPage}: ',
              style:
                  AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          DropdownButton<int>(
            value: _pageSize,
            underline: const SizedBox(),
            isDense: true,
            dropdownColor: colorScheme.surface,
            items: _kMediaPageSizes
                .map((n) => DropdownMenuItem(
                      value: n,
                      child: Text('$n',
                          style: AppTextStyles.labelMedium(
                              color: colorScheme.onSurface)),
                    ))
                .toList(),
            onChanged: (n) =>
                setState(() {
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
          Text('$page / $totalPages',
              style:
                  AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
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
          Icon(Icons.cloud_upload_outlined,
              size: 44, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(strings.dragDropHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(color: colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, MediaAssetModel asset,
      ColorScheme colorScheme, dynamic strings) {
    final multi = widget.pickMode && widget.multiSelect;
    final selected = _selected.contains(asset.url);
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: widget.pickMode
                ? () {
                    if (multi) {
                      setState(() => selected
                          ? _selected.remove(asset.url)
                          : _selected.add(asset.url));
                    } else {
                      Navigator.pop(context, [asset.url]);
                    }
                  }
                : null,
            child: AppNetworkImage(imageUrl: asset.url, fit: BoxFit.cover),
          ),
        ),
        if (multi && selected)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryDark, width: 3),
              color: AppTheme.primaryDark.withValues(alpha: 0.18),
            ),
            child: const Align(
              alignment: Alignment.center,
              child: Icon(Icons.check_circle, color: Colors.white),
            ),
          ),
        // Delete button.
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: () => _confirmDelete(context, asset, strings),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline,
                  size: 16, color: Colors.white),
            ),
          ),
        ),
        if (widget.pickMode && !multi)
          Positioned(
            bottom: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(strings.useImage,
                  style: AppTextStyles.labelSmall(
                      color: Colors.white, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    );
  }

  void _confirmDelete(
      BuildContext context, MediaAssetModel asset, dynamic strings) {
    final cubit = context.read<MediaLibraryCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.confirmDeleteMessage,
            maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _selected.remove(asset.url);
              cubit.remove(asset);
            },
            child: Text(strings.delete,
                style: const TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }
}
