import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'package:bamako_thrift/features/product/presentation/cubit/product_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  ProductCategory? _selectedCategory; // null = Tous

  final List<Map<String, dynamic>> _categoryFilters = [
    {'label': 'Tous', 'value': null, 'icon': Icons.grid_view_rounded},
    {
      'label': 'Femme',
      'value': ProductCategory.women,
      'icon': Icons.woman_outlined
    },
    {
      'label': 'Homme',
      'value': ProductCategory.men,
      'icon': Icons.man_outlined
    },
    {
      'label': 'Enfant',
      'value': ProductCategory.children,
      'icon': Icons.child_care
    },
    {
      'label': 'Chaussures',
      'value': ProductCategory.shoes,
      'icon': Icons.do_not_step_outlined
    },
    {
      'label': 'Accessoires',
      'value': ProductCategory.accessories,
      'icon': Icons.watch_outlined
    },
  ];

  @override
  void initState() {
    super.initState();
    // Recharger les produits à chaque retour sur l'accueil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductCubit>().loadProducts(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            _buildHeader(context),
            const SizedBox(height: 12),

            // ── Barre de recherche ─────────────────────────────────────────
            _buildSearchBar(context),
            const SizedBox(height: 14),

            // ── Filtres catégories ─────────────────────────────────────────
            _buildCategoryFilters(),
            const SizedBox(height: 14),

            // ── Titre section ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommandés pour vous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(RouteNames.catalog),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(color: Color(0xFF6B7F4D)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Grille produits Firestore ──────────────────────────────────
            Expanded(
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading ||
                      state is ProductInitial ||
                      state is ProductDetailLoaded ||
                      state is ProductSearchResult) {
                    // En cours de rechargement → spinner
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B7F4D),
                      ),
                    );
                  }
                  if (state is ProductError) {
                    return _buildError(context, state.message);
                  }
                  if (state is ProductLoaded) {
                    if (state.products.isEmpty) {
                      return _buildEmpty();
                    }
                    return _buildProductGrid(context, state.products);
                  }
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

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
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const Text(
                    'DANAYA',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                ],
              );
            },
          ),
          Row(
            children: [
              // Cloche notification
              GestureDetector(
                onTap: () => context.go(RouteNames.notifications),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: Color(0xFF6B7F4D)),
                ),
              ),
              const SizedBox(width: 8),
              // Avatar
              GestureDetector(
                onTap: () => context.go(RouteNames.profile),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final user =
                        state is AuthAuthenticated ? state.user : null;
                    if (user?.avatarUrl != null) {
                      return CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(user!.avatarUrl!),
                        radius: 20,
                      );
                    }
                    return CircleAvatar(
                      backgroundColor: const Color(0xFFD4E4B8),
                      radius: 20,
                      child: Text(
                        user?.initials ?? '?',
                        style: const TextStyle(
                          color: Color(0xFF6B7F4D),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Color(0xFF6B7F4D)),
              SizedBox(width: 10),
              Text(
                'Rechercher un article...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
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
              setState(() => _selectedCategory = cat);
              context
                  .read<ProductCubit>()
                  .loadProducts(category: cat, refresh: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6B7F4D) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6B7F4D)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
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
      color: const Color(0xFF6B7F4D),
      onRefresh: () async {
        context
            .read<ProductCubit>()
            .loadProducts(category: _selectedCategory, refresh: true);
      },
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aucun article disponible',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go(RouteNames.publish),
            child: const Text(
              'Publier le premier',
              style: TextStyle(color: Color(0xFF6B7F4D)),
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
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7F4D)),
            onPressed: () => context
                .read<ProductCubit>()
                .loadProducts(refresh: true),
            child: const Text('Réessayer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
        switch (index) {
          case 0:
            context.go(RouteNames.home);
            break;
          case 1:
            context.go(RouteNames.search);
            break;
          case 2:
            context.go(RouteNames.publish);
            break;
          case 3:
            context.go(RouteNames.messages);
            break;
          case 4:
            context.go(RouteNames.profile);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF6B7F4D),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Chercher',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Publier',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          activeIcon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}

// ── Carte produit ────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
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
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.mainImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.mainImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFF7F4EE),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6B7F4D),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF7F4EE),
                          child: const Center(
                            child: Icon(Icons.checkroom,
                                size: 48, color: Color(0xFF6B7F4D)),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF7F4EE),
                        child: const Center(
                          child: Icon(Icons.checkroom,
                              size: 48, color: Color(0xFF6B7F4D)),
                        ),
                      ),
              ),
            ),
            // Infos
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge état
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _conditionLabel(product.condition),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.price.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      color: Color(0xFF6B7F4D),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _conditionLabel(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.newWithTags:
        return 'Neuf avec étiquette';
      case ProductCondition.newWithoutTags:
        return 'Neuf sans étiquette';
      case ProductCondition.veryGood:
        return 'Très bon état';
      case ProductCondition.good:
        return 'Bon état';
      case ProductCondition.fair:
        return 'État correct';
    }
  }
}
