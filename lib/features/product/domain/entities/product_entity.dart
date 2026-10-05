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
  final bool verifie;
  final int viewCount;
  final int favoriteCount;
  final String? location;
  final double rating;
  final int reviewCount;
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
    this.verifie = false,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.location,
    this.rating = 0,
    this.reviewCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => status == ProductStatus.available;
  String? get mainImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  @override
  List<Object?> get props => [
        id, sellerId, title, description, price, imageUrls,
        category, condition, brand, size, color, status, verifie,
        viewCount, favoriteCount, rating, reviewCount, createdAt, updatedAt,
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

/// Libellé affiché, centralisé ici (même principe que
/// ProductConditionLabel) pour éviter les copies divergentes entre écrans
/// (ex. "Tradition" vs "Traditionnel" trouvé lors de l'audit du lot 8).
/// N'affecte jamais le filtrage (basé sur la valeur d'enum, pas le texte).
extension ProductCategoryLabel on ProductCategory {
  String get label => switch (this) {
        ProductCategory.women => 'Femmes',
        ProductCategory.men => 'Hommes',
        ProductCategory.children => 'Enfants',
        ProductCategory.shoes => 'Chaussures',
        ProductCategory.accessories => 'Accessoires',
        ProductCategory.bags => 'Sacs',
        ProductCategory.jewelry => 'Bijoux',
        ProductCategory.sportswear => 'Sports',
        ProductCategory.traditional => 'Tenues traditionnelles',
        ProductCategory.other => 'Autres',
      };
}

enum ProductCondition {
  satisfaisant,       // État satisfaisant — porté, quelques signes d'usure visibles
  bon,                // Bon état — légèrement porté, très bon aspect général
  tresSatisfaisant,   // Très satisfaisant — quasi neuf, porté très peu de fois
  neufAvecEtiquette,  // État 99 avec étiquette — jamais porté, étiquette d'origine présente
}

/// Libellé affiché, centralisé ici pour éviter les copies divergentes
/// entre écrans. La valeur stockée en Firestore reste le nom de l'enum.
extension ProductConditionLabel on ProductCondition {
  String get label => switch (this) {
        ProductCondition.satisfaisant => 'Satisfaisant',
        ProductCondition.bon => 'Bon état',
        ProductCondition.tresSatisfaisant => 'Très bon état',
        ProductCondition.neufAvecEtiquette => 'Neuf avec étiquette',
      };
}

enum ProductStatus {
  available,            // Disponible
  reserved,             // Réservé
  sold,                 // Vendu
  inactive,             // Inactif (masqué par le vendeur)
  pending,              // En attente de validation admin
  rejected,             // Rejeté par l'admin
  enAttenteVerification, // En cours de vérification/remise en état (pressing)
}
