import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'app.dart';
import 'core/di/locator.dart';
import 'core/sync/order_sync_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service locator and storage
  await setupLocator();

  // Initialize background automatic order sync service
  locator<OrderSyncService>().initialize();

  FlutterError.onError = (details) {
    developer.log(
      details.exceptionAsString(),
      name: 'FlutterError',
      stackTrace: details.stack,
    );
  };

  runApp(const App());
}
