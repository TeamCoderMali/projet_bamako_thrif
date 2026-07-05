// ─── Bamako Thrift — Product Entity (Domain Layer) ─────────────────────────
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;
  final String title;
  final String description;
  final double price;
  final List<String> imageUrls;
  final ProductCategory category;
  final ProductCondition condition;
  final String? brand;
  final String? size;
  final String? color;
  final ProductStatus status;
  final int viewCount;
  final int favoriteCount;
  final String? location;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductEntity({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatarUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.category,
    required this.condition,
    this.brand,
    this.size,
    this.color,
    this.status = ProductStatus.available,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.location,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => status == ProductStatus.available;
  String? get mainImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  @override
  List<Object?> get props => [
        id, sellerId, title, description, price, imageUrls,
        category, condition, brand, size, color, status,
        viewCount, favoriteCount, createdAt, updatedAt,
      ];
}

enum ProductCategory {
  men,
  women,
  children,
  shoes,
  accessories,
  bags,
  jewelry,
  sportswear,
  traditional,
  other,
}

enum ProductCondition {
  newWithTags,    // Neuf avec étiquettes
  newWithoutTags, // Neuf sans étiquettes
  veryGood,       // Très bon état
  good,           // Bon état
  fair,           // État correct
}

enum ProductStatus {
  available,   // Disponible
  reserved,    // Réservé
  sold,        // Vendu
  inactive,    // Inactif (masqué par le vendeur)
  pending,     // En attente de validation admin
  rejected,    // Rejeté par l'admin
}
