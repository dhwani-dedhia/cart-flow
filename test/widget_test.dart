import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cartflow/features/cart/bloc/cart_cubit.dart';
import 'package:cartflow/features/cart/domain/services/cart_storage_service.dart';
import 'package:cartflow/features/products/domain/models/product.dart';
import 'package:cartflow/features/products/widgets/product_quantity_toggle.dart';

class MockCartStorageService extends Mock implements CartStorageService {}

void main() {
  late MockCartStorageService mockStorageService;
  late CartCubit cartCubit;

  const testProduct = Product(
    id: 1,
    title: 'Test Smartphone',
    description: 'A great device',
    price: 699.00,
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

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<CartCubit>.value(
          value: cartCubit,
          child: const ProductQuantityToggle(product: testProduct),
        ),
      ),
    );
  }

  testWidgets('renders Add to Cart button when product is not in cart', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
  });

  testWidgets('tapping Add to Cart switches to [-] 1 [+] quantity controls', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Tap Add to Cart
    await tester.tap(find.text('Add to Cart'));
    await tester.pump();

    // Now quantity controls should be visible with '1'
    expect(find.text('Add to Cart'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tapping [+] increases quantity to 2, tapping [-] decreases back to 1', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Add to cart
    await tester.tap(find.text('Add to Cart'));
    await tester.pump();

    // Tap [+]
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    // Tap [-]
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    // Tap [-] again: removes from cart and restores 'Add to Cart' button!
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}
