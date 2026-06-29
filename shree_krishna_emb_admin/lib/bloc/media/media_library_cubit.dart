import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/data/models/media_asset_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/media_repository.dart';

/// One image queued for upload (raw bytes + original filename).
class PendingUpload {
  final Uint8List bytes;
  final String filename;
  const PendingUpload({required this.bytes, required this.filename});
}

enum MediaStatus { initial, loading, loaded, error }

class MediaLibraryState extends Equatable {
  final MediaStatus status;
  final List<MediaAssetModel> assets;
  final int uploadingCount; // > 0 while a batch is uploading
  final int uploadingTotal; // total files in the current batch
  final int uploadingDone; // files finished in the current batch
  final double uploadingProgress; // 0..1 of the file currently uploading
  final String? error;

  const MediaLibraryState({
    this.status = MediaStatus.initial,
    this.assets = const [],
    this.uploadingCount = 0,
    this.uploadingTotal = 0,
    this.uploadingDone = 0,
    this.uploadingProgress = 0,
    this.error,
  });

  bool get isUploading => uploadingCount > 0;

  /// Overall batch progress (0..1): finished files + the in-flight fraction.
  double get batchProgress => uploadingTotal == 0
      ? 0
      : ((uploadingDone + uploadingProgress) / uploadingTotal).clamp(0.0, 1.0);

  MediaLibraryState copyWith({
    MediaStatus? status,
    List<MediaAssetModel>? assets,
    int? uploadingCount,
    int? uploadingTotal,
    int? uploadingDone,
    double? uploadingProgress,
    String? error,
  }) => MediaLibraryState(
    status: status ?? this.status,
    assets: assets ?? this.assets,
    uploadingCount: uploadingCount ?? this.uploadingCount,
    uploadingTotal: uploadingTotal ?? this.uploadingTotal,
    uploadingDone: uploadingDone ?? this.uploadingDone,
    uploadingProgress: uploadingProgress ?? this.uploadingProgress,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    assets,
    uploadingCount,
    uploadingTotal,
    uploadingDone,
    uploadingProgress,
    error,
  ];
}

class MediaLibraryCubit extends Cubit<MediaLibraryState> {
  final MediaRepository repository;

  MediaLibraryCubit({required this.repository})
    : super(const MediaLibraryState());

  Future<void> load({bool force = false}) async {
    if (!force && state.status == MediaStatus.loaded) return;
    emit(state.copyWith(status: MediaStatus.loading));
    final result = await repository.list();
    if (isClosed) return;
    result.fold(
      (f) => emit(state.copyWith(status: MediaStatus.error, error: f.message)),
      (assets) =>
          emit(state.copyWith(status: MediaStatus.loaded, assets: assets)),
    );
  }

  /// Uploads a batch (multi-select or drag-and-drop). New assets are prepended
  /// as each finishes. [timestamp] is supplied by the caller (UI) so filenames
  /// are unique per batch.
  Future<String?> uploadMany(List<PendingUpload> uploads, int timestamp) async {
    if (uploads.isEmpty) return null;
    emit(
      state.copyWith(
        uploadingCount: uploads.length,
        uploadingTotal: uploads.length,
        uploadingDone: 0,
        uploadingProgress: 0,
      ),
    );
    String? firstError;
    for (var i = 0; i < uploads.length; i++) {
      final u = uploads[i];
      final result = await repository.uploadOne(
        bytes: u.bytes,
        filename: u.filename,
        timestamp: timestamp,
        seed: i,
        onProgress: (p) {
          if (!isClosed) emit(state.copyWith(uploadingProgress: p));
        },
      );
      if (isClosed) return firstError;
      result.fold(
        (f) {
          firstError ??= f.message;
          // Decrement even on failure so the progress count clears.
          emit(
            state.copyWith(
              uploadingCount: state.uploadingCount - 1,
              uploadingDone: state.uploadingDone + 1,
              uploadingProgress: 0,
            ),
          );
        },
        (asset) => emit(
          state.copyWith(
            status: MediaStatus.loaded,
            assets: [asset, ...state.assets],
            uploadingCount: state.uploadingCount - 1,
            uploadingDone: state.uploadingDone + 1,
            uploadingProgress: 0,
          ),
        ),
      );
    }
    if (isClosed) return firstError;
    emit(
      state.copyWith(
        uploadingCount: 0,
        uploadingTotal: 0,
        uploadingDone: 0,
        uploadingProgress: 0,
        error: firstError,
      ),
    );
    return firstError;
  }

  Future<String?> remove(MediaAssetModel asset) async {
    final result = await repository.delete(asset);
    if (isClosed) return null;
    return result.fold((f) => f.message, (_) {
      emit(
        state.copyWith(
          assets: state.assets.where((a) => a.id != asset.id).toList(),
        ),
      );
      return null;
    });
  }
}
