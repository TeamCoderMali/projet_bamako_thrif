// ─── Bamako Thrift — Product Entity (Domain Layer) ─────────────────────────
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;
  // Ville du vendeur au moment de la publication (copie de users/{uid}.city,
  // liste fixe — lot 6, 2026-10-15). Même principe que sellerName/
  // sellerAvatarUrl : dénormalisé pour éviter une lecture par carte article.
  final String? sellerCity;
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
  // Le vendeur peut désactiver les offres de prix sur son article ("Faire
  // une offre", lot offres). Défaut = autorisé : Fatou n'a pas encore
  // décidé du défaut produit, mais un article publié sans ce champ (tous
  // les articles existants) doit rester négociable plutôt que de bloquer
  // silencieusement une fonctionnalité pas encore annoncée aux vendeurs.
  final bool offersEnabled;
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
    this.sellerCity,
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
    this.offersEnabled = true,
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
        offersEnabled, viewCount, favoriteCount, rating, reviewCount,
        createdAt, updatedAt,
      ];
}

enum ProductCategory {
  men,
  women,
  children,
  shoes,
  accessories,
  // bags/jewelry : fusion cosmétique dans Accessoires (lot 2, 2026-10-12).
  // Gardées comme valeurs d'enum valides pour ne pas perdre les articles
  // déjà publiés sous ces catégories (aucune migration de données) ; ne
  // sont simplement plus proposées dans les sélecteurs, voir
  // selectableProductCategories ci-dessous. Le filtrage par "Accessoires"
  // doit matcher les 3 valeurs (whereIn), pas seulement `accessories`.
  bags,
  jewelry,
  sportswear,
  traditional,
  beauty,
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
        ProductCategory.beauty => 'Beauté',
        ProductCategory.other => 'Autres',
      };
}

/// Catégories proposées à l'utilisateur (formulaire de vente et filtres),
/// dans l'ordre d'affichage — centralisé ici pour que
/// publish_product_page.dart et filter_page.dart restent synchronisés
/// (lot 2, 2026-10-12 ; même risque de divergence déjà trouvé au lot 8).
/// "Sacs" et "Bijoux" n'y figurent plus (fusionnés dans "Accessoires"),
/// mais les articles existants sous ces catégories restent affichés :
/// voir productCategoriesFor() dans product_remote_datasource_impl.dart
/// pour le whereIn qui les inclut toujours au filtrage.
const List<ProductCategory> selectableProductCategories = [
  ProductCategory.women,
  ProductCategory.men,
  ProductCategory.children,
  ProductCategory.shoes,
  ProductCategory.accessories,
  ProductCategory.beauty,
  ProductCategory.sportswear,
  ProductCategory.traditional,
  ProductCategory.other,
];

/// Valeurs Firestore (`category.name`) à matcher pour filtrer sur [category]
/// — un filtre "Accessoires" doit aussi inclure les anciens articles postés
/// sous "Sacs"/"Bijoux" avant la fusion cosmétique (lot 2), d'où plusieurs
/// valeurs pour ce seul cas. Utilisé avec `whereIn` côté requête Firestore
/// quand la liste a plus d'un élément, `isEqualTo` sinon.
List<String> productCategoriesFor(ProductCategory category) =>
    switch (category) {
      ProductCategory.accessories => [
          ProductCategory.accessories.name,
          ProductCategory.bags.name,
          ProductCategory.jewelry.name,
        ],
      _ => [category.name],
    };

enum ProductCondition {
  satisfaisant,       // État satisfaisant — porté, quelques signes d'usure visibles
  bon,                // Bon état — légèrement porté, très bon aspect général
  tresSatisfaisant,   // Très satisfaisant — quasi neuf, porté très peu de fois
  neufSansEtiquette,  // Neuf sans étiquette — jamais porté, étiquette d'origine absente (lot 2)
  neufAvecEtiquette,  // État 99 avec étiquette — jamais porté, étiquette d'origine présente
}

/// Libellé affiché, centralisé ici pour éviter les copies divergentes
/// entre écrans. La valeur stockée en Firestore reste le nom de l'enum.
extension ProductConditionLabel on ProductCondition {
  String get label => switch (this) {
        ProductCondition.satisfaisant => 'Satisfaisant',
        ProductCondition.bon => 'Bon état',
        ProductCondition.tresSatisfaisant => 'Très bon état',
        ProductCondition.neufSansEtiquette => 'Neuf sans étiquette',
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
