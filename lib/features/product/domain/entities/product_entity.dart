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
  // Sous-categorie (ex. "Haut", "Chaussures"...) -- voir subCategoriesFor().
  // Nullable : categories sans sous-categorie (Objets) et anciennes
  // annonces publiees avant la refonte 2026-11-04.
  final String? subCategory;
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
    this.subCategory,
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

  // Mise à jour optimiste côté client (favori, note) sans attendre une
  // relecture Firestore -- voir product_detail_page.dart.
  ProductEntity copyWith({
    int? favoriteCount,
    double? rating,
    int? reviewCount,
  }) {
    return ProductEntity(
      id: id,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerAvatarUrl: sellerAvatarUrl,
      sellerCity: sellerCity,
      title: title,
      description: description,
      price: price,
      imageUrls: imageUrls,
      category: category,
      subCategory: subCategory,
      condition: condition,
      brand: brand,
      size: size,
      color: color,
      status: status,
      verifie: verifie,
      offersEnabled: offersEnabled,
      viewCount: viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      location: location,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, sellerId, title, description, price, imageUrls,
        category, subCategory, condition, brand, size, color, status, verifie,
        offersEnabled, viewCount, favoriteCount, rating, reviewCount,
        createdAt, updatedAt,
      ];
}

// Refonte des catégories du 2026-11-04 (demande Ali) : 5 catégories de
// premier niveau seulement (Sport retiré). Les anciennes catégories de
// premier niveau (shoes/accessories/bags/jewelry/sportswear/traditional)
// deviennent des SOUS-catégories (voir subCategoriesFor ci-dessous) ou
// disparaissent (sportswear). Aucune migration de données : une ancienne
// annonce Firestore portant une de ces anciennes valeurs ne plante pas,
// elle retombe simplement sur `other` (voir ProductModel._parseCategory,
// qui utilise déjà firstWhere(orElse: () => ProductCategory.other)).
// Ali supprimera ces anciennes annonces à la main.
enum ProductCategory {
  femme,
  homme,
  enfant,
  objets,
  beaute,
  other,
}

/// Libellé affiché, centralisé ici (même principe que
/// ProductConditionLabel) pour éviter les copies divergentes entre écrans
/// (ex. "Tradition" vs "Traditionnel" trouvé lors de l'audit du lot 8).
/// N'affecte jamais le filtrage (basé sur la valeur d'enum, pas le texte).
extension ProductCategoryLabel on ProductCategory {
  String get label => switch (this) {
        ProductCategory.femme => 'Femme',
        ProductCategory.homme => 'Homme',
        ProductCategory.enfant => 'Enfant',
        ProductCategory.objets => 'Objets',
        ProductCategory.beaute => 'Beauté',
        ProductCategory.other => 'Autres',
      };
}

/// Catégories proposées à l'utilisateur (formulaire de vente, accueil,
/// catalogue, filtres) — seule source de vérité sur l'ensemble des
/// catégories actives, pour que tous ces écrans restent synchronisés
/// (lot 2, 2026-10-12 ; refonte 2026-11-04). `other` n'y figure pas : ce
/// n'est plus une catégorie proposée à la publication, seulement un repli
/// pour les anciennes annonces (voir commentaire sur l'enum ci-dessus).
const List<ProductCategory> selectableProductCategories = [
  ProductCategory.femme,
  ProductCategory.homme,
  ProductCategory.enfant,
  ProductCategory.objets,
  ProductCategory.beaute,
];

/// Sous-catégories par catégorie (refonte 2026-11-04, demande Ali). Liste
/// vide = catégorie sans sous-catégorie (Objets, et le repli `other`).
/// Stockée telle quelle (String, pas d'enum) dans ProductEntity.subCategory
/// car certaines listes contiennent des parenthèses d'exemples qui ne sont
/// pas un niveau de choix supplémentaire (ex. "Cheveux (mèches, perruques)"
/// = une seule sous-catégorie "Cheveux").
const Map<ProductCategory, List<String>> _subCategoriesByCategory = {
  ProductCategory.femme: [
    'Haut', 'Bas', 'Robes', 'Tenues traditionnelles', 'Chaussures', 'Sacs',
    'Accessoires',
  ],
  ProductCategory.homme: [
    'Haut', 'Bas', 'Tenues traditionnelles', 'Chaussures', 'Accessoires',
  ],
  ProductCategory.enfant: [
    'Haut', 'Bas', 'Ensembles', 'Chaussures', 'Accessoires',
  ],
  ProductCategory.objets: [],
  ProductCategory.beaute: ['Soins', 'Maquillage', 'Parfums', 'Cheveux'],
  ProductCategory.other: [],
};

List<String> subCategoriesFor(ProductCategory category) =>
    _subCategoriesByCategory[category] ?? const [];

/// Valeurs Firestore (`category.name`) à matcher pour filtrer sur [category].
/// Plus de cas particulier depuis la refonte 2026-11-04 (l'ancienne fusion
/// Sacs/Bijoux -> Accessoires n'existe plus, ces deux valeurs d'enum ont
/// disparu). Gardée comme fonction (plutôt qu'un simple `.name` en ligne)
/// pour ne pas devoir toucher les appelants si un futur cas particulier
/// réapparaît.
List<String> productCategoriesFor(ProductCategory category) =>
    [category.name];

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
