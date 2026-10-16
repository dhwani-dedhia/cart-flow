class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://dummyjson.com';

  // Products
  static const String products = '/products';
  static const String searchProducts = '/products/search';
  static const String categories = '/products/categories';
  static String productDetails(int id) => '/products/$id';
  static String productsByCategory(String category) => '/products/category/$category';

  // Cart / Orders
  static const String addCart = '/carts/add';
  static String userCarts(int userId) => '/carts/user/$userId';
}
