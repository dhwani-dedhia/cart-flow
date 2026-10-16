import 'dart:async';
import 'dart:developer' as developer;
import '../api/api_result.dart';
import '../network/network_info.dart';
import '../../features/orders/domain/models/order_model.dart';
import '../../features/orders/domain/services/order_service.dart';

abstract class OrderSyncService {
  void initialize();
  Future<void> syncPendingOrders();
  Stream<OrderModel> get onOrderSynced;
  bool get isSyncing;
  void dispose();
}

class OrderSyncServiceImpl implements OrderSyncService {
  final OrderService _orderService;
  final NetworkInfo _networkInfo;

  bool _isSyncing = false;
  StreamSubscription<bool>? _networkSubscription;
  final StreamController<OrderModel> _syncedOrderController =
      StreamController<OrderModel>.broadcast();

  OrderSyncServiceImpl({
    required OrderService orderService,
    required NetworkInfo networkInfo,
  })  : _orderService = orderService,
        _networkInfo = networkInfo;

  @override
  bool get isSyncing => _isSyncing;

  @override
  Stream<OrderModel> get onOrderSynced => _syncedOrderController.stream;

  @override
  void initialize() {
    developer.log('Initializing OrderSyncService...', name: 'OrderSyncService');

    // 1. Check and sync immediately if already connected on startup
    _networkInfo.isConnected.then((connected) {
      if (connected) {
        syncPendingOrders();
      }
    });

    // 2. Listen to connectivity changes: automatically trigger sync when internet returns
    _networkSubscription = _networkInfo.onConnectivityChanged.listen((connected) {
      if (connected) {
        developer.log(
          'Internet connection restored. Triggering automatic sync of pending orders...',
          name: 'OrderSyncService',
        );
        syncPendingOrders();
      }
    });
  }

  @override
  Future<void> syncPendingOrders() async {
    // Concurrency Lock: prevent parallel sync runs (duplicate prevention rule 1)
    if (_isSyncing) {
      developer.log(
        'Sync already in progress. Skipping redundant trigger.',
        name: 'OrderSyncService',
      );
      return;
    }

    _isSyncing = true;

    try {
      final isOnline = await _networkInfo.isConnected;
      if (!isOnline) {
        developer.log('Device is offline. Cannot sync.', name: 'OrderSyncService');
        return;
      }

      final pendingOrders = _orderService.getPendingOrders();
      if (pendingOrders.isEmpty) {
        developer.log('No pending orders to sync.', name: 'OrderSyncService');
        return;
      }

      developer.log(
        'Found ${pendingOrders.length} pending order(s) to synchronize.',
        name: 'OrderSyncService',
      );

      for (final order in pendingOrders) {
        // Skip orders already synced or currently marked syncing by another thread
        if (order.status == OrderSyncStatus.synced) {
          await _orderService.removePendingOrder(order.clientOrderId);
          continue;
        }

        // Lock individual order into syncing state (duplicate prevention rule 2)
        await _orderService.updateOrderStatus(
          order.clientOrderId,
          OrderSyncStatus.syncing,
        );

        developer.log(
          'Syncing offline order: ${order.clientOrderId} (${order.items.length} items)...',
          name: 'OrderSyncService',
        );

        final result = await _orderService.submitOrderToApi(order);

        if (result is ApiSuccess<Map<String, dynamic>>) {
          final serverCartId = result.data['id'] as int?;
          developer.log(
            'Order ${order.clientOrderId} successfully synced! Server Cart ID: $serverCartId',
            name: 'OrderSyncService',
          );

          // Mark order as synced, record timestamp and server response ID
          await _orderService.updateOrderStatus(
            order.clientOrderId,
            OrderSyncStatus.synced,
            serverCartId: serverCartId,
          );

          final syncedOrder = order.copyWith(
            status: OrderSyncStatus.synced,
            serverCartId: serverCartId,
            syncedAt: DateTime.now(),
          );

          // Broadcast notification to active UI listeners
          _syncedOrderController.add(syncedOrder);
        } else if (result is ApiFailure<Map<String, dynamic>>) {
          developer.log(
            'Sync failed for order ${order.clientOrderId}: ${result.message}',
            name: 'OrderSyncService',
          );

          // If it was a network timeout or connection error, return to pending for next cycle
          final isNetworkError = result.statusCode == null;
          await _orderService.updateOrderStatus(
            order.clientOrderId,
            isNetworkError ? OrderSyncStatus.pending : OrderSyncStatus.failed,
            errorMessage: result.message,
          );

          // If offline again, stop trying remaining orders
          final stillOnline = await _networkInfo.isConnected;
          if (!stillOnline) break;
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error in syncPendingOrders: $e',
        name: 'OrderSyncService',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    _syncedOrderController.close();
  }
}
