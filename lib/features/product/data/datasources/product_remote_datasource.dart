// ─── Bamako Thrift — Product Remote DataSource (stub) ──────────────────────────
import '../models/product_model.dart';
import '../../domain/entities/product_entity.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    int page = 0,
    int limit = 20,
    ProductCategory? category,
    ProductCondition? condition,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String? sellerId,
  });

  Future<ProductModel> getProductById(String id);

  Future<ProductModel> createProduct(ProductModel product);

  Future<ProductModel> updateProduct(ProductModel product);

  Future<void> deleteProduct(String id);

  Future<List<ProductModel>> searchProducts(String query);

  Future<void> addToFavorites(String productId, String userId);

  Future<void> removeFromFavorites(String productId, String userId);

  Future<List<ProductModel>> getFavorites(String userId);

  Future<void> incrementViewCount(String productId);

  Stream<List<ProductModel>> watchProducts({ProductCategory? category});
}
