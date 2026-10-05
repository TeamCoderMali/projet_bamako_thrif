// ─── Bamako Thrift — Browse Page ("Parcourir") ───────────────────────────────
// Page d'accueil de l'onglet "Parcourir" : recherche + grille de catégories.
// Taper la barre de recherche ouvre l'écran de recherche existant (inchangé).
// Chaque tuile ouvre le catalogue filtré sur la catégorie correspondante.
//
// Seules 7 des 10 catégories du modèle produit sont affichées ici (décision
// Ali) : bags/jewelry/traditional/other restent valides pour les articles
// existants et le formulaire de vente, juste pas de tuile dédiée pour
// jewelry/traditional/other sur cet écran. Pas de repli générique
// silencieux : un asset manquant (svgAsset null) affiche une erreur visible
// au lieu d'une icône grise qui masquerait le problème.
// Illustrations centrées dans chaque tuile (taille régulière), nom sous le
// dessin.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'package:bamako_thrift/shared/widgets/bottom_navigation.dart';
import 'catalog_page.dart' show CatalogFilters;

class _CategoryTile {
  final ProductCategory category;
  // null = illustration pas encore fournie -> erreur visible, pas de repli.
  final String? svgAsset;
  const _CategoryTile({required this.category, this.svgAsset});
}

// Libelle derive de ProductCategoryLabel (lot 8) : plus de champ label
// explicite ici, pour ne pas pouvoir diverger de la liste centralisee.
const _categoryTiles = <_CategoryTile>[
  _CategoryTile(
    category: ProductCategory.women,
    svgAsset: 'assets/images/categories/femmes.svg',
  ),
  _CategoryTile(
    category: ProductCategory.men,
    svgAsset: 'assets/images/categories/hommes.svg',
  ),
  _CategoryTile(
    category: ProductCategory.children,
    svgAsset: 'assets/images/categories/enfants.svg',
  ),
  _CategoryTile(
    category: ProductCategory.shoes,
    svgAsset: 'assets/images/categories/chaussures.svg',
  ),
  _CategoryTile(
    category: ProductCategory.accessories,
    svgAsset: 'assets/images/categories/accessoires.svg',
  ),
  _CategoryTile(
    category: ProductCategory.bags,
    svgAsset: 'assets/images/categories/sacs.svg',
  ),
  _CategoryTile(
    category: ProductCategory.sportswear,
    svgAsset: 'assets/images/categories/sport.svg',
  ),
];

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  void _openSearch() {
    context.push(RouteNames.search);
  }

  void _openCategory(ProductCategory category) {
    context.push(
      RouteNames.catalog,
      extra: CatalogFilters(category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Parcourir',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _openSearch,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: colors.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        'Rechercher un article...',
                        style: TextStyle(
                            color: colors.onSurfaceVariant, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildGrid(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  // Grille manuelle (2 colonnes) plutôt que GridView : avec un nombre impair
  // de tuiles, la derniere occupe toute la largeur au lieu de laisser un trou.
  Widget _buildGrid() {
    final rows = <Widget>[];
    for (var i = 0; i < _categoryTiles.length; i += 2) {
      final hasSecond = i + 1 < _categoryTiles.length;
      final isLast = !hasSecond;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: Row(
            children: [
              Expanded(
                child: _CategoryTileCard(
                  tile: _categoryTiles[i],
                  isWide: isLast,
                  onTap: () => _openCategory(_categoryTiles[i].category),
                ),
              ),
              if (hasSecond) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: _CategoryTileCard(
                    tile: _categoryTiles[i + 1],
                    onTap: () =>
                        _openCategory(_categoryTiles[i + 1].category),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _CategoryTileCard extends StatelessWidget {
  final _CategoryTile tile;
  final VoidCallback onTap;
  final bool isWide;
  const _CategoryTileCard({
    required this.tile,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final missing = tile.svgAsset == null;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: isWide ? 2.6 : 1.15,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: missing
                ? Border.all(color: Colors.red.shade400, width: 1.5)
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: missing
                    ? Tooltip(
                        message: 'Illustration manquante pour "${tile.category.label}"',
                        child: Icon(Icons.warning_amber_rounded,
                            color: Colors.red.shade400, size: 36),
                      )
                    : SvgPicture.asset(tile.svgAsset!, fit: BoxFit.contain),
              ),
              const SizedBox(height: 10),
              Text(
                tile.category.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              if (missing) ...[
                const SizedBox(height: 4),
                Text(
                  'SVG manquant',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade400),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
