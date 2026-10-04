// ─── Bamako Thrift — Browse Page ("Parcourir") ───────────────────────────────
// Page d'accueil de l'onglet "Parcourir" : recherche + grille de catégories.
// Taper la barre de recherche ouvre l'écran de recherche existant (inchangé).
// Chaque tuile ouvre le catalogue filtré sur la catégorie correspondante.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'package:bamako_thrift/shared/widgets/bottom_navigation.dart';
import 'catalog_page.dart' show CatalogFilters;

class _CategoryTile {
  final ProductCategory category;
  final String label;
  final String? svgAsset;
  final IconData fallbackIcon;
  const _CategoryTile({
    required this.category,
    required this.label,
    this.svgAsset,
    required this.fallbackIcon,
  });
}

// Illustrations disponibles pour 6 des 10 catégories ; les 4 restantes
// (sacs, bijoux, traditionnel, autre) utilisent une icône générique en
// attendant leur SVG dédié.
const _categoryTiles = <_CategoryTile>[
  _CategoryTile(
    category: ProductCategory.women,
    label: 'Femmes',
    svgAsset: 'assets/images/categories/femmes.svg',
    fallbackIcon: Icons.woman_outlined,
  ),
  _CategoryTile(
    category: ProductCategory.men,
    label: 'Hommes',
    svgAsset: 'assets/images/categories/hommes.svg',
    fallbackIcon: Icons.man_outlined,
  ),
  _CategoryTile(
    category: ProductCategory.children,
    label: 'Enfants',
    svgAsset: 'assets/images/categories/enfants.svg',
    fallbackIcon: Icons.child_care,
  ),
  _CategoryTile(
    category: ProductCategory.shoes,
    label: 'Chaussures',
    svgAsset: 'assets/images/categories/chaussures.svg',
    fallbackIcon: Icons.do_not_step_outlined,
  ),
  _CategoryTile(
    category: ProductCategory.accessories,
    label: 'Accessoires',
    svgAsset: 'assets/images/categories/accessoires.svg',
    fallbackIcon: Icons.watch_outlined,
  ),
  _CategoryTile(
    category: ProductCategory.bags,
    label: 'Sacs',
    fallbackIcon: Icons.shopping_bag_outlined,
  ),
  _CategoryTile(
    category: ProductCategory.jewelry,
    label: 'Bijoux',
    fallbackIcon: Icons.diamond_outlined,
  ),
  _CategoryTile(
    category: ProductCategory.sportswear,
    label: 'Sport',
    svgAsset: 'assets/images/categories/sport.svg',
    fallbackIcon: Icons.sports_outlined,
  ),
  _CategoryTile(
    category: ProductCategory.traditional,
    label: 'Traditionnel',
    fallbackIcon: Icons.checkroom,
  ),
  _CategoryTile(
    category: ProductCategory.other,
    label: 'Autre',
    fallbackIcon: Icons.category_outlined,
  ),
];

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemCount: _categoryTiles.length,
                itemBuilder: (context, index) {
                  final tile = _categoryTiles[index];
                  return _CategoryTileCard(
                    tile: tile,
                    onTap: () => _openCategory(tile.category),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _CategoryTileCard extends StatelessWidget {
  final _CategoryTile tile;
  final VoidCallback onTap;
  const _CategoryTileCard({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -6,
              child: SizedBox(
                width: 84,
                height: 84,
                child: tile.svgAsset != null
                    ? SvgPicture.asset(tile.svgAsset!, fit: BoxFit.contain)
                    : Icon(tile.fallbackIcon, size: 56, color: colors.onSurfaceVariant.withOpacity(0.5)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  tile.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
