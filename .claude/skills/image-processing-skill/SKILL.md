---
name: image-processing-skill
description: Use when implementing image upload, watermarking, compression, high-res preview viewer, image optimization, and design gallery features for marketplace designs.
argument-hint: [image feature: upload, watermark, compress, or preview]
disable-model-invocation: true
---

## What This Skill Does

Generates complete image processing system for Shree Krishna marketplace with watermarking, compression, Firebase Storage integration, pinch-to-zoom preview, and image optimization.

**Features:**
- ✅ Image upload to Firebase Storage
- ✅ Automatic watermarking
- ✅ Image compression & resizing
- ✅ Pinch-to-zoom image viewer
- ✅ High-res preview after purchase
- ✅ Image optimization for web
- ✅ Progressive image loading
- ✅ Caching strategies
- ✅ Error handling
- ✅ Upload progress tracking

## Workflow

### 1. Image Upload Service

**Path:** `lib/domain/repositories/image_repository.dart`

Functions:
- `uploadImage(file, type)` - type: preview, design, portfolio
- `uploadMultiple(files, type)`
- `deleteImage(url)`
- `getDownloadURL(storagePath)`

### 2. Image Models

```dart
class DesignImage {
  String id;
  String url; // Compressed preview
  String fullResUrl; // Full res (locked until purchase)
  String watermarkedUrl; // Watermarked preview
  int width;
  int height;
  int fileSize;
  DateTime uploadedAt;
}
```

### 3. Watermarking

**Path:** `lib/domain/usecases/watermark_usecase.dart`

Use `image` package:
- Add semi-transparent watermark
- Place logo/text on design
- Preserve image quality
- Handle different image sizes

```dart
// Add watermark before showing preview
final watermarkedImage = await watermarkUsecase(originalImage);
```

### 4. Image Compression

**Path:** `lib/core/utils/image_compressor.dart`

- Compress for preview (max 500px, 80% quality)
- Compress for thumbnail (max 200px)
- Keep full-res version locked
- Different resolutions for different screens

### 5. Image Viewer Screen

**Path:** `lib/screens/design/image_viewer_screen.dart`

Features:
- Pinch-to-zoom (using `photo_view` package)
- Pan/scroll support
- Share & download buttons
- Image info (size, technique, time)
- Previous/next design arrows

### 6. Firebase Storage Paths

```
/designs/{designId}/
  ├── preview_{timestamp}.jpg (compressed, watermarked)
  ├── thumbnail_{timestamp}.jpg (200px)
  └── original_{timestamp}.jpg (full-res, locked)

/users/{userId}/portfolio/
  ├── image_{timestamp}.jpg
```

### 7. Image Caching

**Path:** `lib/core/utils/image_cache_manager.dart`

- Cache images locally using `cached_network_image`
- Keep cache size < 100MB
- Delete old cached images
- Handle offline access

### 8. Progressive Image Loading

```dart
// Show low-res while high-res loads
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => BlurHash(preview),
  errorWidget: (context, url, error) => ErrorPlaceholder(),
)
```

### 9. Upload Progress

**Path:** `lib/bloc/design/design_upload_bloc.dart`

- Track upload progress (0-100%)
- Handle failures with retry
- Show upload status UI
- Cancel upload option

### 10. Security

- Validate image files (format, size)
- Virus scan on backend
- Set Firebase Storage rules (read: public, write: verified users)
- Rate limit uploads

### 11. Performance

- Lazy load images in galleries
- Use thumbnails in lists
- Virtual scrolling for image galleries
- Preload next image in detail view

---

**Phase 1:** Upload, watermarking, compression  
**Phase 2+:** Advanced editing, filters

---

**Ready to implement image handling!**
