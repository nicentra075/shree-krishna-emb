import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/domain/repositories/cart_repository.dart';

enum CartStatus { initial, loading, loaded, error }

class CartState extends Equatable {
  final CartStatus status;
  final CartModel cart;
  final String? error;

  const CartState({
    this.status = CartStatus.initial,
    this.cart = const CartModel(),
    this.error,
  });

  int get itemCount => cart.items.length;
  bool get isEmpty => cart.isEmpty;
  List<CartItemEntity> get items => cart.items;
  bool contains(String designId) => cart.containsDesign(designId);

  /// Display subtotal in integer rupees (snapshot prices).
  int get subtotal => cart.itemsSubtotal;

  CartState copyWith({CartStatus? status, CartModel? cart, String? error}) =>
      CartState(
        status: status ?? this.status,
        cart: cart ?? this.cart,
        error: error,
      );

  @override
  List<Object?> get props => [status, cart, error];
}

/// App-wide cart state. Singleton so the app-bar badge, the design detail CTA,
/// and the Cart screen all stay in sync from one read. Optimistic like the
/// wishlist cubit: mutate UI immediately, persist, revert on failure.
class CartCubit extends Cubit<CartState> {
  final CartRepository repository;

  CartCubit({required this.repository}) : super(const CartState());

  Future<void> load() async {
    emit(state.copyWith(status: CartStatus.loading));
    final result = await repository.load();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: CartStatus.error, error: failure.message),
      ),
      (cart) => emit(state.copyWith(status: CartStatus.loaded, cart: cart)),
    );
  }

  bool contains(String designId) => state.contains(designId);

  /// Adds a design to the cart (no-op if already present, respecting the
  /// 50-item cap). Prices are integer rupees. Returns true when the item is in
  /// the cart afterward.
  Future<bool> add({
    required String designId,
    required String title,
    String? thumbUrl,
    int price = 0,
    String categoryName = '',
  }) async {
    final current = state.cart;
    if (current.containsDesign(designId)) return true;
    if (current.items.length >= CartEntity.maxItems) {
      emit(state.copyWith(error: 'Cart limit reached'));
      return false;
    }

    final next = <CartItemEntity>[
      CartItemModel(
        designId: designId,
        title: title,
        thumbUrl: thumbUrl,
        price: price,
        categoryName: categoryName,
        addedAt: DateTime.now(),
      ),
      ...current.items,
    ];
    final optimistic = CartModel(items: next, updatedAt: DateTime.now());
    emit(state.copyWith(status: CartStatus.loaded, cart: optimistic));

    final result = await repository.save(optimistic);
    if (isClosed) return true;
    return result.fold((failure) {
      emit(state.copyWith(cart: current, error: failure.message));
      return false;
    }, (_) => true);
  }

  Future<void> remove(String designId) async {
    if (!state.contains(designId)) return;
    final current = state.cart;
    final next = current.items.where((i) => i.designId != designId).toList();
    final optimistic = CartModel(items: next, updatedAt: DateTime.now());
    emit(state.copyWith(cart: optimistic));
    final result = await repository.save(optimistic);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(cart: current, error: failure.message)),
      (_) {},
    );
  }

  /// Empties the cart locally and persists. Used after a successful checkout
  /// (test/demo paths); the server clears it itself in the live path.
  Future<void> clear() async {
    if (state.cart.isEmpty) {
      emit(state.copyWith(status: CartStatus.loaded));
      return;
    }
    final current = state.cart;
    final optimistic = CartModel(items: const [], updatedAt: DateTime.now());
    emit(state.copyWith(status: CartStatus.loaded, cart: optimistic));
    final result = await repository.save(optimistic);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(cart: current, error: failure.message)),
      (_) {},
    );
  }
}
