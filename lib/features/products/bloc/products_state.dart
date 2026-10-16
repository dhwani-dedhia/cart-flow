import 'package:equatable/equatable.dart';
import '../domain/models/product.dart';

enum ProductsStatus {
  initial,
  loading,
  success,
  loadingMore,
  failure,
  empty,
}

class ProductsState extends Equatable {
  final ProductsStatus status;
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;
  final bool hasMore;
  final String searchQuery;
  final String selectedCategory;
  final List<String> categories;
  final String? errorMessage;
  final bool isFromCache;

  const ProductsState({
    this.status = ProductsStatus.initial,
    this.products = const [],
    this.total = 0,
    this.skip = 0,
    this.limit = 10,
    this.hasMore = true,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.categories = const ['All'],
    this.errorMessage,
    this.isFromCache = false,
  });

  bool get isLoading => status == ProductsStatus.loading;
  bool get isLoadingMore => status == ProductsStatus.loadingMore;
  bool get isSuccess => status == ProductsStatus.success;
  bool get isFailure => status == ProductsStatus.failure;
  bool get isEmpty => status == ProductsStatus.empty;

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    int? total,
    int? skip,
    int? limit,
    bool? hasMore,
    String? searchQuery,
    String? selectedCategory,
    List<String>? categories,
    String? errorMessage,
    bool? isFromCache,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      total: total ?? this.total,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        total,
        skip,
        limit,
        hasMore,
        searchQuery,
        selectedCategory,
        categories,
        errorMessage,
        isFromCache,
      ];
}
