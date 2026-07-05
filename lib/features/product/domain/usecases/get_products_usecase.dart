// ─── Bamako Thrift — Get Products UseCase ─────────────────────────────────
import '../../../../core/utils/use_case.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase extends UseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository _repository;
  GetProductsUseCase(this._repository);

  @override
  Future<List<ProductEntity>> call(GetProductsParams params) {
    return _repository.getProducts(
      page: params.page,
      limit: params.limit,
      category: params.category,
      condition: params.condition,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      searchQuery: params.searchQuery,
    );
  }
}

class GetProductsParams {
  final int page;
  final int limit;
  final ProductCategory? category;
  final ProductCondition? condition;
  final double? minPrice;
  final double? maxPrice;
  final String? searchQuery;

  const GetProductsParams({
    this.page = 0,
    this.limit = 20,
    this.category,
    this.condition,
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
  });
}
