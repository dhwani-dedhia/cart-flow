import 'dart:developer' as developer;
import '../../../../core/api/api_dio_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../models/order_model.dart';

abstract class OrderService {
  Future<ApiResult<Map<String, dynamic>>> submitOrderToApi(OrderModel order);
  Future<void> saveOrder(OrderModel order);
  Future<void> updateOrderStatus(
    String clientOrderId,
    OrderSyncStatus status, {
    int? serverCartId,
    String? errorMessage,
  });
  List<OrderModel> getPendingOrders();
  List<OrderModel> getOrdersHistory();
  Future<void> removePendingOrder(String clientOrderId);
}

class OrderServiceImpl implements OrderService {
  final ApiDioClient _apiClient;
  final LocalStorageService _storageService;

  OrderServiceImpl({
    required ApiDioClient apiClient,
    required LocalStorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService;

  @override
  Future<ApiResult<Map<String, dynamic>>> submitOrderToApi(OrderModel order) async {
    final payload = order.toApiRequestBody();
    developer.log(
      'Submitting order ${order.clientOrderId} to API: $payload',
      name: 'OrderService',
    );

    return _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.addCart,
      data: payload,
      parser: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  @override
  Future<void> saveOrder(OrderModel order) async {
    // 1. Save or update in orders history
    final history = getOrdersHistory();
    final historyIndex = history.indexWhere((o) => o.clientOrderId == order.clientOrderId);
    if (historyIndex >= 0) {
      history[historyIndex] = order;
    } else {
      history.insert(0, order);
    }
    await _storageService.saveOrdersHistoryJson(
      history.map((o) => o.toJson()).toList(),
    );

    // 2. If status is pending or syncing, ensure it is in pending orders queue
    if (order.status == OrderSyncStatus.pending || order.status == OrderSyncStatus.syncing) {
      final pending = getPendingOrders();
      final pendingIndex = pending.indexWhere((o) => o.clientOrderId == order.clientOrderId);
      if (pendingIndex >= 0) {
        pending[pendingIndex] = order;
      } else {
        pending.add(order);
      }
      await _storageService.savePendingOrdersJson(
        pending.map((o) => o.toJson()).toList(),
      );
    }
  }

  @override
  Future<void> updateOrderStatus(
    String clientOrderId,
    OrderSyncStatus status, {
    int? serverCartId,
    String? errorMessage,
  }) async {
    final history = getOrdersHistory();
    final index = history.indexWhere((o) => o.clientOrderId == clientOrderId);
    if (index >= 0) {
      final current = history[index];
      final updated = current.copyWith(
        status: status,
        serverCartId: serverCartId ?? current.serverCartId,
        syncedAt: status == OrderSyncStatus.synced ? DateTime.now() : current.syncedAt,
        errorMessage: errorMessage,
      );
      history[index] = updated;
      await _storageService.saveOrdersHistoryJson(
        history.map((o) => o.toJson()).toList(),
      );

      // If synced, remove from pending queue
      if (status == OrderSyncStatus.synced) {
        await removePendingOrder(clientOrderId);
      } else {
        // Update pending queue item
        final pending = getPendingOrders();
        final pIndex = pending.indexWhere((o) => o.clientOrderId == clientOrderId);
        if (pIndex >= 0) {
          pending[pIndex] = updated;
          await _storageService.savePendingOrdersJson(
            pending.map((o) => o.toJson()).toList(),
          );
        }
      }
    }
  }

  @override
  List<OrderModel> getPendingOrders() {
    final raw = _storageService.getPendingOrdersJson();
    return raw.map((json) => OrderModel.fromJson(json)).toList();
  }

  @override
  List<OrderModel> getOrdersHistory() {
    final raw = _storageService.getOrdersHistoryJson();
    return raw.map((json) => OrderModel.fromJson(json)).toList();
  }

  @override
  Future<void> removePendingOrder(String clientOrderId) async {
    final pending = getPendingOrders();
    pending.removeWhere((o) => o.clientOrderId == clientOrderId);
    await _storageService.savePendingOrdersJson(
      pending.map((o) => o.toJson()).toList(),
    );
  }
}
