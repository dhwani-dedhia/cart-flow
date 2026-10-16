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
  });
}
