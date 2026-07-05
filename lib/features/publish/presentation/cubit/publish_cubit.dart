// ─── Bamako Thrift — Publish Cubit & State ─────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/repositories/product_repository.dart';
import '../../domain/entities/publish_draft_entity.dart';

// ── States ─────────────────────────────────────────────────────────────────
abstract class PublishState extends Equatable {
  const PublishState();
  @override
  List<Object?> get props => [];
}

class PublishInitial extends PublishState {
  const PublishInitial();
}

class PublishDraftUpdated extends PublishState {
  final PublishDraftEntity draft;
  const PublishDraftUpdated(this.draft);
  @override
  List<Object?> get props => [draft];
}

class PublishUploading extends PublishState {
  final double progress; // 0.0 → 1.0
  const PublishUploading(this.progress);
  @override
  List<Object?> get props => [progress];
}

class PublishSuccess extends PublishState {
  final ProductEntity product;
  const PublishSuccess(this.product);
  @override
  List<Object?> get props => [product];
}

class PublishError extends PublishState {
  final String message;
  const PublishError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class PublishCubit extends Cubit<PublishState> {
  final ProductRepository _productRepository;
  PublishDraftEntity _draft = const PublishDraftEntity();

  PublishCubit({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(const PublishInitial());

  void updateTitle(String value) =>
      _updateDraft(_draft.copyWith(title: value));

  void updateDescription(String value) =>
      _updateDraft(_draft.copyWith(description: value));

  void updatePrice(double value) =>
      _updateDraft(_draft.copyWith(price: value));

  void updateCategory(ProductCategory value) =>
      _updateDraft(_draft.copyWith(category: value));

  void updateCondition(ProductCondition value) =>
      _updateDraft(_draft.copyWith(condition: value));

  void updateBrand(String? value) =>
      _updateDraft(_draft.copyWith(brand: value));

  void updateSize(String? value) =>
      _updateDraft(_draft.copyWith(size: value));

  void updateColor(String? value) =>
      _updateDraft(_draft.copyWith(color: value));

  void updateLocation(String? value) =>
      _updateDraft(_draft.copyWith(location: value));

  void addImage(String path) {
    final paths = List<String>.from(_draft.imagesPaths)..add(path);
    _updateDraft(_draft.copyWith(imagesPaths: paths));
  }

  void removeImage(int index) {
    final paths = List<String>.from(_draft.imagesPaths)..removeAt(index);
    _updateDraft(_draft.copyWith(imagesPaths: paths));
  }

  void _updateDraft(PublishDraftEntity draft) {
    _draft = draft;
    emit(PublishDraftUpdated(draft));
  }

  Future<void> publish({required String sellerId, required String sellerName}) async {
    if (!_draft.isReadyToPublish) {
      emit(const PublishError('Veuillez remplir tous les champs requis'));
      return;
    }
    emit(const PublishUploading(0.0));
    try {
      // TODO: Upload images first, then create product
      // For now creating product directly
      final product = ProductEntity(
        id: '',
        sellerId: sellerId,
        sellerName: sellerName,
        title: _draft.title,
        description: _draft.description,
        price: _draft.price!,
        imageUrls: _draft.uploadedImageUrls ?? [],
        category: _draft.category!,
        condition: _draft.condition!,
        brand: _draft.brand,
        size: _draft.size,
        color: _draft.color,
        location: _draft.location,
        createdAt: DateTime.now(),
      );
      final created = await _productRepository.createProduct(product);
      emit(PublishSuccess(created));
    } catch (e) {
      emit(PublishError(e.toString()));
    }
  }

  void reset() {
    _draft = const PublishDraftEntity();
    emit(const PublishInitial());
  }
}
