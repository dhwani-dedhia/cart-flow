import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cartflow/features/cart/bloc/cart_cubit.dart';
import 'package:cartflow/features/cart/domain/services/cart_storage_service.dart';
import 'package:cartflow/features/products/domain/models/product.dart';

class MockCartStorageService extends Mock implements CartStorageService {}

void main() {
  late MockCartStorageService mockStorageService;
  late CartCubit cartCubit;

  const testProduct = Product(
    id: 1,
    title: 'Test Phone',
    description: 'High performance smartphone',
    price: 499.99,
    thumbnail: 'https://example.com/phone.jpg',
  );

  const testProduct2 = Product(
    id: 2,
    title: 'Wireless Earbuds',
    description: 'Noise cancelling earbuds',
    price: 99.99,
    thumbnail: 'https://example.com/earbuds.jpg',
  );

  setUp(() {
    mockStorageService = MockCartStorageService();
    when(() => mockStorageService.loadCart()).thenAnswer((_) async => []);
    when(() => mockStorageService.saveCart(any())).thenAnswer((_) async {});
    when(() => mockStorageService.clearCart()).thenAnswer((_) async {});

    cartCubit = CartCubit(cartStorageService: mockStorageService);
  });

  tearDown(() {
    cartCubit.close();
  });

  group('CartCubit Tests', () {
    test('initial state has empty items', () async {
      await Future.delayed(Duration.zero);
      expect(cartCubit.state.isEmpty, isTrue);
      expect(cartCubit.state.totalItemCount, equals(0));
      expect(cartCubit.state.totalAmount, equals(0.0));
    });

    test('addItem adds product with quantity 1 and computes correct total', () async {
      cartCubit.addItem(testProduct);

      expect(cartCubit.state.isEmpty, isFalse);
      expect(cartCubit.state.totalItemCount, equals(1));
      expect(cartCubit.state.getQuantity(1), equals(1));
      expect(cartCubit.state.totalAmount, equals(499.99));
      verify(() => mockStorageService.saveCart(any())).called(1);
    });

    test('increaseQuantity increases quantity from 1 to 2', () {
      cartCubit.addItem(testProduct);
      cartCubit.increaseQuantity(testProduct);

      expect(cartCubit.state.getQuantity(1), equals(2));
      expect(cartCubit.state.totalItemCount, equals(2));
      expect(cartCubit.state.totalAmount, closeTo(999.98, 0.01));
    });

    test('decreaseQuantity decreases quantity from 2 to 1', () {
      cartCubit.addItem(testProduct);
      cartCubit.increaseQuantity(testProduct);
      expect(cartCubit.state.getQuantity(1), equals(2));

      cartCubit.decreaseQuantity(testProduct);
      expect(cartCubit.state.getQuantity(1), equals(1));
      expect(cartCubit.state.totalAmount, equals(499.99));
    });

    test('decreaseQuantity at 1 removes product from cart (quantity never negative)', () {
      cartCubit.addItem(testProduct);
      expect(cartCubit.state.getQuantity(1), equals(1));

      // Decrease when quantity is 1
      cartCubit.decreaseQuantity(testProduct);

      expect(cartCubit.state.getQuantity(1), equals(0));
      expect(cartCubit.state.isInCart(1), isFalse);
      expect(cartCubit.state.isEmpty, isTrue);
      expect(cartCubit.state.totalAmount, equals(0.0));

      // Attempt to decrease again does nothing and never goes negative
      cartCubit.decreaseQuantity(testProduct);
      expect(cartCubit.state.getQuantity(1), equals(0));
      expect(cartCubit.state.totalItemCount, equals(0));
    });

    test('multiple products calculate combined cart total correctly', () {
      cartCubit.addItem(testProduct); // 1x 499.99
      cartCubit.addItem(testProduct2); // 1x 99.99
      cartCubit.increaseQuantity(testProduct2); // 2x 99.99 = 199.98

      expect(cartCubit.state.totalItemCount, equals(3));
      // 499.99 + 199.98 = 699.97
      expect(cartCubit.state.totalAmount, closeTo(699.97, 0.01));
    });

    test('removeItem removes specific product', () {
      cartCubit.addItem(testProduct);
      cartCubit.addItem(testProduct2);

      cartCubit.removeItem(testProduct.id);

      expect(cartCubit.state.isInCart(testProduct.id), isFalse);
      expect(cartCubit.state.isInCart(testProduct2.id), isTrue);
      expect(cartCubit.state.totalItemCount, equals(1));
    });

    test('clearCart empties all items', () {
      cartCubit.addItem(testProduct);
      cartCubit.addItem(testProduct2);

      cartCubit.clearCart();

      expect(cartCubit.state.isEmpty, isTrue);
      expect(cartCubit.state.totalAmount, equals(0.0));
    });

    test('addItem respects minimumOrderQuantity when enforceMoq is true', () {
      cartCubit.setMoqEnforcement(true);
      const moqProduct = Product(
        id: 10,
        title: 'Bulk Pack item',
        description: 'Wholesale box',
        price: 20.0,
        stock: 50,
        minimumOrderQuantity: 5,
      );

      final success = cartCubit.addItem(moqProduct);

      expect(success, isTrue);
      expect(cartCubit.state.getQuantity(10), equals(5));
      expect(cartCubit.state.totalItemCount, equals(5));
      expect(cartCubit.state.totalAmount, equals(100.0));
    });

    test('decreaseQuantity removes item when reaching minimumOrderQuantity in MOQ mode', () {
      cartCubit.setMoqEnforcement(true);
      const moqProduct = Product(
        id: 10,
        title: 'Bulk Pack item',
        description: 'Wholesale box',
        price: 20.0,
        stock: 50,
        minimumOrderQuantity: 3,
      );

      cartCubit.addItem(moqProduct); // starts at 3
      expect(cartCubit.state.getQuantity(10), equals(3));

      cartCubit.increaseQuantity(moqProduct); // increases to 4
      expect(cartCubit.state.getQuantity(10), equals(4));

      cartCubit.decreaseQuantity(moqProduct); // decreases back to 3
      expect(cartCubit.state.getQuantity(10), equals(3));

      // Decreasing at 3 (the MOQ) removes the product from the cart
      cartCubit.decreaseQuantity(moqProduct);
      expect(cartCubit.state.isInCart(10), isFalse);
      expect(cartCubit.state.getQuantity(10), equals(0));
    });

    test('cannot add product if out of stock', () {
      const outOfStockProduct = Product(
        id: 99,
        title: 'Sold Out Item',
        description: 'Out of stock item',
        price: 50.0,
        stock: 0,
      );

      final success = cartCubit.addItem(outOfStockProduct);

      expect(success, isFalse);
      expect(cartCubit.state.isInCart(99), isFalse);
      expect(cartCubit.state.errorMessage, contains('out of stock'));
    });

    test('cannot add product if stock is less than minimumOrderQuantity in MOQ mode', () {
      cartCubit.setMoqEnforcement(true);
      const insufficientStockProduct = Product(
        id: 101,
        title: 'Limited Item',
        description: 'Requires 10, only 4 left',
        price: 15.0,
        stock: 4,
        minimumOrderQuantity: 10,
      );

      final success = cartCubit.addItem(insufficientStockProduct);

      expect(success, isFalse);
      expect(cartCubit.state.isInCart(101), isFalse);
      expect(cartCubit.state.errorMessage, contains('Insufficient stock'));
    });

    test('cannot increase quantity beyond available stock', () {
      const limitedProduct = Product(
        id: 200,
        title: 'Rare Product',
        description: 'Only 2 available',
        price: 80.0,
        stock: 2,
        minimumOrderQuantity: 1,
      );

      cartCubit.addItem(limitedProduct); // qty 1
      expect(cartCubit.state.getQuantity(200), equals(1));

      final firstInc = cartCubit.increaseQuantity(limitedProduct); // qty 2 (max)
      expect(firstInc, isTrue);
      expect(cartCubit.state.getQuantity(200), equals(2));

      // Attempting to exceed stock 2 is prevented
      final secondInc = cartCubit.increaseQuantity(limitedProduct);
      expect(secondInc, isFalse);
      expect(cartCubit.state.getQuantity(200), equals(2));
      expect(cartCubit.state.errorMessage, contains('Maximum available stock'));
    });

    test('toggleMoqEnforcement switches enforceMoq state', () {
      expect(cartCubit.state.enforceMoq, isFalse);

      cartCubit.toggleMoqEnforcement();
      expect(cartCubit.state.enforceMoq, isTrue);

      cartCubit.toggleMoqEnforcement();
      expect(cartCubit.state.enforceMoq, isFalse);
    });

    test('when enforceMoq is false, addItem adds single unit even for products with MOQ > 1', () {
      const bulkItem = Product(
        id: 300,
        title: 'Bulk Towels',
        description: 'Pack of towels',
        price: 10.0,
        stock: 50,
        minimumOrderQuantity: 12,
      );

      // Disable MOQ
      cartCubit.setMoqEnforcement(false);

      final success = cartCubit.addItem(bulkItem);

      expect(success, isTrue);
      // Starts with 1 instead of 12!
      expect(cartCubit.state.getQuantity(300), equals(1));
      expect(cartCubit.state.totalItemCount, equals(1));
      expect(cartCubit.state.totalAmount, equals(10.0));

      // Increase to 2
      cartCubit.increaseQuantity(bulkItem);
      expect(cartCubit.state.getQuantity(300), equals(2));

      // Decrease back to 1
      cartCubit.decreaseQuantity(bulkItem);
      expect(cartCubit.state.getQuantity(300), equals(1));

      // Decrease at 1 removes from cart
      cartCubit.decreaseQuantity(bulkItem);
      expect(cartCubit.state.isInCart(300), isFalse);
    });
  });
}
