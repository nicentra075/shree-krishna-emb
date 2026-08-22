import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/domain/repositories/wishlist_repository.dart';

enum WishlistStatus { initial, loading, loaded, error }

class WishlistState extends Equatable {
  final WishlistStatus status;
  final WishlistModel wishlist;
  final String? error;

  const WishlistState({
    this.status = WishlistStatus.initial,
    this.wishlist = const WishlistModel(),
    this.error,
  });

  bool isFavorite(String designId) => wishlist.containsDesign(designId);
  List<WishlistItemEntity> get items => wishlist.items;

  WishlistState copyWith({
    WishlistStatus? status,
    WishlistModel? wishlist,
    String? error,
  }) => WishlistState(
    status: status ?? this.status,
    wishlist: wishlist ?? this.wishlist,
    error: error,
  );

  @override
  List<Object?> get props => [status, wishlist, error];
}

/// App-wide favorites state. Held as a singleton so the heart on a card, the
/// design detail, and the Favorites screen all stay in sync from one read.
class WishlistCubit extends Cubit<WishlistState> {
  final WishlistRepository repository;

  WishlistCubit({required this.repository}) : super(const WishlistState());

  Future<void> load() async {
    emit(state.copyWith(status: WishlistStatus.loading));
    final result = await repository.load();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: WishlistStatus.error, error: failure.message),
      ),
      (wishlist) => emit(
        state.copyWith(status: WishlistStatus.loaded, wishlist: wishlist),
      ),
    );
  }

  bool isFavorite(String designId) => state.isFavorite(designId);

  /// Adds the design if absent (respecting the 100-item cap), removes it if
  /// present. Optimistic: updates UI immediately, then persists; reverts on
  /// failure. Returns the resulting favorite state (true = now a favorite).
  Future<bool> toggle({
    required String designId,
    required String title,
    String? thumbUrl,
    int price = 0,
    double avgRating = 0,
  }) async {
    final current = state.wishlist;
    final already = current.containsDesign(designId);

    final List<WishlistItemEntity> next;
    if (already) {
      next = current.items.where((i) => i.designId != designId).toList();
    } else {
      if (current.items.length >= WishlistEntity.maxItems) {
        emit(state.copyWith(error: 'Favorites limit reached'));
        return true; // unchanged — still a non-favorite, but cap hit
      }
      next = [
        WishlistItemModel(
          designId: designId,
          title: title,
          thumbUrl: thumbUrl,
          price: price,
          avgRating: avgRating,
          addedAt: DateTime.now(),
        ),
        ...current.items,
      ];
    }

    final optimistic = WishlistModel(items: next, updatedAt: DateTime.now());
    emit(state.copyWith(status: WishlistStatus.loaded, wishlist: optimistic));

    final result = await repository.save(optimistic);
    if (isClosed) return !already;
    return result.fold((failure) {
      // Revert on failure.
      emit(state.copyWith(wishlist: current, error: failure.message));
      return already;
    }, (_) => !already);
  }

  Future<void> remove(String designId) async {
    if (!state.isFavorite(designId)) return;
    final current = state.wishlist;
    final next = current.items.where((i) => i.designId != designId).toList();
    final optimistic = WishlistModel(items: next, updatedAt: DateTime.now());
    emit(state.copyWith(wishlist: optimistic));
    final result = await repository.save(optimistic);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(wishlist: current, error: failure.message)),
      (_) {},
    );
  }
}
