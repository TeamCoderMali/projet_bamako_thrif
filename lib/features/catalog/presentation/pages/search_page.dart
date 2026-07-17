import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'package:bamako_thrift/features/product/presentation/cubit/product_cubit.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  // ── Filtres ─────────────────────────────────────────────────────────────────
  ProductCategory? _selectedCategory;
  ProductCondition? _selectedCondition;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Femme',       'value': ProductCategory.women,      'emoji': '👗'},
    {'label': 'Homme',       'value': ProductCategory.men,        'emoji': '👔'},
    {'label': 'Enfant',      'value': ProductCategory.children,   'emoji': '👶'},
    {'label': 'Chaussures',  'value': ProductCategory.shoes,      'emoji': '👟'},
    {'label': 'Accessoires', 'value': ProductCategory.accessories,'emoji': '🧣'},
    {'label': 'Sacs',        'value': ProductCategory.bags,       'emoji': '👜'},
    {'label': 'Bijoux',      'value': ProductCategory.jewelry,    'emoji': '💍'},
    {'label': 'Sport',       'value': ProductCategory.sportswear, 'emoji': '⚽'},
    {'label': 'Tradition',   'value': ProductCategory.traditional,'emoji': '🎋'},
    {'label': 'Autre',       'value': ProductCategory.other,      'emoji': '📦'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Recherche avec debounce 400ms ────────────────────────────────────────────
  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      context.read<ProductCubit>().loadProducts(refresh: true);
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ProductCubit>().searchProducts(query.trim());
      if (mounted) setState(() => _isSearching = false);
    });
  }

  void _applyFilters() {
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      context.read<ProductCubit>().searchProducts(q);
    } else {
      context.read<ProductCubit>().loadProducts(
        category: _selectedCategory,
        refresh: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go(RouteNames.home),
        ),
        title: Container(
          margin: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onQueryChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (q) {
              _debounce?.cancel();
              if (q.trim().isNotEmpty) {
                context.read<ProductCubit>().searchProducts(q.trim());
              }
            },
            decoration: InputDecoration(
              hintText: 'Robe, Nike, sac à main...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF7F4EE),
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF6B7F4D)),
                      ),
                    )
                  : const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        _controller.clear();
                        context.read<ProductCubit>().loadProducts(refresh: true);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildCategoryFilter(),
        ),
      ),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
            );
          }

          if (state is ProductError) {
            return _buildEmpty(
              icon: Icons.error_outline,
              title: 'Erreur de chargement',
              subtitle: state.message,
              iconColor: Colors.red.shade200,
            );
          }

          List<ProductEntity> products = [];
          if (state is ProductLoaded) products = state.products;
          if (state is ProductSearchResult) products = state.results;

          if (_controller.text.isEmpty && state is! ProductSearchResult) {
            return _buildSuggestionsView();
          }

          if (products.isEmpty) {
            return _buildEmpty(
              icon: Icons.search_off,
              title: 'Aucun résultat',
              subtitle: 'Essayez un autre mot-clé ou changez les filtres',
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${products.length} résultat${products.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    // Filtre état
                    GestureDetector(
                      onTap: _showConditionFilter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedCondition != null
                              ? const Color(0xFF6B7F4D)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedCondition != null
                                ? const Color(0xFF6B7F4D)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune,
                              size: 14,
                              color: _selectedCondition != null
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCondition != null
                                  ? _conditionLabel(_selectedCondition!)
                                  : 'État',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedCondition != null
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => _ProductCard(product: products[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Filtre catégories horizontal ─────────────────────────────────────────────
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _categories.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            final isAll = _selectedCategory == null;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = null);
                _applyFilters();
              },
              child: _chip('Tous', '🔍', isAll),
            );
          }
          final cat = _categories[i - 1];
          final isSelected = _selectedCategory == cat['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory =
                  isSelected ? null : cat['value'] as ProductCategory);
              _applyFilters();
            },
            child: _chip(cat['label'] as String, cat['emoji'] as String, isSelected),
          );
        },
      ),
    );
  }

  Widget _chip(String label, String emoji, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF6B7F4D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFF6B7F4D) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ── État vide / erreur ────────────────────────────────────────────────────────
  Widget _buildEmpty({
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = Colors.grey,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: iconColor.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  // ── Page de suggestions (avant toute recherche) ──────────────────────────────
  Widget _buildSuggestionsView() {
    final suggestions = [
      '👗 Robe',
      '👟 Sneakers',
      '👜 Sac',
      '💍 Bijoux',
      '🧥 Veste',
      '👔 Chemise',
      '👖 Jean',
      '🧢 Casquette',
    ];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suggestions populaires',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  final q = s.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                  _controller.text = q;
                  context.read<ProductCubit>().searchProducts(q);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(s,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet filtre état ──────────────────────────────────────────────────
  void _showConditionFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('État du vêtement',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...ProductCondition.values.map((c) {
                return RadioListTile<ProductCondition?>(
                  value: c,
                  groupValue: _selectedCondition,
                  title: Text(_conditionLabel(c)),
                  activeColor: const Color(0xFF6B7F4D),
                  onChanged: (v) {
                    setModalState(() => _selectedCondition = v);
                    setState(() => _selectedCondition = v);
                    _applyFilters();
                    Navigator.pop(ctx);
                  },
                );
              }),
              RadioListTile<ProductCondition?>(
                value: null,
                groupValue: _selectedCondition,
                title: const Text('Tous les états'),
                activeColor: const Color(0xFF6B7F4D),
                onChanged: (v) {
                  setModalState(() => _selectedCondition = null);
                  setState(() => _selectedCondition = null);
                  _applyFilters();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
}

// ── Carte produit dans la grille de résultats ─────────────────────────────────
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
                              color: Color(0xFF6B7F4D), strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF7F4EE),
                          child: const Center(
                            child: Icon(Icons.checkroom,
                                color: Color(0xFFB8C9A0), size: 40),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF7F4EE),
                        child: const Center(
                          child: Icon(Icons.checkroom,
                              color: Color(0xFFB8C9A0), size: 40),
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
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                  if (product.size != null || product.brand != null)
                    Text(
                      [product.brand, product.size]
                          .where((e) => e != null)
                          .join(' · '),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
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
