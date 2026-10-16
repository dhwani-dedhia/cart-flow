import 'package:equatable/equatable.dart';
import '../domain/models/order_model.dart';

enum OrderSubmissionStatus {
  initial,
  submitting,
  successOnline,  // Submitted to API directly while online
  queuedOffline,  // Saved locally because device is offline or network failed
  failure,        // Unrecoverable validation or server error
}

class OrderState extends Equatable {
  final OrderSubmissionStatus submissionStatus;
  final List<OrderModel> orders;
  final OrderModel? lastPlacedOrder;
  final String? errorMessage;
  final bool isSyncingOfflineOrders;

  const OrderState({
    this.submissionStatus = OrderSubmissionStatus.initial,
    this.orders = const [],
    this.lastPlacedOrder,
    this.errorMessage,
    this.isSyncingOfflineOrders = false,
  });

  bool get isSubmitting =>
      submissionStatus == OrderSubmissionStatus.submitting;

  int get pendingOfflineCount =>
      orders.where((o) => o.status == OrderSyncStatus.pending).length;

  OrderState copyWith({
    OrderSubmissionStatus? submissionStatus,
    List<OrderModel>? orders,
    OrderModel? lastPlacedOrder,
    String? errorMessage,
    bool? isSyncingOfflineOrders,
  }) {
    return OrderState(
      submissionStatus: submissionStatus ?? this.submissionStatus,
      orders: orders ?? this.orders,
      lastPlacedOrder: lastPlacedOrder ?? this.lastPlacedOrder,
      errorMessage: errorMessage,
      isSyncingOfflineOrders:
          isSyncingOfflineOrders ?? this.isSyncingOfflineOrders,
    );
  }

  @override
  List<Object?> get props => [
        submissionStatus,
        orders,
        lastPlacedOrder,
        errorMessage,
        isSyncingOfflineOrders,
      ];
}
