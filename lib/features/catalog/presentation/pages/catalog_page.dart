// ─── Bamako Thrift — Catalog Page ────────────────────────────────────────────
// Page catalogue avec données Firestore réelles et filtrage dynamique
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'package:bamako_thrift/features/product/presentation/cubit/product_cubit.dart';

// ── Modèle de filtres partagé entre CatalogPage et FilterPage ────────────────
class CatalogFilters {
  final ProductCategory? category;
  final ProductCondition? condition;
  final double minPrice;
  final double maxPrice;

  const CatalogFilters({
    this.category,
    this.condition,
    this.minPrice = 0,
    this.maxPrice = 100000,
  });

  bool get hasActiveFilters =>
      category != null || condition != null || minPrice > 0 || maxPrice < 100000;

  CatalogFilters copyWith({
    ProductCategory? Function()? category,
    ProductCondition? Function()? condition,
    double? minPrice,
    double? maxPrice,
  }) {
    return CatalogFilters(
      category:  category  != null ? category()  : this.category,
      condition: condition != null ? condition() : this.condition,
      minPrice:  minPrice  ?? this.minPrice,
      maxPrice:  maxPrice  ?? this.maxPrice,
    );
  }
}

// ── Labels ────────────────────────────────────────────────────────────────────
String _categoryLabel(ProductCategory c) {
  switch (c) {
    case ProductCategory.men:         return 'Homme';
    case ProductCategory.women:       return 'Femme';
    case ProductCategory.children:    return 'Enfant';
    case ProductCategory.shoes:       return 'Chaussures';
    case ProductCategory.accessories: return 'Accessoires';
    case ProductCategory.bags:        return 'Sacs';
    case ProductCategory.jewelry:     return 'Bijoux';
    case ProductCategory.sportswear:  return 'Sport';
    case ProductCategory.traditional: return 'Traditionnel';
    case ProductCategory.other:       return 'Autre';
  }
}

String _conditionLabel(ProductCondition c) {
  switch (c) {
    case ProductCondition.newWithTags:    return 'Neuf avec étiquette';
    case ProductCondition.newWithoutTags: return 'Neuf sans étiquette';
    case ProductCondition.veryGood:       return 'Très bon état';
    case ProductCondition.good:           return 'Bon état';
    case ProductCondition.fair:           return 'État correct';
  }
}

String _fmtPrice(double p) =>
    '${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA';

// ─────────────────────────────────────────────────────────────────────────────

class CatalogPage extends StatefulWidget {
  final CatalogFilters? initialFilters;
  const CatalogPage({super.key, this.initialFilters});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late CatalogFilters _filters;

  // Catégories rapides dans la barre horizontale
  static const _quickCats = <_QuickCat>[
    _QuickCat(null, 'Tous', Icons.grid_view_rounded),
    _QuickCat(ProductCategory.women,    'Femme',       Icons.woman_outlined),
    _QuickCat(ProductCategory.men,      'Homme',       Icons.man_outlined),
    _QuickCat(ProductCategory.children, 'Enfant',      Icons.child_care),
    _QuickCat(ProductCategory.shoes,    'Chaussures',  Icons.do_not_step_outlined),
    _QuickCat(ProductCategory.accessories, 'Accès.',   Icons.watch_outlined),
    _QuickCat(ProductCategory.bags,     'Sacs',        Icons.shopping_bag_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? const CatalogFilters();
    _load();
  }

  void _load() {
    context.read<ProductCubit>().loadProductsWithFilters(
      category: _filters.category,
      condition: _filters.condition,
      minPrice:  _filters.minPrice  > 0       ? _filters.minPrice  : null,
      maxPrice:  _filters.maxPrice  < 100000  ? _filters.maxPrice  : null,
    );
  }

  void _applyCategory(ProductCategory? cat) {
    setState(() => _filters = _filters.copyWith(category: () => cat));
    _load();
  }

  Future<void> _openFilters() async {
    final result = await context.push<CatalogFilters>(
      RouteNames.filters,
      extra: _filters,
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Catalogue',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          // Badge si filtres actifs
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.black87),
                onPressed: _openFilters,
              ),
              if (_filters.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B7F4D),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barre recherche (tap → /search) ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: GestureDetector(
              onTap: () => context.push(RouteNames.search),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4)
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF6B7F4D), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Rechercher un article...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Filtres rapides catégorie ─────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickCats.length,
              itemBuilder: (_, i) {
                final qc = _quickCats[i];
                final isSelected = _filters.category == qc.value;
                return GestureDetector(
                  onTap: () => _applyCategory(qc.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6B7F4D)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6B7F4D)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      qc.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Bandeau filtres actifs ────────────────────────────────────────
          if (_filters.condition != null ||
              _filters.minPrice > 0 ||
              _filters.maxPrice < 100000) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.filter_list,
                      size: 14, color: Color(0xFF6B7F4D)),
                  const SizedBox(width: 6),
                  if (_filters.condition != null)
                    _Chip(_conditionLabel(_filters.condition!)),
                  if (_filters.minPrice > 0 || _filters.maxPrice < 100000)
                    _Chip(
                        '${_fmtPrice(_filters.minPrice)} – ${_fmtPrice(_filters.maxPrice)}'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(
                          () => _filters = const CatalogFilters());
                      _load();
                    },
                    child: const Text(
                      'Effacer',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── Grille produits ───────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6B7F4D)),
                  );
                }
                if (state is ProductError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(state.message,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Réessayer',
                              style: TextStyle(color: Color(0xFF6B7F4D))),
                        ),
                      ],
                    ),
                  );
                }
                final products = state is ProductLoaded
                    ? state.products
                    : <ProductEntity>[];

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Aucun article trouvé',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() => _filters = const CatalogFilters());
                            _load();
                          },
                          child: const Text('Réinitialiser les filtres',
                              style: TextStyle(color: Color(0xFF6B7F4D))),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF6B7F4D),
                  onRefresh: () async => _load(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) =>
                        _ProductCard(product: products[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentIndex: 1),
    );
  }
}

// ── Carte produit ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: product.mainImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.mainImageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFF7F4EE),
                          child: const Center(
                            child: Icon(Icons.checkroom,
                                size: 40, color: Color(0xFF6B7F4D)),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF7F4EE),
                          child: const Center(
                            child: Icon(Icons.checkroom,
                                size: 40, color: Color(0xFF6B7F4D)),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF7F4EE),
                        child: const Center(
                          child: Icon(Icons.checkroom,
                              size: 40, color: Color(0xFF6B7F4D)),
                        ),
                      ),
              ),
            ),
            // Infos
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _fmtPrice(product.price),
                    style: const TextStyle(
                      color: Color(0xFF6B7F4D),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3E6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _conditionLabel(product.condition),
                          style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF5A6B3E),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        switch (i) {
          case 0: context.go(RouteNames.home);     break;
          case 1: context.go(RouteNames.search);   break;
          case 2: context.go(RouteNames.publish);  break;
          case 3: context.go(RouteNames.messages); break;
          case 4: context.go(RouteNames.profile);  break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF6B7F4D),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Accueil'),
        BottomNavigationBarItem(
            icon: Icon(Icons.search), label: 'Chercher'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline), label: 'Publier'),
        BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined), label: 'Messages'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profil'),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _QuickCat {
  final ProductCategory? value;
  final String label;
  final IconData icon;
  const _QuickCat(this.value, this.label, this.icon);
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF5A6B3E))),
    );
  }
}
