// ─── Bamako Thrift — Product Repository Implementation ─────────────────────
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final String? _currentUserId; // Injecté depuis l'auth

  ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
    String? currentUserId,
  })  : _remoteDataSource = remoteDataSource,
        _currentUserId = currentUserId;

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
  }) async {
    return _remoteDataSource.getProducts(
      page: page,
      limit: limit,
      category: category,
      condition: condition,
      minPrice: minPrice,
      maxPrice: maxPrice,
      searchQuery: searchQuery,
      sellerId: sellerId,
    );
  }

  @override
  Future<ProductEntity> getProductById(String id) {
    return _remoteDataSource.getProductById(id);
  }

  @override
  Future<ProductEntity> createProduct(ProductEntity product) {
    return _remoteDataSource.createProduct(product as ProductModel);
  }

  @override
  Future<ProductEntity> updateProduct(ProductEntity product) {
    return _remoteDataSource.updateProduct(product as ProductModel);
  }

  @override
  Future<void> deleteProduct(String id) {
    return _remoteDataSource.deleteProduct(id);
  }

  @override
  Future<List<ProductEntity>> searchProducts(String query) {
    return _remoteDataSource.searchProducts(query);
  }

  @override
  Future<void> addToFavorites(String productId) {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Utilisateur non connecté.');
    return _remoteDataSource.addToFavorites(productId, uid);
  }

  @override
  Future<void> removeFromFavorites(String productId) {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Utilisateur non connecté.');
    return _remoteDataSource.removeFromFavorites(productId, uid);
  }

  @override
  Future<List<ProductEntity>> getFavorites() {
    final uid = _currentUserId;
    if (uid == null) throw Exception('Utilisateur non connecté.');
    return _remoteDataSource.getFavorites(uid);
  }

  @override
  Future<void> incrementViewCount(String productId) {
    return _remoteDataSource.incrementViewCount(productId);
  }

  @override
  Stream<List<ProductEntity>> watchProducts({ProductCategory? category}) {
    return _remoteDataSource.watchProducts(category: category);
  }
}
