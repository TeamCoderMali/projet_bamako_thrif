import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';
import 'package:bamako_thrift/features/product/presentation/cubit/product_cubit.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isContactLoading = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);
  }

  // ── Ouvrir un chat avec le vendeur ─────────────────────────────────────
  Future<void> _contactSeller(ProductEntity product) async {
    if (_isContactLoading) return;
    setState(() => _isContactLoading = true);

    try {
      final currentUser = context.read<AuthCubit>().currentUser;
      if (currentUser == null) {
        context.go(RouteNames.login);
        return;
      }

      if (currentUser.id == product.sellerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous ne pouvez pas vous contacter vous-même.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final chatRepo = ChatRepositoryImpl(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      );

      final chatId = await chatRepo.createOrGetChatWithUsers(
        participantIds: [currentUser.id, product.sellerId],
        participantNames: {
          currentUser.id: currentUser.fullName,
          product.sellerId: product.sellerName ?? 'Vendeur',
        },
        participantAvatars: {
          currentUser.id: currentUser.avatarUrl,
          product.sellerId: null,
        },
        productId: product.id,
        productTitle: product.title,
      );

      if (mounted) context.go('/messages/$chatId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isContactLoading = false);
    }
  }

  // ── Partager le produit ────────────────────────────────────────────────
  void _shareProduct(ProductEntity product) {
    Share.share(
      '🛍️ ${product.title}\n'
      '💰 ${product.price.toStringAsFixed(0)} FCFA\n\n'
      'Disponible sur DANAYA – Seconde main, première confiance.',
    );
  }

  // ── Ajouter/Retirer des favoris (local pour l'instant) ─────────────────
  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Ajouté aux favoris ❤️' : 'Retiré des favoris',
        ),
        backgroundColor: const Color(0xFF6B7F4D),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
            );
          }
          if (state is ProductError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7F4D)),
                    onPressed: () => context
                        .read<ProductCubit>()
                        .loadProductDetail(widget.productId),
                    child: const Text('Réessayer',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          if (state is ProductDetailLoaded) {
            return _buildContent(context, state.product);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductEntity product) {
    return CustomScrollView(
      slivers: [
        // ── Image en-tête ─────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: Colors.white,
          leading: GestureDetector(
            onTap: () =>
                context.canPop() ? context.pop() : context.go(RouteNames.home),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
          actions: [
            // ── Favori ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _toggleFavorite,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.black,
                ),
              ),
            ),
            // ── Partager ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => _shareProduct(product),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_outlined, color: Colors.black),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(product),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Badge état ─────────────────────────────────────────────
                Row(
                  children: [
                    _Badge(
                      label: _conditionLabel(product.condition),
                      color: Colors.green,
                    ),
                    if (product.brand != null) ...[
                      const SizedBox(width: 8),
                      _Badge(label: product.brand!, color: Colors.blue),
                    ],
                    if (product.size != null) ...[
                      const SizedBox(width: 8),
                      _Badge(
                          label: 'Taille ${product.size}',
                          color: Colors.orange),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // ── Titre ─────────────────────────────────────────────────
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B2B),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Infos rapides ──────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${product.viewCount} vues',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.favorite_border,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${product.favoriteCount} favoris',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (product.location != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        product.location!,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 14),

                // ── Prix ──────────────────────────────────────────────────
                Text(
                  '${product.price.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7F4D),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Description ──────────────────────────────────────────
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Couleur ───────────────────────────────────────────────
                if (product.color != null) ...[
                  const Text(
                    'Couleur',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(product.color!,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                ],

                // ── Vendeur ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF6B7F4D),
                        backgroundImage: product.sellerAvatarUrl != null
                            ? CachedNetworkImageProvider(
                                product.sellerAvatarUrl!)
                            : null,
                        child: product.sellerAvatarUrl == null
                            ? Text(
                                product.sellerName.isNotEmpty
                                    ? product.sellerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.sellerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                            const Text(
                              'Vendeur vérifié ✓',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Boutons Contacter / Acheter ───────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _contactSeller(product),
                        icon: _isContactLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF6B7F4D),
                                ),
                              )
                            : const Icon(Icons.chat_bubble_outline,
                                color: Color(0xFF6B7F4D), size: 18),
                        label: const Text(
                          'Contacter',
                          style: TextStyle(color: Color(0xFF6B7F4D)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF6B7F4D)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go(
                          '/payment',
                          extra: product,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7F4D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Acheter',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(ProductEntity product) {
    if (product.imageUrls.isEmpty) {
      return Container(
        color: const Color(0xFFF7F4EE),
        child: const Center(
          child: Icon(Icons.checkroom, size: 100, color: Color(0xFF6B7F4D)),
        ),
      );
    }
    return PageView.builder(
      itemCount: product.imageUrls.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: product.imageUrls[index],
          fit: BoxFit.cover,
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
              child: Icon(Icons.checkroom, size: 100, color: Color(0xFF6B7F4D)),
            ),
          ),
        );
      },
    );
  }

  String _conditionLabel(ProductCondition c) {
    switch (c) {
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
