import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/locator.dart';
import 'core/network/network_cubit.dart';
import 'core/theme/app_theme.dart';
import 'features/cart/bloc/cart_cubit.dart';
import 'features/orders/bloc/order_cubit.dart';
import 'features/products/bloc/products_cubit.dart';
import 'features/products/presentation/products_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NetworkCubit>(
          create: (_) => locator<NetworkCubit>(),
        ),
        BlocProvider<CartCubit>(
          create: (_) => locator<CartCubit>(),
        ),
        BlocProvider<OrderCubit>(
          create: (_) => locator<OrderCubit>(),
        ),
        BlocProvider<ProductsCubit>(
          create: (_) => locator<ProductsCubit>()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'CartFlow - Offline-First Shopping Cart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ProductsScreen(),
      ),
    );
  }
}
