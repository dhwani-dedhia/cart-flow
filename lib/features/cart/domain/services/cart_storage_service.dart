import '../../../../core/storage/local_storage_service.dart';
import '../models/cart_item.dart';

abstract class CartStorageService {
  Future<List<CartItem>> loadCart();
  Future<void> saveCart(List<CartItem> items);
  Future<void> clearCart();
}

class CartStorageServiceImpl implements CartStorageService {
  final LocalStorageService _storageService;

  CartStorageServiceImpl(this._storageService);

  @override
  Future<List<CartItem>> loadCart() async {
    final list = _storageService.getCartJson();
    return list.map((json) => CartItem.fromJson(json)).toList();
  }

  @override
  Future<void> saveCart(List<CartItem> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    await _storageService.saveCartJson(jsonList);
  }

  @override
  Future<void> clearCart() async {
    await _storageService.clearCart();
  }
}
