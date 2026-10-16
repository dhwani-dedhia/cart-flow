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

  void toggleMoqEnforcement() {
    final nextValue = !state.enforceMoq;
    emit(state.copyWith(
      enforceMoq: nextValue,
      errorMessage: null,
    ));
  }

  void setMoqEnforcement(bool enforce) {
    emit(state.copyWith(
      enforceMoq: enforce,
      errorMessage: null,
    ));
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

  bool addItem(Product product) {
    if (product.isOutOfStock) {
      emit(state.copyWith(
        errorMessage: '${product.title} is currently out of stock.',
      ));
      return false;
    }

    if (state.enforceMoq && !product.hasSufficientStockForMoq) {
      emit(state.copyWith(
        errorMessage:
            'Insufficient stock (${product.stock}) for minimum order quantity (${product.minimumOrderQuantity}).',
      ));
      return false;
    }

    final currentMap = Map<int, CartItem>.from(state.items);
    final existing = currentMap[product.id];

    // If MOQ enforcement is active, start with product.minimumOrderQuantity; else standard 1
    final initialQuantity = state.enforceMoq && product.minimumOrderQuantity > 0
        ? product.minimumOrderQuantity
        : 1;

    if (existing != null) {
      if (existing.quantity >= product.stock) {
        emit(state.copyWith(
          errorMessage:
              'Maximum available stock (${product.stock}) reached for ${product.title}.',
        ));
        return false;
      }
      currentMap[product.id] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      currentMap[product.id] = CartItem(
        product: product,
        quantity: initialQuantity,
      );
    }

    _updateCartStateAndPersist(currentMap);
    return true;
  }

  bool increaseQuantity(Product product) {
    final currentMap = Map<int, CartItem>.from(state.items);
    final existing = currentMap[product.id];

    if (existing != null) {
      if (existing.quantity >= product.stock) {
        emit(state.copyWith(
          errorMessage:
              'Maximum available stock (${product.stock}) reached for ${product.title}.',
        ));
        return false;
      }
      currentMap[product.id] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
      _updateCartStateAndPersist(currentMap);
      return true;
    } else {
      return addItem(product);
    }
  }

  void decreaseQuantity(Product product) {
    final currentMap = Map<int, CartItem>.from(state.items);
    final existing = currentMap[product.id];

    if (existing == null) return;

    final effectiveMoq = state.enforceMoq && product.minimumOrderQuantity > 0
        ? product.minimumOrderQuantity
        : 1;

    if (existing.quantity > effectiveMoq) {
      currentMap[product.id] = existing.copyWith(
        quantity: existing.quantity - 1,
      );
    } else {
      // Reaching or going below minimum order threshold removes the product from the cart
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

  void clearErrorMessage() {
    emit(state.copyWith(errorMessage: null));
  }

  void _updateCartStateAndPersist(Map<int, CartItem> newItems) {
    emit(state.copyWith(
      status: CartStatus.loaded,
      items: newItems,
      errorMessage: null,
    ));

    // Persist to local storage asynchronously (never blocks the UI thread)
    _cartStorageService.saveCart(newItems.values.toList()).catchError((e) {
      developer.log('Failed to persist cart: $e', name: 'CartCubit');
    });
  }
}
