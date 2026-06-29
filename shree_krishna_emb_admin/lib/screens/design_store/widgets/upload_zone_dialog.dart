import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

bool _isImage(String name) {
  final n = name.toLowerCase();
  return n.endsWith('.jpg') ||
      n.endsWith('.jpeg') ||
      n.endsWith('.png') ||
      n.endsWith('.webp') ||
      n.endsWith('.gif');
}

/// Web-style upload picker for images: a drag-and-drop area + a "Select from
/// device" button. Returns the chosen image files (supports multiple), or null
/// on cancel.
Future<List<XFile>?> showImageUploadSheet(
  BuildContext context, {
  bool multiple = true,
}) {
  return showDialog<List<XFile>>(
    context: context,
    builder: (_) => _UploadZoneDialog(multiple: multiple, imagesOnly: true),
  );
}

/// Web-style upload picker for design source files (.dst/.emb/.dhe and similar).
/// Returns the chosen files (supports multiple), or null on cancel.
Future<List<XFile>?> showFileUploadSheet(
  BuildContext context, {
  bool multiple = true,
}) {
  return showDialog<List<XFile>>(
    context: context,
    builder: (_) => _UploadZoneDialog(multiple: multiple, imagesOnly: false),
  );
}

class _UploadZoneDialog extends StatefulWidget {
  final bool multiple;
  final bool imagesOnly;
  const _UploadZoneDialog({required this.multiple, required this.imagesOnly});

  @override
  State<_UploadZoneDialog> createState() => _UploadZoneDialogState();
}

class _UploadZoneDialogState extends State<_UploadZoneDialog> {
  bool _dragging = false;

  void _done(List<XFile> files) {
    // Images are filtered to image types; design files accept any extension.
    final picked = widget.imagesOnly
        ? files.where((f) => _isImage(f.name)).toList()
        : files.where((f) => f.name.trim().isNotEmpty).toList();
    if (picked.isEmpty) return;
    Navigator.pop(context, widget.multiple ? picked : [picked.first]);
  }

  Future<void> _browse() async {
    if (widget.imagesOnly) {
      final picker = ImagePicker();
      if (widget.multiple) {
        final files = await picker.pickMultiImage();
        if (files.isNotEmpty) _done(files);
      } else {
        final file = await picker.pickImage(source: ImageSource.gallery);
        if (file != null) _done([file]);
      }
      return;
    }
    // Arbitrary design files — image_picker can't pick these.
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: widget.multiple,
      withData: true,
    );
    if (result == null) return;
    final files = result.files
        .where((f) => f.bytes != null)
        .map((f) => XFile.fromData(f.bytes!, name: f.name))
        .toList();
    if (files.isNotEmpty) _done(files);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final title = widget.imagesOnly
        ? strings.uploadImages
        : strings.uploadDesignFiles;

    return Dialog(
      backgroundColor: colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.headlineMedium(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Drag-and-drop area.
              DropTarget(
                onDragEntered: (_) => setState(() => _dragging = true),
                onDragExited: (_) => setState(() => _dragging = false),
                onDragDone: (detail) {
                  setState(() => _dragging = false);
                  _done(detail.files);
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _dragging
                        ? AppTheme.primaryDark.withValues(alpha: 0.08)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _dragging
                          ? AppTheme.primaryDark
                          : colorScheme.outline.withValues(alpha: 0.4),
                      width: _dragging ? 2 : 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 44,
                        color: AppTheme.primaryDark,
                      ),
                      const SizedBox(height: 10),
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
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: AppButton(
                  label: strings.selectFromDevice,
                  leadingIcon: Icons.folder_open_outlined,
                  onPressed: _browse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
