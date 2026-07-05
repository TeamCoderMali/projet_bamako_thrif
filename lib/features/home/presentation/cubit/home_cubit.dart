// ─── Bamako Thrift — Home Cubit & State ────────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/repositories/product_repository.dart';

// ── State ──────────────────────────────────────────────────────────────────
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<ProductEntity> featured;     // Coups de cœur
  final List<ProductEntity> recentlyAdded; // Nouveautés
  final List<ProductEntity> nearbyItems;   // Autour de moi
  final List<ProductCategory> trendingCategories;

  const HomeLoaded({
    required this.featured,
    required this.recentlyAdded,
    required this.nearbyItems,
    required this.trendingCategories,
  });

  @override
  List<Object?> get props => [featured, recentlyAdded, nearbyItems, trendingCategories];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class HomeCubit extends Cubit<HomeState> {
  final ProductRepository _productRepository;

  HomeCubit({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(const HomeInitial());

  Future<void> loadHome() async {
    emit(const HomeLoading());
    try {
      // Parallel loading of home sections
      final results = await Future.wait([
        _productRepository.getProducts(limit: 8),             // featured
        _productRepository.getProducts(limit: 12),            // recent
        _productRepository.getProducts(limit: 6),             // nearby
      ]);

      emit(HomeLoaded(
        featured: results[0],
        recentlyAdded: results[1],
        nearbyItems: results[2],
        trendingCategories: const [
          ProductCategory.women,
          ProductCategory.men,
          ProductCategory.shoes,
          ProductCategory.accessories,
          ProductCategory.bags,
        ],
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> refresh() => loadHome();
}
