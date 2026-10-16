import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_keys.dart';

abstract class LocalStorageService {
  Future<void> saveString(String key, String value);
  String? getString(String key);
  Future<void> remove(String key);

  // Cart persistence
  Future<void> saveCartJson(List<Map<String, dynamic>> items);
  List<Map<String, dynamic>> getCartJson();
  Future<void> clearCart();

  // Offline pending orders queue
  Future<void> savePendingOrdersJson(List<Map<String, dynamic>> orders);
  List<Map<String, dynamic>> getPendingOrdersJson();

  // Orders history
  Future<void> saveOrdersHistoryJson(List<Map<String, dynamic>> orders);
  List<Map<String, dynamic>> getOrdersHistoryJson();

  // Product cache (for offline browsing)
  Future<void> saveCachedProductsJson(List<Map<String, dynamic>> products);
  List<Map<String, dynamic>> getCachedProductsJson();

  Future<void> saveCachedCategories(List<String> categories);
  List<String> getCachedCategories();
}

class LocalStorageServiceImpl implements LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageServiceImpl(this._prefs);

  @override
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> saveCartJson(List<Map<String, dynamic>> items) async {
    try {
      final jsonString = jsonEncode(items);
      await _prefs.setString(StorageKeys.cartItems, jsonString);
    } catch (e) {
      developer.log('Error saving cart: $e', name: 'LocalStorageService');
    }
  }

  @override
  List<Map<String, dynamic>> getCartJson() {
    try {
      final jsonString = _prefs.getString(StorageKeys.cartItems);
      if (jsonString == null || jsonString.isEmpty) return [];
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      developer.log('Error reading cart: $e', name: 'LocalStorageService');
      return [];
    }
  }

  @override
  Future<void> clearCart() async {
    await _prefs.remove(StorageKeys.cartItems);
  }

  @override
  Future<void> savePendingOrdersJson(List<Map<String, dynamic>> orders) async {
    try {
      final jsonString = jsonEncode(orders);
      await _prefs.setString(StorageKeys.pendingOrders, jsonString);
    } catch (e) {
      developer.log('Error saving pending orders: $e', name: 'LocalStorageService');
    }
  }

  @override
  List<Map<String, dynamic>> getPendingOrdersJson() {
    try {
      final jsonString = _prefs.getString(StorageKeys.pendingOrders);
      if (jsonString == null || jsonString.isEmpty) return [];
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      developer.log('Error reading pending orders: $e', name: 'LocalStorageService');
      return [];
    }
  }

  @override
  Future<void> saveOrdersHistoryJson(List<Map<String, dynamic>> orders) async {
    try {
      final jsonString = jsonEncode(orders);
      await _prefs.setString(StorageKeys.ordersHistory, jsonString);
    } catch (e) {
      developer.log('Error saving orders history: $e', name: 'LocalStorageService');
    }
  }

  @override
  List<Map<String, dynamic>> getOrdersHistoryJson() {
    try {
      final jsonString = _prefs.getString(StorageKeys.ordersHistory);
      if (jsonString == null || jsonString.isEmpty) return [];
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      developer.log('Error reading orders history: $e', name: 'LocalStorageService');
      return [];
    }
  }

  @override
  Future<void> saveCachedProductsJson(List<Map<String, dynamic>> products) async {
    try {
      final jsonString = jsonEncode(products);
      await _prefs.setString(StorageKeys.cachedProducts, jsonString);
    } catch (e) {
      developer.log('Error saving cached products: $e', name: 'LocalStorageService');
    }
  }

  @override
  List<Map<String, dynamic>> getCachedProductsJson() {
    try {
      final jsonString = _prefs.getString(StorageKeys.cachedProducts);
      if (jsonString == null || jsonString.isEmpty) return [];
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      developer.log('Error reading cached products: $e', name: 'LocalStorageService');
      return [];
    }
  }

  @override
  Future<void> saveCachedCategories(List<String> categories) async {
    try {
      await _prefs.setStringList(StorageKeys.cachedCategories, categories);
    } catch (e) {
      developer.log('Error saving cached categories: $e', name: 'LocalStorageService');
    }
  }

  @override
  List<String> getCachedCategories() {
    return _prefs.getStringList(StorageKeys.cachedCategories) ?? [];
  }
}
