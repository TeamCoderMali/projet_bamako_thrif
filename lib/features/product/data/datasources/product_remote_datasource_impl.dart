// ─── Bamako Thrift — Product Remote DataSource (Firestore) ─────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product_entity.dart';
import '../models/product_model.dart';
import 'product_remote_datasource.dart';

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProductRemoteDataSourceImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _firestore.collection('product');

  // ── Récupérer les produits avec filtres ──────────────────────────────────
  @override
  Future<List<ProductModel>> getProducts({
    int page = 0,
    int limit = 20,
    ProductCategory? category,
    ProductCondition? condition,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String? sellerId,
  }) async {
    // ── Requête Firestore : uniquement filtres d'égalité + orderBy ────────
    // Les filtres de range (price) sont faits côté client pour éviter
    // l'erreur "inequality filters on multiple fields" de Firestore.
    Query<Map<String, dynamic>> query = _productsCol
        .where('status', isEqualTo: ProductStatus.available.name)
        .orderBy('createdAt', descending: true)
        .limit(minPrice != null || maxPrice != null ? 200 : limit);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (condition != null) {
      query = query.where('condition', isEqualTo: condition.name);
    }
    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }

    // Pagination
    if (page > 0) {
      final allDocs = await _productsCol
          .where('status', isEqualTo: ProductStatus.available.name)
          .orderBy('createdAt', descending: true)
          .limit(page * limit)
          .get();
      if (allDocs.docs.isEmpty) return [];
      query = query.startAfterDocument(allDocs.docs.last);
    }

    final snapshot = await query.get();
    var results = snapshot.docs.map((doc) {
      final data = _convertTimestamps(doc.data());
      return ProductModel.fromFirestore(data, doc.id);
    }).toList();

    // ── Filtrage prix côté client ─────────────────────────────────────────
    if (minPrice != null) {
      results = results.where((p) => p.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      results = results.where((p) => p.price <= maxPrice).toList();
    }

    // Respecter la limite après filtrage côté client
    if (results.length > limit) {
      results = results.take(limit).toList();
    }

    return results;
  }

  // ── Récupérer un produit par ID ──────────────────────────────────────────
  @override
  Future<ProductModel> getProductById(String id) async {
    final doc = await _productsCol.doc(id).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Produit introuvable.');
    }
    final data = _convertTimestamps(doc.data()!);
    return ProductModel.fromFirestore(data, doc.id);
  }

  // ── Créer un produit ─────────────────────────────────────────────────────
  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    final data = product.toFirestore();
    // Utiliser serverTimestamp pour createdAt
    data['createdAt'] = FieldValue.serverTimestamp();
    data.remove('updatedAt');

    final docRef = await _productsCol.add(data);
    final created = await docRef.get();
    final createdData = _convertTimestamps(created.data()!);
    return ProductModel.fromFirestore(createdData, docRef.id);
  }

  // ── Mettre à jour un produit ─────────────────────────────────────────────
  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    final data = product.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _productsCol.doc(product.id).update(data);
    return product;
  }

  // ── Supprimer un produit ─────────────────────────────────────────────────
  @override
  Future<void> deleteProduct(String id) async {
    await _productsCol.doc(id).delete();
  }

  // ── Recherche (client-side sur title + description) ──────────────────────
  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    final snapshot = await _productsCol
        .where('status', isEqualTo: ProductStatus.available.name)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) {
          final data = _convertTimestamps(doc.data());
          return ProductModel.fromFirestore(data, doc.id);
        })
        .where((p) =>
            p.title.toLowerCase().contains(lowerQuery) ||
            p.description.toLowerCase().contains(lowerQuery) ||
            (p.brand?.toLowerCase().contains(lowerQuery) ?? false))
        .toList();
  }

  // ── Favoris ──────────────────────────────────────────────────────────────
  @override
  Future<void> addToFavorites(String productId, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .set({
      'productId': productId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeFromFavorites(String productId, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId)
        .delete();
  }

  @override
  Future<List<ProductModel>> getFavorites(String userId) async {
    final favSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();

    final productIds = favSnapshot.docs.map((d) => d.id).toList();
    if (productIds.isEmpty) return [];

    final products = await Future.wait(
      productIds.map((id) => getProductById(id).catchError((_) async =>
          throw Exception('Product $id not found'))),
    );
    return products.cast<ProductModel>();
  }

  // ── Incrémenter le compteur de vues ─────────────────────────────────────
  @override
  Future<void> incrementViewCount(String productId) async {
    await _productsCol.doc(productId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // ── Stream produits en temps réel ────────────────────────────────────────
  @override
  Stream<List<ProductModel>> watchProducts({ProductCategory? category}) {
    Query<Map<String, dynamic>> query = _productsCol
        .where('status', isEqualTo: ProductStatus.available.name)
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = _convertTimestamps(doc.data());
        return ProductModel.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  // ── Helper : convertir Timestamps Firestore → int ────────────────────────
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    if (result['createdAt'] is Timestamp) {
      result['createdAt'] =
          (result['createdAt'] as Timestamp).millisecondsSinceEpoch;
    }
    if (result['updatedAt'] is Timestamp) {
      result['updatedAt'] =
          (result['updatedAt'] as Timestamp).millisecondsSinceEpoch;
    }
    return result;
  }
}
