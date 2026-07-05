// ─── Bamako Thrift — Publish Entity (Domain Layer) ─────────────────────────
import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';

/// Entité de publication d'article — représente le formulaire/draft
/// avant de créer un ProductEntity final.
class PublishDraftEntity extends Equatable {
  final String? id;
  final String title;
  final String description;
  final double? price;
  final List<String> imagesPaths; // chemins locaux avant upload
  final List<String>? uploadedImageUrls; // URLs après upload
  final ProductCategory? category;
  final ProductCondition? condition;
  final String? brand;
  final String? size;
  final String? color;
  final String? location;
  final bool isDraft;

  const PublishDraftEntity({
    this.id,
    this.title = '',
    this.description = '',
    this.price,
    this.imagesPaths = const [],
    this.uploadedImageUrls,
    this.category,
    this.condition,
    this.brand,
    this.size,
    this.color,
    this.location,
    this.isDraft = true,
  });

  bool get isReadyToPublish =>
      title.isNotEmpty &&
      description.isNotEmpty &&
      price != null &&
      price! > 0 &&
      imagesPaths.isNotEmpty &&
      category != null &&
      condition != null;

  PublishDraftEntity copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    List<String>? imagesPaths,
    List<String>? uploadedImageUrls,
    ProductCategory? category,
    ProductCondition? condition,
    String? brand,
    String? size,
    String? color,
    String? location,
    bool? isDraft,
  }) {
    return PublishDraftEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imagesPaths: imagesPaths ?? this.imagesPaths,
      uploadedImageUrls: uploadedImageUrls ?? this.uploadedImageUrls,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      color: color ?? this.color,
      location: location ?? this.location,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  @override
  List<Object?> get props => [
        id, title, description, price, imagesPaths, category, condition,
      ];
}
