// ─── Bamako Thrift — Product Repository Implementation (stub) ──────────────
// TODO: Implémenter avec Firestore
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  // TODO: Injecter ProductRemoteDataSource via get_it

  @override
  Future<List<ProductEntity>> getProducts({
    int page = 0,
    int limit = 20,
    ProductCategory? category,
    ProductCondition? condition,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String? sellerId,
  }) {
    throw UnimplementedError('getProducts not yet implemented');
  }

  @override
  Future<ProductEntity> getProductById(String id) {
    throw UnimplementedError('getProductById not yet implemented');
  }

  @override
  Future<ProductEntity> createProduct(ProductEntity product) {
    throw UnimplementedError('createProduct not yet implemented');
  }

  @override
  Future<ProductEntity> updateProduct(ProductEntity product) {
    throw UnimplementedError('updateProduct not yet implemented');
  }

  @override
  Future<void> deleteProduct(String id) {
    throw UnimplementedError('deleteProduct not yet implemented');
  }

  @override
  Future<List<ProductEntity>> searchProducts(String query) {
    throw UnimplementedError('searchProducts not yet implemented');
  }

  @override
  Future<void> addToFavorites(String productId) {
    throw UnimplementedError('addToFavorites not yet implemented');
  }

  @override
  Future<void> removeFromFavorites(String productId) {
    throw UnimplementedError('removeFromFavorites not yet implemented');
  }

  @override
  Future<List<ProductEntity>> getFavorites() {
    throw UnimplementedError('getFavorites not yet implemented');
  }

  @override
  Future<void> incrementViewCount(String productId) {
    throw UnimplementedError('incrementViewCount not yet implemented');
  }

  @override
  Stream<List<ProductEntity>> watchProducts({ProductCategory? category}) {
    throw UnimplementedError('watchProducts not yet implemented');
  }
}
