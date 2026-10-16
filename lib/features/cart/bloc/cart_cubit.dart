import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../products/domain/models/product.dart';
import '../domain/models/cart_item.dart';
import '../domain/services/cart_storage_service.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartStorageService _cartStorageService;

  CartCubit({required CartStorageService cartStorageService})
      : _cartStorageService = cartStorageService,
        super(const CartState()) {
    loadCart();
  }

  Future<void> loadCart() async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final items = await _cartStorageService.loadCart();
      final Map<int, CartItem> map = {
        for (var item in items) item.productId: item,
      };
      emit(state.copyWith(
        status: CartStatus.loaded,
        items: map,
      ));
    } catch (e) {
      developer.log('Error loading cart: $e', name: 'CartCubit');
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to load persisted cart.',
      ));
    }
  }

  void addItem(Product product) {
    increaseQuantity(product);
  }

  void increaseQuantity(Product product) {
    final currentMap = Map<int, CartItem>.from(state.items);
    final existing = currentMap[product.id];

    if (existing != null) {
      currentMap[product.id] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      currentMap[product.id] = CartItem(
        product: product,
        quantity: 1,
      );
    }

    _updateCartStateAndPersist(currentMap);
  }

  void decreaseQuantity(Product product) {
    final currentMap = Map<int, CartItem>.from(state.items);
    final existing = currentMap[product.id];

    if (existing == null) return;

    if (existing.quantity > 1) {
      currentMap[product.id] = existing.copyWith(
        quantity: existing.quantity - 1,
      );
    } else {
      // Reaching 0 removes the product from the cart
      currentMap.remove(product.id);
    }

    _updateCartStateAndPersist(currentMap);
  }

  void removeItem(int productId) {
    final currentMap = Map<int, CartItem>.from(state.items);
    if (currentMap.containsKey(productId)) {
      currentMap.remove(productId);
      _updateCartStateAndPersist(currentMap);
    }
  }

  void clearCart() {
    _updateCartStateAndPersist({});
  }

  void _updateCartStateAndPersist(Map<int, CartItem> newItems) {
    emit(state.copyWith(
      status: CartStatus.loaded,
      items: newItems,
    ));

    // Persist to local storage asynchronously (never blocks the UI thread)
    _cartStorageService.saveCart(newItems.values.toList()).catchError((e) {
      developer.log('Failed to persist cart: $e', name: 'CartCubit');
    });
  }
}
