import 'package:equatable/equatable.dart';
import 'package:cartflow/features/cart/domain/models/cart_item.dart';

enum OrderSyncStatus {
  pending,  // Saved locally offline, waiting to sync
  syncing,  // Currently in-flight to server (lock acquired to prevent duplicate)
  synced,   // Successfully submitted and confirmed by server
  failed,   // Failed with permanent/server error, can retry
}

class OrderModel extends Equatable {
  final String clientOrderId; // Unique UUID v4 generated locally
  final int userId;
  final List<CartItem> items;
  final double totalAmount;
  final OrderSyncStatus status;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int? serverCartId; // Returned by DummyJSON /carts/add
  final String? errorMessage;

  const OrderModel({
    required this.clientOrderId,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.syncedAt,
    this.serverCartId,
    this.errorMessage,
  });

  bool get isPending => status == OrderSyncStatus.pending;
  bool get isSyncing => status == OrderSyncStatus.syncing;
  bool get isSynced => status == OrderSyncStatus.synced;
  bool get isFailed => status == OrderSyncStatus.failed;

  /// Formats the body required by DummyJSON /carts/add
  /// BODY: { "userId": 1, "products": [ { "id": 1, "quantity": 2 }, ... ] }
  Map<String, dynamic> toApiRequestBody() {
    return {
      'userId': userId,
      'products': items
          .map(
            (item) => {
              'id': item.product.id,
              'quantity': item.quantity,
            },
          )
          .toList(),
    };
  }

  OrderModel copyWith({
    String? clientOrderId,
    int? userId,
    List<CartItem>? items,
    double? totalAmount,
    OrderSyncStatus? status,
    DateTime? createdAt,
    DateTime? syncedAt,
    int? serverCartId,
    String? errorMessage,
  }) {
    return OrderModel(
      clientOrderId: clientOrderId ?? this.clientOrderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      serverCartId: serverCartId ?? this.serverCartId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      clientOrderId: json['clientOrderId'] as String,
      userId: json['userId'] as int? ?? 1,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: OrderSyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderSyncStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
      serverCartId: json['serverCartId'] as int?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientOrderId': clientOrderId,
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'serverCartId': serverCartId,
      'errorMessage': errorMessage,
    };
  }

  @override
  List<Object?> get props => [
        clientOrderId,
        userId,
        items,
        totalAmount,
        status,
        createdAt,
        syncedAt,
        serverCartId,
        errorMessage,
      ];
}
