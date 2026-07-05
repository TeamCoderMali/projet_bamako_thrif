// ─── Bamako Thrift — Product Repository (Domain Contract) ──────────────────
import '../entities/product_entity.dart';

abstract class ProductRepository {
  /// Récupère les produits avec pagination et filtres optionnels.
  Future<List<ProductEntity>> getProducts({
    int page = 0,
    int limit = 20,
    ProductCategory? category,
    ProductCondition? condition,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String? sellerId,
  });

  /// Récupère un produit par son ID.
  Future<ProductEntity> getProductById(String id);

  /// Crée un nouveau produit.
  Future<ProductEntity> createProduct(ProductEntity product);

  /// Met à jour un produit existant.
  Future<ProductEntity> updateProduct(ProductEntity product);

  /// Supprime un produit.
  Future<void> deleteProduct(String id);

  /// Recherche de produits.
  Future<List<ProductEntity>> searchProducts(String query);

  /// Ajoute un produit aux favoris.
  Future<void> addToFavorites(String productId);

  /// Retire un produit des favoris.
  Future<void> removeFromFavorites(String productId);

  /// Récupère les favoris de l'utilisateur.
  Future<List<ProductEntity>> getFavorites();

  /// Incrémente le compteur de vues.
  Future<void> incrementViewCount(String productId);

  /// Stream des produits en temps réel.
  Stream<List<ProductEntity>> watchProducts({ProductCategory? category});
}
