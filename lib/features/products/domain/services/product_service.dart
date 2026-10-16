import 'dart:developer' as developer;
import '../../../../core/api/api_dio_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_result.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../models/product.dart';
import '../models/products_response.dart';

abstract class ProductService {
  Future<ApiResult<ProductsResponse>> getProducts({
    int skip = 0,
    int limit = 10,
    String? search,
    String? category,
  });

  Future<ApiResult<Product>> getProductDetails(int id);

  Future<List<String>> getCategories();
}

class ProductServiceImpl implements ProductService {
  final ApiDioClient _apiClient;
  final LocalStorageService _storageService;
  final NetworkInfo _networkInfo;

  ProductServiceImpl({
    required ApiDioClient apiClient,
    required LocalStorageService storageService,
    required NetworkInfo networkInfo,
  })  : _apiClient = apiClient,
        _storageService = storageService,
        _networkInfo = networkInfo;

  @override
  Future<ApiResult<ProductsResponse>> getProducts({
    int skip = 0,
    int limit = 10,
    String? search,
    String? category,
  }) async {
    final isOnline = await _networkInfo.isConnected;

    // If offline, attempt to serve from local product cache
    if (!isOnline) {
      final cached = _getCachedProducts(skip: skip, limit: limit, search: search, category: category);
      if (cached != null && cached.products.isNotEmpty) {
        return ApiSuccess(cached);
      }
      return const ApiFailure(
        message: 'You are currently offline. Please connect to the internet to load more products.',
      );
    }

    try {
      String endpoint = ApiEndpoints.products;
      Map<String, dynamic> queryParams = {
        'limit': limit,
        'skip': skip,
      };

      if (search != null && search.trim().isNotEmpty) {
        endpoint = ApiEndpoints.searchProducts;
        queryParams['q'] = search.trim();
      } else if (category != null && category.trim().isNotEmpty && category != 'All') {
        endpoint = ApiEndpoints.productsByCategory(category.trim());
      }

      final result = await _apiClient.get<ProductsResponse>(
        endpoint,
        queryParameters: queryParams,
        parser: (json) => ProductsResponse.fromJson(json as Map<String, dynamic>),
      );

      if (result is ApiSuccess<ProductsResponse>) {
        // Cache products locally for offline viewing
        _cacheProducts(result.data.products);
      }

      return result;
    } catch (e) {
      developer.log('Error fetching products: $e', name: 'ProductService');
      // Fallback to cache on unexpected error
      final cached = _getCachedProducts(skip: skip, limit: limit, search: search, category: category);
      if (cached != null && cached.products.isNotEmpty) {
        return ApiSuccess(cached);
      }
      return ApiFailure(message: 'Failed to load products: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<Product>> getProductDetails(int id) async {
    final isOnline = await _networkInfo.isConnected;

    if (!isOnline) {
      // Check local cached products
      final cachedList = _storageService.getCachedProductsJson();
      final match = cachedList.firstWhere(
        (p) => p['id'] == id,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        return ApiSuccess(Product.fromJson(match));
      }
      return const ApiFailure(
        message: 'Product details not cached. Please connect to the internet.',
      );
    }

    return _apiClient.get<Product>(
      ApiEndpoints.productDetails(id),
      parser: (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<List<String>> getCategories() async {
    final isOnline = await _networkInfo.isConnected;

    if (!isOnline) {
      final cached = _storageService.getCachedCategories();
      return cached.isNotEmpty ? ['All', ...cached] : ['All'];
    }

    try {
      final result = await _apiClient.get<List<String>>(
        ApiEndpoints.categories,
        parser: (json) {
          if (json is List) {
            return json.map((item) {
              if (item is Map) {
                return item['slug']?.toString() ?? item['name']?.toString() ?? '';
              }
              return item.toString();
            }).where((s) => s.isNotEmpty).toList();
          }
          return <String>[];
        },
      );

      if (result is ApiSuccess<List<String>>) {
        final list = result.data;
        await _storageService.saveCachedCategories(list);
        return ['All', ...list];
      }
    } catch (e) {
      developer.log('Error fetching categories: $e', name: 'ProductService');
    }

    final cached = _storageService.getCachedCategories();
    return cached.isNotEmpty ? ['All', ...cached] : ['All'];
  }

  void _cacheProducts(List<Product> newProducts) {
    try {
      final existingJson = _storageService.getCachedProductsJson();
      final Map<int, Map<String, dynamic>> map = {
        for (var p in existingJson) (p['id'] as int): p,
      };

      for (var p in newProducts) {
        map[p.id] = p.toJson();
      }

      _storageService.saveCachedProductsJson(map.values.toList());
    } catch (e) {
      developer.log('Error caching products: $e', name: 'ProductService');
    }
  }

  ProductsResponse? _getCachedProducts({
    int skip = 0,
    int limit = 10,
    String? search,
    String? category,
  }) {
    try {
      final rawList = _storageService.getCachedProductsJson();
      if (rawList.isEmpty) return null;

      var products = rawList.map((e) => Product.fromJson(e)).toList();

      if (category != null && category.isNotEmpty && category != 'All') {
        products = products
            .where((p) => p.category.toLowerCase() == category.toLowerCase())
            .toList();
      }

      if (search != null && search.trim().isNotEmpty) {
        final query = search.trim().toLowerCase();
        products = products
            .where((p) =>
                p.title.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query) ||
                p.brand.toLowerCase().contains(query))
            .toList();
      }

      final total = products.length;
      final paged = products.skip(skip).take(limit).toList();

      return ProductsResponse(
        products: paged,
        total: total,
        skip: skip,
        limit: limit,
      );
    } catch (e) {
      developer.log('Error reading cached products: $e', name: 'ProductService');
      return null;
    }
  }
}
