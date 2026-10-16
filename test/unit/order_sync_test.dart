import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cartflow/core/api/api_result.dart';
import 'package:cartflow/core/network/network_info.dart';
import 'package:cartflow/core/sync/order_sync_service.dart';
import 'package:cartflow/features/cart/domain/models/cart_item.dart';
import 'package:cartflow/features/orders/domain/models/order_model.dart';
import 'package:cartflow/features/orders/domain/services/order_service.dart';
import 'package:cartflow/features/products/domain/models/product.dart';

class MockOrderService extends Mock implements OrderService {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
class FakeOrderModel extends Fake implements OrderModel {}

void main() {
  late MockOrderService mockOrderService;
  late MockNetworkInfo mockNetworkInfo;
  late OrderSyncService orderSyncService;

  const testProduct = Product(
    id: 1,
    title: 'Test Phone',
    description: 'High performance smartphone',
    price: 499.99,
  );

  final testOrder = OrderModel(
    clientOrderId: 'uuid-1234-test',
    userId: 1,
    items: const [CartItem(product: testProduct, quantity: 2)],
    totalAmount: 999.98,
    status: OrderSyncStatus.pending,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(OrderSyncStatus.pending);
    registerFallbackValue(FakeOrderModel());
  });

  setUp(() {
    mockOrderService = MockOrderService();
    mockNetworkInfo = MockNetworkInfo();

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkInfo.onConnectivityChanged)
        .thenAnswer((_) => const Stream<bool>.empty());

    orderSyncService = OrderSyncServiceImpl(
      orderService: mockOrderService,
      networkInfo: mockNetworkInfo,
    );
  });

  group('OrderSyncService & Duplicate Prevention Tests', () {
    test('syncPendingOrders submits pending order and updates status to synced', () async {
      when(() => mockOrderService.getPendingOrders()).thenReturn([testOrder]);
      when(() => mockOrderService.updateOrderStatus(
            any(),
            any(),
            serverCartId: any(named: 'serverCartId'),
            errorMessage: any(named: 'errorMessage'),
          )).thenAnswer((_) async {});
      when(() => mockOrderService.submitOrderToApi(any()))
          .thenAnswer((_) async => const ApiSuccess({'id': 101}));

      await orderSyncService.syncPendingOrders();

      // Verify order was transitioned to syncing first (lock)
      verify(() => mockOrderService.updateOrderStatus(
            'uuid-1234-test',
            OrderSyncStatus.syncing,
          )).called(1);

      // Verify API was called
      verify(() => mockOrderService.submitOrderToApi(testOrder)).called(1);

      // Verify order was transitioned to synced with server cart id
      verify(() => mockOrderService.updateOrderStatus(
            'uuid-1234-test',
            OrderSyncStatus.synced,
            serverCartId: 101,
          )).called(1);
    });

    test('orders already marked synced are removed and never uploaded to API again', () async {
      final alreadySyncedOrder = testOrder.copyWith(status: OrderSyncStatus.synced);
      when(() => mockOrderService.getPendingOrders()).thenReturn([alreadySyncedOrder]);
      when(() => mockOrderService.removePendingOrder(any())).thenAnswer((_) async {});

      await orderSyncService.syncPendingOrders();

      // Submit API should NEVER be called for already synced order
      verifyNever(() => mockOrderService.submitOrderToApi(any()));
      verify(() => mockOrderService.removePendingOrder('uuid-1234-test')).called(1);
    });

    test('duplicate concurrent sync calls are prevented by mutex lock', () async {
      when(() => mockOrderService.getPendingOrders()).thenReturn([testOrder]);
      when(() => mockOrderService.updateOrderStatus(
            any(),
            any(),
            serverCartId: any(named: 'serverCartId'),
            errorMessage: any(named: 'errorMessage'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      when(() => mockOrderService.submitOrderToApi(any()))
          .thenAnswer((_) async => const ApiSuccess({'id': 101}));

      // Trigger two sync calls simultaneously
      final future1 = orderSyncService.syncPendingOrders();
      final future2 = orderSyncService.syncPendingOrders();

      await Future.wait([future1, future2]);

      // Only one execution should have run
      verify(() => mockOrderService.submitOrderToApi(any())).called(1);
    });
  });
}
