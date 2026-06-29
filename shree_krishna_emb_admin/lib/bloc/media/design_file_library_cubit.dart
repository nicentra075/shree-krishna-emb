import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/data/models/design_file_asset_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/design_file_repository.dart';

/// One design file queued for upload (raw bytes + original filename).
class PendingFileUpload {
  final Uint8List bytes;
  final String filename;
  const PendingFileUpload({required this.bytes, required this.filename});
}

enum DesignFileStatus { initial, loading, loaded, error }

class DesignFileLibraryState extends Equatable {
  final DesignFileStatus status;
  final List<DesignFileAssetModel> assets;
  final int uploadingCount; // > 0 while a batch is uploading
  final int uploadingTotal; // total files in the current batch
  final int uploadingDone; // files finished in the current batch
  final double uploadingProgress; // 0..1 of the file currently uploading
  final String? error;

  const DesignFileLibraryState({
    this.status = DesignFileStatus.initial,
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

  DesignFileLibraryState copyWith({
    DesignFileStatus? status,
    List<DesignFileAssetModel>? assets,
    int? uploadingCount,
    int? uploadingTotal,
    int? uploadingDone,
    double? uploadingProgress,
    String? error,
  }) => DesignFileLibraryState(
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

class DesignFileLibraryCubit extends Cubit<DesignFileLibraryState> {
  final DesignFileRepository repository;

  DesignFileLibraryCubit({required this.repository})
    : super(const DesignFileLibraryState());

  Future<void> load({bool force = false}) async {
    if (!force && state.status == DesignFileStatus.loaded) return;
    emit(state.copyWith(status: DesignFileStatus.loading));
    final result = await repository.list();
    if (isClosed) return;
    result.fold(
      (f) => emit(
        state.copyWith(status: DesignFileStatus.error, error: f.message),
      ),
      (assets) =>
          emit(state.copyWith(status: DesignFileStatus.loaded, assets: assets)),
    );
  }

  /// Uploads a batch (multi-select or drag-and-drop). The format is inferred
  /// from each file's extension. New assets are prepended as each finishes.
  Future<String?> uploadMany(
    List<PendingFileUpload> uploads,
    int timestamp,
  ) async {
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
            status: DesignFileStatus.loaded,
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

  Future<String?> remove(DesignFileAssetModel asset) async {
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
