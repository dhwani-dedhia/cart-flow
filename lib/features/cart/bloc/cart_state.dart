import 'package:equatable/equatable.dart';
import '../domain/models/cart_item.dart';

enum CartStatus { initial, loading, loaded, error }

class CartState extends Equatable {
  final CartStatus status;
  final Map<int, CartItem> items; // Keyed by Product ID for O(1) lookups
  final String? errorMessage;

  const CartState({
    this.status = CartStatus.initial,
    this.items = const {},
    this.errorMessage,
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

  CartState copyWith({
    CartStatus? status,
    Map<int, CartItem>? items,
    String? errorMessage,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
