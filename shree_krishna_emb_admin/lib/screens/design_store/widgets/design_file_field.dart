import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/domain/entities/design.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/design_file_repository.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/design_file_library_dialog.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/upload_zone_dialog.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

/// Opens a chooser to attach a design source file to a [format] slot — either
/// by uploading from the device or picking from the Design File Library — and
/// returns the resulting [DesignFileRef] (or null if cancelled).
Future<DesignFileRef?> showDesignFileChooser(
  BuildContext context, {
  required String format,
}) {
  return showDialog<DesignFileRef>(
    context: context,
    builder: (_) => _DesignFileChooser(format: format),
  );
}

class _DesignFileChooser extends StatefulWidget {
  final String format;
  const _DesignFileChooser({required this.format});

  @override
  State<_DesignFileChooser> createState() => _DesignFileChooserState();
}

class _DesignFileChooserState extends State<_DesignFileChooser> {
  bool _uploading = false;
  double _progress = 0;

  Future<void> _upload() async {
    final files = await showFileUploadSheet(context, multiple: false);
    if (files == null || files.isEmpty || !mounted) return;
    setState(() {
      _uploading = true;
      _progress = 0;
    });
    final repo = GetIt.instance<DesignFileRepository>();
    final f = files.first;
    final bytes = await f.readAsBytes();
    final res = await repo.uploadOne(
      bytes: bytes,
      filename: f.name,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      format: widget.format,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    res.fold(
      (fail) => ResponsiveSnackbar.showError(fail.message, context),
      (asset) => Navigator.pop(
        context,
        DesignFileRef(
          format: widget.format,
          name: asset.name,
          url: asset.url,
          path: asset.path,
          sizeBytes: asset.sizeBytes,
        ),
      ),
    );
  }

  Future<void> _fromLibrary() async {
    final chosen = await showDesignFileLibrary(context, pickMode: true);
    if (chosen == null || chosen.isEmpty || !mounted) return;
    final a = chosen.first;
    Navigator.pop(
      context,
      DesignFileRef(
        format: widget.format,
        name: a.name,
        url: a.url,
        path: a.path,
        sizeBytes: a.sizeBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(
        '${strings.addDesignFile} · ${widget.format}',
        style: AppTextStyles.headlineMedium(
          color: AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 360,
        child: _uploading
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.uploadingPercent((_progress * 100).round()),
                      style: AppTextStyles.bodyMedium(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _option(
                    icon: Icons.upload_outlined,
                    label: strings.uploadFromDevice,
                    onTap: _upload,
                    colorScheme: colorScheme,
                  ),
                  _option(
                    icon: Icons.folder_copy_outlined,
                    label: strings.chooseFromLibrary,
                    onTap: _fromLibrary,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
      ],
    );
  }

  Widget _option({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.primaryDark),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

/// Multi-select of design formats (DST/EMB/DHE) with a downloadable source-file
/// slot per selected format. Deselecting a format also drops its attached file.
class DesignFilesField extends StatelessWidget {
  final List<String> formats;
  final List<DesignFileRef> files;
  final ValueChanged<List<String>> onFormatsChanged;
  final ValueChanged<List<DesignFileRef>> onFilesChanged;

  const DesignFilesField({
    super.key,
    required this.formats,
    required this.files,
    required this.onFormatsChanged,
    required this.onFilesChanged,
  });

  DesignFileRef? _fileFor(String format) {
    for (final f in files) {
      if (f.format == format) return f;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.layers_outlined,
                size: 18,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.designFormat,
                  style: AppTextStyles.labelMedium(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kDesignFormats.map((fmt) {
              final selected = formats.contains(fmt);
              return FilterChip(
                label: Text(
                  fmt,
                  style: AppTextStyles.labelMedium(
                    color: selected
                        ? AppTheme.primaryDark
                        : colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selected,
                showCheckmark: true,
                checkmarkColor: AppTheme.primaryDark,
                backgroundColor: colorScheme.surface,
                selectedColor: AppTheme.primaryDark.withValues(alpha: 0.14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(
                  color: selected
                      ? AppTheme.primaryDark
                      : colorScheme.outline.withValues(alpha: 0.4),
                  width: selected ? 1.4 : 1,
                ),
                onSelected: (sel) {
                  final next = [...formats];
                  if (sel) {
                    if (!next.contains(fmt)) next.add(fmt);
                  } else {
                    next.remove(fmt);
                    // Drop the file attached to the de-selected format.
                    onFilesChanged(
                      files.where((f) => f.format != fmt).toList(),
                    );
                  }
                  onFormatsChanged(next);
                },
              );
            }).toList(),
          ),
          if (formats.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              strings.designFiles,
              style: AppTextStyles.labelMedium(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            for (final fmt in formats)
              _slot(context, fmt, strings, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _slot(
    BuildContext context,
    String fmt,
    dynamic strings,
    ColorScheme colorScheme,
  ) {
    final file = _fileFor(fmt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              fmt,
              style: AppTextStyles.labelSmall(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: file == null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      label: strings.addDesignFile,
                      leadingIcon: Icons.attach_file,
                      size: AppButtonSize.small,
                      onPressed: () async {
                        final ref = await showDesignFileChooser(
                          context,
                          format: fmt,
                        );
                        if (ref != null) {
                          final next =
                              files.where((f) => f.format != fmt).toList()
                                ..add(ref);
                          onFilesChanged(next);
                        }
                      },
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 18,
                          color: AppTheme.primaryDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.name,
                            style: AppTextStyles.bodySmall(
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: strings.delete,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFFFF6B6B),
                          ),
                          onPressed: () => onFilesChanged(
                            files.where((f) => f.format != fmt).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
