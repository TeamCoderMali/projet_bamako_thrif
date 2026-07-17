// ─── Bamako Thrift — Product Cubit & State ─────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

// ── States ──────────────────────────────────────────────────────────────────
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductLoaded extends ProductState {
  final List<ProductEntity> products;
  final bool hasMore;
  final int currentPage;

  const ProductLoaded({
    required this.products,
    this.hasMore = true,
    this.currentPage = 0,
  });

  @override
  List<Object?> get props => [products, hasMore, currentPage];

  ProductLoaded copyWith({
    List<ProductEntity>? products,
    bool? hasMore,
    int? currentPage,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ProductDetailLoaded extends ProductState {
  final ProductEntity product;
  const ProductDetailLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductPublished extends ProductState {
  final ProductEntity product;
  const ProductPublished(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductSearchResult extends ProductState {
  final List<ProductEntity> results;
  final String query;
  const ProductSearchResult({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}

// ── Cubit ────────────────────────────────────────────────────────────────────
class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  ProductCubit({required ProductRepository repository})
      : _repository = repository,
        super(const ProductInitial());

  // ── Charger les produits ──────────────────────────────────────────────────
  Future<void> loadProducts({
    ProductCategory? category,
    bool refresh = false,
  }) async {
    if (refresh) {
      emit(const ProductLoading());
    }
    try {
      final products = await _repository.getProducts(category: category);
      emit(ProductLoaded(products: products, hasMore: products.length == 20));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  // ── Charger avec filtres avancés ──────────────────────────────────────────
  Future<void> loadProductsWithFilters({
    ProductCategory? category,
    ProductCondition? condition,
    double? minPrice,
    double? maxPrice,
  }) async {
    emit(const ProductLoading());
    try {
      final products = await _repository.getProducts(
        category: category,
        condition: condition,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      emit(ProductLoaded(products: products, hasMore: products.length == 20));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  // ── Charger le détail d'un produit ───────────────────────────────────────
  Future<void> loadProductDetail(String id) async {
    emit(const ProductLoading());
    try {
      final product = await _repository.getProductById(id);
      // Incrémenter les vues en arrière-plan
      _repository.incrementViewCount(id).catchError((_) {});
      emit(ProductDetailLoaded(product));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  // ── Rechercher des produits ─────────────────────────────────────
  Future<void> searchProducts(String query) async {
    emit(const ProductLoading());
    try {
      final products = await _repository.searchProducts(query);
      emit(ProductSearchResult(results: products, query: query));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  // ── Créer un produit ──────────────────────────────────────────────────────
  Future<void> createProduct(ProductEntity product) async {
    emit(const ProductLoading());
    try {
      final created = await _repository.createProduct(product);
      emit(ProductPublished(created));
    } catch (e) {
      emit(ProductError(e.toString()));
      rethrow;
    }
  }

  // ── Ajouter/retirer des favoris ───────────────────────────────────────────
  Future<void> addToFavorites(String productId) async {
    try {
      await _repository.addToFavorites(productId);
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    try {
      await _repository.removeFromFavorites(productId);
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
