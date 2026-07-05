// ─── Bamako Thrift — Product Model (Data Layer) ────────────────────────────
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.sellerId,
    required super.sellerName,
    super.sellerAvatarUrl,
    required super.title,
    required super.description,
    required super.price,
    required super.imageUrls,
    required super.category,
    required super.condition,
    super.brand,
    super.size,
    super.color,
    super.status,
    super.viewCount,
    super.favoriteCount,
    super.location,
    required super.createdAt,
    super.updatedAt,
  });

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      sellerId: data['sellerId'] as String,
      sellerName: data['sellerName'] as String,
      sellerAvatarUrl: data['sellerAvatarUrl'] as String?,
      title: data['title'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      category: _parseCategory(data['category'] as String?),
      condition: _parseCondition(data['condition'] as String?),
      brand: data['brand'] as String?,
      size: data['size'] as String?,
      color: data['color'] as String?,
      status: _parseStatus(data['status'] as String?),
      viewCount: data['viewCount'] as int? ?? 0,
      favoriteCount: data['favoriteCount'] as int? ?? 0,
      location: data['location'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int? ?? 0,
      ),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAvatarUrl': sellerAvatarUrl,
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'category': category.name,
      'condition': condition.name,
      'brand': brand,
      'size': size,
      'color': color,
      'status': status.name,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'location': location,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  static ProductCategory _parseCategory(String? value) {
    return ProductCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProductCategory.other,
    );
  }

  static ProductCondition _parseCondition(String? value) {
    return ProductCondition.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProductCondition.good,
    );
  }

  static ProductStatus _parseStatus(String? value) {
    return ProductStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProductStatus.available,
    );
  }
}
