// ─── Bamako Thrift — Product Cubit & State ─────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

// ── States ─────────────────────────────────────────────────────────────────
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

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  ProductCubit({required ProductRepository repository})
      : _repository = repository,
        super(const ProductInitial());

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

  Future<void> loadProductDetail(String id) async {
    emit(const ProductLoading());
    try {
      final product = await _repository.getProductById(id);
      emit(ProductDetailLoaded(product));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> searchProducts(String query) async {
    emit(const ProductLoading());
    try {
      final products = await _repository.searchProducts(query);
      emit(ProductLoaded(products: products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
