import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/sync/order_sync_service.dart';
import '../../cart/domain/models/cart_item.dart';
import '../domain/models/order_model.dart';
import '../domain/services/order_service.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderService _orderService;
  final NetworkInfo _networkInfo;
  final OrderSyncService _orderSyncService;
  final Uuid _uuid;

  StreamSubscription<OrderModel>? _syncSubscription;

  OrderCubit({
    required OrderService orderService,
    required NetworkInfo networkInfo,
    required OrderSyncService orderSyncService,
    Uuid? uuid,
  })  : _orderService = orderService,
        _networkInfo = networkInfo,
        _orderSyncService = orderSyncService,
        _uuid = uuid ?? const Uuid(),
        super(const OrderState()) {
    loadOrdersHistory();
    _listenToSyncEvents();
  }

  void _listenToSyncEvents() {
    _syncSubscription = _orderSyncService.onOrderSynced.listen((syncedOrder) {
      // Reload order history when an offline order sync completes
      loadOrdersHistory();
    });
  }

  void loadOrdersHistory() {
    final history = _orderService.getOrdersHistory();
    emit(state.copyWith(
      orders: history,
      isSyncingOfflineOrders: _orderSyncService.isSyncing,
    ));
  }

  Future<void> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    int userId = 1,
    bool enforceMoq = false,
  }) async {
    if (items.isEmpty) {
      emit(state.copyWith(
        submissionStatus: OrderSubmissionStatus.failure,
        errorMessage: 'Cannot place an empty order.',
      ));
      return;
    }

    // Stock and Minimum Order Quantity validation
    for (final item in items) {
      if (item.product.isOutOfStock) {
        emit(state.copyWith(
          submissionStatus: OrderSubmissionStatus.failure,
          errorMessage:
              'Cannot place order: "${item.product.title}" is out of stock.',
        ));
        return;
      }
      if (item.quantity > item.product.stock) {
        emit(state.copyWith(
          submissionStatus: OrderSubmissionStatus.failure,
          errorMessage:
              'Cannot place order: "${item.product.title}" exceeds available stock (${item.product.stock}).',
        ));
        return;
      }
      if (enforceMoq && item.quantity < item.product.minimumOrderQuantity) {
        emit(state.copyWith(
          submissionStatus: OrderSubmissionStatus.failure,
          errorMessage:
              'Cannot place order: "${item.product.title}" requires a minimum order of ${item.product.minimumOrderQuantity} items.',
        ));
        return;
      }
    }

    emit(state.copyWith(
      submissionStatus: OrderSubmissionStatus.submitting,
      errorMessage: null,
    ));

    final clientOrderId = _uuid.v4();
    final isOnline = await _networkInfo.isConnected;

    final newOrder = OrderModel(
      clientOrderId: clientOrderId,
      userId: userId,
      items: items,
      totalAmount: totalAmount,
      status: isOnline ? OrderSyncStatus.pending : OrderSyncStatus.pending,
      createdAt: DateTime.now(),
    );

    if (!isOnline) {
      // Offline mode: queue order locally
      await _orderService.saveOrder(newOrder);
      loadOrdersHistory();
      emit(state.copyWith(
        submissionStatus: OrderSubmissionStatus.queuedOffline,
        lastPlacedOrder: newOrder,
      ));
      return;
    }

    // Online mode: attempt direct submission
    try {
      final result = await _orderService.submitOrderToApi(newOrder);

      if (result is ApiSuccess<Map<String, dynamic>>) {
        final serverCartId = result.data['id'] as int?;
        final syncedOrder = newOrder.copyWith(
          status: OrderSyncStatus.synced,
          serverCartId: serverCartId,
          syncedAt: DateTime.now(),
        );

        await _orderService.saveOrder(syncedOrder);
        loadOrdersHistory();

        emit(state.copyWith(
          submissionStatus: OrderSubmissionStatus.successOnline,
          lastPlacedOrder: syncedOrder,
        ));
      } else if (result is ApiFailure<Map<String, dynamic>>) {
        // Fallback to offline queue if failure was a connection/network issue
        if (result.statusCode == null) {
          await _orderService.saveOrder(newOrder);
          loadOrdersHistory();
          emit(state.copyWith(
            submissionStatus: OrderSubmissionStatus.queuedOffline,
            lastPlacedOrder: newOrder,
          ));
        } else {
          emit(state.copyWith(
            submissionStatus: OrderSubmissionStatus.failure,
            errorMessage: result.message,
          ));
        }
      }
    } catch (e) {
      // In case of unexpected network drops, queue offline
      await _orderService.saveOrder(newOrder);
      loadOrdersHistory();
      emit(state.copyWith(
        submissionStatus: OrderSubmissionStatus.queuedOffline,
        lastPlacedOrder: newOrder,
      ));
    }
  }

  void resetSubmissionStatus() {
    emit(state.copyWith(
      submissionStatus: OrderSubmissionStatus.initial,
      errorMessage: null,
    ));
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    return super.close();
  }
}
