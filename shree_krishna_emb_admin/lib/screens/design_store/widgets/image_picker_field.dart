import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/media_repository.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/media_library_dialog.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/widgets/upload_zone_dialog.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

/// Opens a small chooser with three ways to add image(s) and returns the chosen
/// image URLs (or null if cancelled):
///  1. Upload from device  2. Add image URL  3. Choose from Media Library.
///
/// Uploads go through the Media Library so every uploaded image is reusable and
/// appears in the library. When [multiple] is true, "Upload from device"
/// supports drag-and-drop / multi-select and can return several URLs.
Future<List<String>?> showAddImageChooser(
  BuildContext context, {
  bool multiple = false,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (dialogCtx) => _AddImageChooser(multiple: multiple),
  );
}

class _AddImageChooser extends StatefulWidget {
  final bool multiple;
  const _AddImageChooser({required this.multiple});

  @override
  State<_AddImageChooser> createState() => _AddImageChooserState();
}

class _AddImageChooserState extends State<_AddImageChooser> {
  bool _uploading = false;
  bool _showUrl = false;
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    // Web-style upload: drag-and-drop area + browse, with multi-select.
    final files = await showImageUploadSheet(context, multiple: widget.multiple);
    if (files == null || files.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    final repo = GetIt.instance<MediaRepository>();
    final urls = <String>[];
    String? err;
    for (var i = 0; i < files.length; i++) {
      final bytes = await files[i].readAsBytes();
      final res = await repo.uploadOne(
        bytes: bytes,
        filename: files[i].name,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        seed: i,
      );
      res.fold((f) => err ??= f.message, (a) => urls.add(a.url));
    }
    if (!mounted) return;
    setState(() => _uploading = false);
    if (urls.isEmpty) {
      ResponsiveSnackbar.showError(err ?? 'Upload failed', context);
      return;
    }
    Navigator.pop(context, urls);
  }

  Future<void> _fromLibrary() async {
    final urls = await showMediaLibrary(
      context,
      pickMode: true,
      multiSelect: widget.multiple,
    );
    if (urls != null && urls.isNotEmpty && mounted) {
      Navigator.pop(context, urls);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(strings.addImage,
          style: AppTextStyles.headlineMedium(
              color: AppTheme.primaryDark, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      content: SizedBox(
        width: 360,
        child: _uploading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: AppLoader()),
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
                    icon: Icons.link,
                    label: strings.addImageUrl,
                    onTap: () => setState(() => _showUrl = !_showUrl),
                    colorScheme: colorScheme,
                  ),
                  if (_showUrl)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: strings.imageUrl,
                              // In multi mode accept several URLs, one per line.
                              hint: widget.multiple
                                  ? 'https://...\nhttps://...'
                                  : 'https://...',
                              controller: _urlController,
                              keyboardType: TextInputType.url,
                              maxLines: widget.multiple ? 3 : 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppButton(
                            label: strings.add,
                            size: AppButtonSize.small,
                            onPressed: () {
                              final raw = _urlController.text.trim();
                              if (raw.isEmpty) return;
                              final parts = widget.multiple
                                  ? raw
                                      .split(RegExp(r'[\n,]'))
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList()
                                  : [raw];
                              final valid = parts
                                  .where((u) =>
                                      Uri.tryParse(u)?.hasScheme == true)
                                  .toList();
                              if (valid.isEmpty) {
                                ResponsiveSnackbar.showError(
                                    strings.imageUrl, context);
                                return;
                              }
                              Navigator.pop(context, valid);
                            },
                          ),
                        ],
                      ),
                    ),
                  _option(
                    icon: Icons.photo_library_outlined,
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
      title: Text(label,
          style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

/// Single-image picker: preview + one "Add / Change image" button that opens
/// the 3-option chooser, plus remove.
class AppImagePickerField extends StatelessWidget {
  final String label;
  final String? value;

  /// Kept for source compatibility; uploads now always go to the Media Library.
  final String folder;
  final ValueChanged<String?> onChanged;

  const AppImagePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.folder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = (value ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? AppNetworkImage(imageUrl: value, fit: BoxFit.cover)
                  : Icon(Icons.image_outlined,
                      color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              children: [
                AppButton(
                  label: hasImage ? strings.changeImage : strings.addImage,
                  leadingIcon: Icons.add_photo_alternate_outlined,
                  size: AppButtonSize.small,
                  onPressed: () async {
                    final urls = await showAddImageChooser(context);
                    if (urls != null && urls.isNotEmpty) onChanged(urls.first);
                  },
                ),
                if (hasImage)
                  IconButton(
                    tooltip: strings.delete,
                    icon: const Icon(Icons.close,
                        size: 18, color: Color(0xFFFF6B6B)),
                    onPressed: () => onChanged(null),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Multi-image picker for designs: thumbnails with an add tile that opens the
/// 3-option chooser, plus remove per image.
class AppMultiImagePicker extends StatelessWidget {
  final String label;
  final List<String> values;
  final String folder;
  final ValueChanged<List<String>> onChanged;

  const AppMultiImagePicker({
    super.key,
    required this.label,
    required this.values,
    required this.folder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.labelSmall(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < values.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.3)),
                        ),
                        child: AppNetworkImage(
                            imageUrl: values[i], fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () {
                            final next = [...values]..removeAt(i);
                            onChanged(next);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Add tile → 3-option chooser.
              InkWell(
                onTap: () async {
                  final urls = await showAddImageChooser(context, multiple: true);
                  if (urls != null && urls.isNotEmpty) {
                    onChanged([...values, ...urls]);
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: AppTheme.primaryDark),
                      const SizedBox(height: 2),
                      Text(strings.addImage,
                          style: AppTextStyles.labelSmall(
                              color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
