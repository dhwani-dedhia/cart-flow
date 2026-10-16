import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_dio_client.dart';
import '../network/network_cubit.dart';
import '../network/network_info.dart';
import '../storage/local_storage_service.dart';
import '../sync/order_sync_service.dart';
import '../../features/cart/bloc/cart_cubit.dart';
import '../../features/cart/domain/services/cart_storage_service.dart';
import '../../features/orders/bloc/order_cubit.dart';
import '../../features/orders/domain/services/order_service.dart';
import '../../features/products/bloc/products_cubit.dart';
import '../../features/products/domain/services/product_service.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  // 1. External & Platform
  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(prefs);

  // 2. Core services
  locator.registerLazySingleton<LocalStorageService>(
    () => LocalStorageServiceImpl(locator<SharedPreferences>()),
  );

  locator.registerLazySingleton<ApiDioClient>(
    () => ApiDioClient(),
  );

  locator.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(),
  );

  // 3. Feature services
  locator.registerLazySingleton<ProductService>(
    () => ProductServiceImpl(
      apiClient: locator<ApiDioClient>(),
      storageService: locator<LocalStorageService>(),
      networkInfo: locator<NetworkInfo>(),
    ),
  );

  locator.registerLazySingleton<CartStorageService>(
    () => CartStorageServiceImpl(locator<LocalStorageService>()),
  );

  locator.registerLazySingleton<OrderService>(
    () => OrderServiceImpl(
      apiClient: locator<ApiDioClient>(),
      storageService: locator<LocalStorageService>(),
    ),
  );

  locator.registerLazySingleton<OrderSyncService>(
    () => OrderSyncServiceImpl(
      orderService: locator<OrderService>(),
      networkInfo: locator<NetworkInfo>(),
    ),
  );

  // 4. BLoCs / Cubits
  locator.registerLazySingleton<NetworkCubit>(
    () => NetworkCubit(networkInfo: locator<NetworkInfo>()),
  );

  locator.registerLazySingleton<CartCubit>(
    () => CartCubit(cartStorageService: locator<CartStorageService>()),
  );

  locator.registerLazySingleton<OrderCubit>(
    () => OrderCubit(
      orderService: locator<OrderService>(),
      networkInfo: locator<NetworkInfo>(),
      orderSyncService: locator<OrderSyncService>(),
    ),
  );

  locator.registerFactory<ProductsCubit>(
    () => ProductsCubit(productService: locator<ProductService>()),
  );
}
