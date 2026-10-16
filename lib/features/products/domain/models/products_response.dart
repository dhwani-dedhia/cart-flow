import 'package:equatable/equatable.dart';
import 'product.dart';

class ProductsResponse extends Equatable {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  const ProductsResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['products'] as List<dynamic>? ?? [];
    final products = rawList
        .whereType<Map<String, dynamic>>()
        .map((p) => Product.fromJson(p))
        .toList();

    return ProductsResponse(
      products: products,
      total: json['total'] as int? ?? products.length,
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? products.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((p) => p.toJson()).toList(),
      'total': total,
      'skip': skip,
      'limit': limit,
    };
  }

  @override
  List<Object?> get props => [products, total, skip, limit];
}
