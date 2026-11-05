import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bamako_thrift/core/constants/feature_flags.dart';
import 'package:bamako_thrift/core/extensions/double_extension.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'package:bamako_thrift/features/product/presentation/cubit/product_cubit.dart';
import 'package:bamako_thrift/shared/widgets/bottom_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ProductCategory? _selectedCategory;
  // Sous-categorie choisie (barre sous les categories, ajout 2026-11-05) --
  // null = "Tout", reinitialisee a chaque changement de categorie.
  String? _selectedSubCategory;
  // Derniere liste connue pour "Recommande pour toi" : le ProductCubit est
  // partage avec la fiche article/la recherche (voir main.dart), donc son
  // etat peut devenir ProductDetailLoaded/ProductSearchResult pendant que
  // cet ecran reste monte en arriere-plan. On ne doit jamais remplacer la
  // grille par une roue dans ce cas -- seul un ProductLoaded met a jour ce
  // cache (retour de test Fatou, 2026-10-29).
  List<ProductEntity>? _lastProducts;

  // Issu de selectableProductCategories (product_entity.dart, seule source
  // de vérité -- refonte 2026-11-04) + "Voir tout".
  static IconData _iconFor(ProductCategory c) => switch (c) {
        ProductCategory.femme => Icons.woman_outlined,
        ProductCategory.homme => Icons.man_outlined,
        ProductCategory.enfant => Icons.child_care,
        ProductCategory.objets => Icons.inventory_2_outlined,
        ProductCategory.beaute => Icons.spa_outlined,
        ProductCategory.other => Icons.category_outlined,
      };

  final List<Map<String, dynamic>> _categoryFilters = [
    {'label': 'Voir tout', 'value': null, 'icon': Icons.grid_view_rounded},
    for (final c in selectableProductCategories)
      {'label': c.label, 'value': c, 'icon': _iconFor(c)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductCubit>().loadProducts(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TabRootBackHandler(
      isHomeTab: true,
      child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildSearchBar(context),
            const SizedBox(height: 14),
            _buildCategoryFilters(),
            if (_selectedCategory != null &&
                subCategoriesFor(_selectedCategory!).isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSubCategoryFilters(),
            ],
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommandé pour toi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(RouteNames.catalog),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        color: Color(0xFFC3653D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoaded) {
                    _lastProducts = state.products;
                    if (state.products.isEmpty) return _buildEmpty(context);
                    return _buildProductGrid(context, state.products);
                  }
                  // Etat venant d'un autre ecran (fiche article, recherche)
                  // ou rafraichissement en cours : on garde la derniere
                  // liste affichee plutot qu'une roue, si on en a une.
                  final cached = _lastProducts;
                  if (cached != null) {
                    if (cached.isEmpty) return _buildEmpty(context);
                    return _buildProductGrid(context, cached);
                  }
                  if (state is ProductError) {
                    return _buildError(context, state.message);
                  }
                  return Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final name = state is AuthAuthenticated
                  ? state.user.fullName.split(' ').first
                  : 'là';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour $name 👋',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/icone_danaya_cutout.png',
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DANAYA',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push(RouteNames.notifications),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => context.go(RouteNames.profile),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final user = state is AuthAuthenticated ? state.user : null;
                    if (user?.avatarUrl != null) {
                      return CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(user!.avatarUrl!),
                        radius: 22,
                      );
                    }
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          user?.initials ?? '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.go('${RouteNames.catalog}/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rechercher un article...',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.tune,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categoryFilters.length,
        itemBuilder: (context, index) {
          final filter = _categoryFilters[index];
          final isSelected = _selectedCategory == filter['value'];
          return GestureDetector(
            onTap: () {
              final cat = filter['value'] as ProductCategory?;
              // Reinitialise la sous-categorie au changement de categorie.
              setState(() {
                _selectedCategory = cat;
                _selectedSubCategory = null;
              });
              context
                  .read<ProductCubit>()
                  .loadProducts(category: cat, refresh: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubCategoryFilters() {
    final subCats = subCategoriesFor(_selectedCategory!);
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subCats.length + 1,
        itemBuilder: (context, index) {
          final subCat = index == 0 ? null : subCats[index - 1];
          final isSelected = _selectedSubCategory == subCat;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSubCategory = subCat);
              context.read<ProductCubit>().loadProducts(
                    category: _selectedCategory,
                    subCategory: subCat,
                    refresh: true,
                  );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                index == 0 ? 'Tout' : subCat!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<ProductEntity> products) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async {
        context.read<ProductCubit>().loadProducts(
              category: _selectedCategory,
              subCategory: _selectedSubCategory,
              refresh: true,
            );
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _ProductCard(product: product);
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.checkroom_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun article disponible',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à publier !',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(RouteNames.publish),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: Text(
              'Publier un article',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off,
              size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () =>
                context.read<ProductCubit>().loadProducts(refresh: true),
            child: Text('Réessayer',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          ),
        ],
      ),
    );
  }

}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: product.mainImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.mainImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (_, __) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Center(
                                child: Icon(Icons.checkroom,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          )
                        : Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: Center(
                              child: Icon(Icons.checkroom,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.condition.label,
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (pressingEnabled && product.verifie)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '✓ Vérifié',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      '${product.price.toPriceFCFA}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    // ── Note sous le prix, comme sur la maquette ───────
                    Row(
                      children: [
                        if (product.reviewCount > 0) ...[
                          const Icon(Icons.star, size: 11, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else
                          Flexible(
                            child: Text(
                              'Pas encore noté',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        if ((product.sellerCity ?? product.location) !=
                            null) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.location_on_outlined,
                              size: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                          Flexible(
                            child: Text(
                              // Ville du vendeur (lot 6) si disponible, sinon
                              // repli sur l'ancienne localisation libre de
                              // l'article (anciennes annonces, pas de
                              // migration) — même emplacement visuel, pas de
                              // doublon.
                              product.sellerCity ?? product.location!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
