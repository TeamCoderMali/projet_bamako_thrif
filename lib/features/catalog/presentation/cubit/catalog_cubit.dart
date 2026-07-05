// ─── Bamako Thrift — Catalog Cubit & State ─────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/repositories/product_repository.dart';

// ── Filter params ──────────────────────────────────────────────────────────
class CatalogFilter extends Equatable {
  final ProductCategory? category;
  final ProductCondition? condition;
  final double? minPrice;
  final double? maxPrice;
  final String? searchQuery;
  final String? brand;
  final String? size;

  const CatalogFilter({
    this.category,
    this.condition,
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
    this.brand,
    this.size,
  });

  bool get hasActiveFilters =>
      category != null ||
      condition != null ||
      minPrice != null ||
      maxPrice != null ||
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      brand != null ||
      size != null;

  CatalogFilter copyWith({
    ProductCategory? category,
    ProductCondition? condition,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String? brand,
    String? size,
  }) {
    return CatalogFilter(
      category: category ?? this.category,
      condition: condition ?? this.condition,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      searchQuery: searchQuery ?? this.searchQuery,
      brand: brand ?? this.brand,
      size: size ?? this.size,
    );
  }

  @override
  List<Object?> get props => [category, condition, minPrice, maxPrice, searchQuery, brand, size];
}

// ── States ─────────────────────────────────────────────────────────────────
abstract class CatalogState extends Equatable {
  const CatalogState();
  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {
  const CatalogInitial();
}

class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

class CatalogLoaded extends CatalogState {
  final List<ProductEntity> products;
  final CatalogFilter filter;
  final bool hasMore;
  final int currentPage;

  const CatalogLoaded({
    required this.products,
    required this.filter,
    this.hasMore = true,
    this.currentPage = 0,
  });

  @override
  List<Object?> get props => [products, filter, hasMore, currentPage];

  CatalogLoaded copyWith({
    List<ProductEntity>? products,
    CatalogFilter? filter,
    bool? hasMore,
    int? currentPage,
  }) {
    return CatalogLoaded(
      products: products ?? this.products,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class CatalogError extends CatalogState {
  final String message;
  const CatalogError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class CatalogCubit extends Cubit<CatalogState> {
  final ProductRepository _repository;
  CatalogFilter _currentFilter = const CatalogFilter();

  CatalogCubit({required ProductRepository repository})
      : _repository = repository,
        super(const CatalogInitial());

  Future<void> loadCatalog({bool refresh = false}) async {
    if (refresh) {
      _currentFilter = const CatalogFilter();
      emit(const CatalogLoading());
    } else {
      emit(const CatalogLoading());
    }
    try {
      final products = await _repository.getProducts(
        category: _currentFilter.category,
        minPrice: _currentFilter.minPrice,
        maxPrice: _currentFilter.maxPrice,
        searchQuery: _currentFilter.searchQuery,
      );
      emit(CatalogLoaded(
        products: products,
        filter: _currentFilter,
        hasMore: products.length == 20,
      ));
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> applyFilter(CatalogFilter filter) async {
    _currentFilter = filter;
    await loadCatalog();
  }

  Future<void> clearFilters() async {
    _currentFilter = const CatalogFilter();
    await loadCatalog();
  }

  Future<void> search(String query) async {
    _currentFilter = _currentFilter.copyWith(searchQuery: query);
    await loadCatalog();
  }

  Future<void> loadNextPage() async {
    final current = state;
    if (current is! CatalogLoaded || !current.hasMore) return;
    try {
      final more = await _repository.getProducts(
        page: current.currentPage + 1,
        category: _currentFilter.category,
        searchQuery: _currentFilter.searchQuery,
      );
      emit(current.copyWith(
        products: [...current.products, ...more],
        hasMore: more.length == 20,
        currentPage: current.currentPage + 1,
      ));
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }
}
