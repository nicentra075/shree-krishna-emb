import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Image picker helper for file selection from camera or gallery
class AppImagePicker {
  AppImagePicker._();

  static final _picker = ImagePicker();

  static Future<XFile?> fromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  static Future<XFile?> fromCamera({
    int imageQuality = 85,
  }) async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );
  }

  static Future<XFile?> showPickerSheet(
    BuildContext context, {
    String galleryLabel = 'Choose from Gallery',
    String cameraLabel = 'Take Photo',
  }) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(galleryLabel),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(cameraLabel),
              onTap: () => Navigator.pop(context, 1),
            ),
          ],
        ),
      ),
    );

    if (result == null) return null;
    return result == 0 ? await fromGallery() : await fromCamera();
  }
}
