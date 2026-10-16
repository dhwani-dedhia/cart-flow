import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/models/product.dart';
import '../domain/services/product_service.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final ProductService _productService;
  Timer? _debounceTimer;

  ProductsCubit({required ProductService productService})
      : _productService = productService,
        super(const ProductsState());

  Future<void> initialize() async {
    await loadCategories();
    await loadProducts();
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      emit(state.copyWith(categories: categories));
    } catch (_) {}
  }

  Future<void> loadProducts({bool isRefresh = false}) async {
    if (state.isLoading) return;

    final skip = isRefresh ? 0 : 0;
    emit(state.copyWith(
      status: ProductsStatus.loading,
      skip: skip,
      errorMessage: null,
    ));

    final result = await _productService.getProducts(
      skip: 0,
      limit: state.limit,
      search: state.searchQuery,
      category: state.selectedCategory,
    );

    result.when(
      success: (response) {
        if (response.products.isEmpty) {
          emit(state.copyWith(
            status: ProductsStatus.empty,
            products: [],
            total: 0,
            skip: 0,
            hasMore: false,
          ));
        } else {
          final hasMore = (response.products.length + 0) < response.total;
          emit(state.copyWith(
            status: ProductsStatus.success,
            products: response.products,
            total: response.total,
            skip: response.products.length,
            hasMore: hasMore,
          ));
        }
      },
      failure: (message, statusCode, error) {
        emit(state.copyWith(
          status: ProductsStatus.failure,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> loadMoreProducts() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    emit(state.copyWith(status: ProductsStatus.loadingMore));

    final nextSkip = state.skip;
    final result = await _productService.getProducts(
      skip: nextSkip,
      limit: state.limit,
      search: state.searchQuery,
      category: state.selectedCategory,
    );

    result.when(
      success: (response) {
        final combined = List<Product>.from(state.products)
          ..addAll(response.products);
        final hasMore = combined.length < response.total && response.products.isNotEmpty;

        emit(state.copyWith(
          status: ProductsStatus.success,
          products: combined,
          total: response.total,
          skip: combined.length,
          hasMore: hasMore,
        ));
      },
      failure: (message, statusCode, error) {
        emit(state.copyWith(
          status: ProductsStatus.success, // keep showing existing products
          errorMessage: 'Failed to load more: $message',
        ));
      },
    );
  }

  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (query.trim() == state.searchQuery) return;
      emit(state.copyWith(searchQuery: query.trim()));
      loadProducts(isRefresh: true);
    });
  }

  void onCategorySelected(String category) {
    if (category == state.selectedCategory) return;
    emit(state.copyWith(
      selectedCategory: category,
      searchQuery: '', // reset search when category changes
    ));
    loadProducts(isRefresh: true);
  }

  void retry() {
    loadProducts(isRefresh: true);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
