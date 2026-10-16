import 'package:equatable/equatable.dart';

import '../domain/models/cart_item.dart';

enum CartStatus { initial, loading, loaded, error }

class CartState extends Equatable {
  final CartStatus status;
  final Map<int, CartItem> items; // Keyed by Product ID for O(1) lookups
  final String? errorMessage;
  final bool
  enforceMoq; // Global toggle: whether to enforce minimum order quantity

  const CartState({
    this.status = CartStatus.initial,
    this.items = const {},
    this.errorMessage,
    this.enforceMoq = false,
  });

  List<CartItem> get itemList => items.values.toList();

  int get totalItemCount =>
      items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int getQuantity(int productId) => items[productId]?.quantity ?? 0;

  bool isInCart(int productId) => (items[productId]?.quantity ?? 0) > 0;

  bool isAtMaxStock(int productId) {
    final item = items[productId];
    if (item == null) return false;
    return item.quantity >= item.product.stock;
  }

  bool canIncrease(int productId) {
    final item = items[productId];
    if (item == null) return true;
    return item.quantity < item.product.stock;
  }

  bool meetsMoq(int productId) {
    if (!enforceMoq) return true;
    final item = items[productId];
    if (item == null) return true;
    return item.quantity >= item.product.minimumOrderQuantity;
  }

  CartState copyWith({
    CartStatus? status,
    Map<int, CartItem>? items,
    String? errorMessage,
    bool? enforceMoq,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      enforceMoq: enforceMoq ?? this.enforceMoq,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage, enforceMoq];
}
