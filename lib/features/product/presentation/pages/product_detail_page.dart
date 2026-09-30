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
  bool _isFavoriteLoading = false;

  // ── État de la note de l'utilisateur courant ───────────────────────────
  int _myRating = 0;
  bool _isRatingLoading = false;

  // ── Avis texte (réservé aux vendeurs Pro) ──────────────────────────────
  final _commentController = TextEditingController();
  bool _isCommentSubmitting = false;
  bool _sellerIsVendeurPro = false;
  bool _proStatusRequested = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProductDetail(widget.productId);
    _checkIfFavorite();
    _loadMyRating();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ── Vérifier si déjà en favori ─────────────────────────────────────────
  Future<void> _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.productId)
        .get();

    if (doc.exists && mounted) {
      setState(() => _isFavorite = true);
    }
  }

  // ── Charger la note déjà donnée par l'utilisateur (le cas échéant) ────
  Future<void> _loadMyRating() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('product')
        .doc(widget.productId)
        .collection('reviews')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        _myRating = (data['rating'] as num).toInt();
        _commentController.text = data['comment'] as String? ?? '';
      });
    }
  }

  // ── Vérifier si le vendeur de cet article est "Vendeur Pro" ────────────
  // (seuls les Vendeurs Pro reçoivent des avis texte, pas juste des étoiles)
  Future<void> _loadSellerProStatus(String sellerId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
    if (mounted) {
      setState(() => _sellerIsVendeurPro = doc.data()?['isVendeurPro'] == true);
    }
  }

  // ── Envoyer/mettre à jour le commentaire texte (nécessite d'avoir déjà
  // noté par étoiles, et que le vendeur soit Pro) ────────────────────────
  Future<void> _submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    final currentUser = context.read<AuthCubit>().currentUser;
    if (user == null || _myRating == 0 || _isCommentSubmitting) return;

    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() => _isCommentSubmitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('product')
          .doc(widget.productId)
          .collection('reviews')
          .doc(user.uid)
          .set(
        {
          'userId': user.uid,
          'userName': currentUser?.fullName ?? 'Utilisateur',
          'comment': comment,
        },
        SetOptions(merge: true),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis envoyé, merci !'),
            backgroundColor: Color(0xFF6B7F4D),
            duration: Duration(seconds: 1),
          ),
        );
      }
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
      if (mounted) setState(() => _isCommentSubmitting = false);
    }
  }

  // ── Ajouter/Retirer des favoris Firestore ──────────────────────────────
  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go(RouteNames.login);
      return;
    }

    if (_isFavoriteLoading) return;
    setState(() => _isFavoriteLoading = true);

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.productId);

    try {
      if (_isFavorite) {
        await favRef.delete();
        if (mounted) {
          setState(() => _isFavorite = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retiré des favoris'),
              backgroundColor: Color(0xFF6B7F4D),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await favRef.set({
          'productId': widget.productId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() => _isFavorite = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ajouté aux favoris ❤️'),
              backgroundColor: Color(0xFF6B7F4D),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
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
      if (mounted) setState(() => _isFavoriteLoading = false);
    }
  }

  // ── Noter le produit (vendeur ou acheteur) ─────────────────────────────
  Future<void> _rateProduct(int stars) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go(RouteNames.login);
      return;
    }

    if (_isRatingLoading) return;
    setState(() => _isRatingLoading = true);

    final productRef =
        FirebaseFirestore.instance.collection('product').doc(widget.productId);
    final reviewRef = productRef.collection('reviews').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final existingReview = await transaction.get(reviewRef);
        final productSnap = await transaction.get(productRef);

        final currentRating =
            (productSnap['rating'] as num?)?.toDouble() ?? 0.0;
        final currentCount =
            (productSnap['reviewCount'] as num?)?.toInt() ?? 0;

        double newRating;
        int newCount;

        if (existingReview.exists) {
          final oldStars = (existingReview['rating'] as num).toDouble();
          final totalPoints = (currentRating * currentCount) - oldStars + stars;
          newRating = currentCount == 0 ? 0 : totalPoints / currentCount;
          newCount = currentCount;
        } else {
          final totalPoints = (currentRating * currentCount) + stars;
          newCount = currentCount + 1;
          newRating = totalPoints / newCount;
        }

        transaction.set(reviewRef, {
          'userId': user.uid,
          'rating': stars,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(productRef, {
          'rating': newRating,
          'reviewCount': newCount,
        });
      });

      if (mounted) {
        setState(() => _myRating = stars);
        // Recharge le produit pour afficher la nouvelle moyenne
        context.read<ProductCubit>().loadProductDetail(widget.productId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre note ⭐'),
            backgroundColor: Color(0xFF6B7F4D),
            duration: Duration(seconds: 1),
          ),
        );
      }
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
      if (mounted) setState(() => _isRatingLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductDetailLoaded && !_proStatusRequested) {
            _proStatusRequested = true;
            _loadSellerProStatus(state.product.sellerId);
          }
        },
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
                  Icon(Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
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
                child: _isFavoriteLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6B7F4D),
                        ),
                      )
                    : Icon(
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
                Text(
                  product.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Note moyenne + étoiles cliquables ──────────────────
                Row(
                  children: [
                    if (product.reviewCount > 0) ...[
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating.toStringAsFixed(1)} (${product.reviewCount} avis)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      Text(
                        'Pas encore noté',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                    ],
                    _RatingStars(
                      currentRating: _myRating,
                      isLoading: _isRatingLoading,
                      onRate: _rateProduct,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Avis texte (réservé aux Vendeurs Pro) ──────────────
                if (_sellerIsVendeurPro) ...[
                  if (_myRating == 0)
                    Text(
                      'Notez d\'abord l\'article avec les étoiles pour pouvoir laisser un avis.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _commentController,
                          maxLength: 500,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Laissez un avis sur ce vendeur Pro...',
                            filled: true,
                            fillColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isCommentSubmitting ? null : _submitComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B7F4D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isCommentSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Envoyer l\'avis',
                                    style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],

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
                const SizedBox(height: 14),
                Text(
                  '${product.price.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7F4D),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Description',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.6,
                      fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (_sellerIsVendeurPro) ...[
                  const Text('Avis',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _ReviewsList(productId: widget.productId),
                  const SizedBox(height: 24),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const Text(
                              'Vendeur vérifié ✓',
                              style:
                                  TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
                        label: const Text('Contacter',
                            style: TextStyle(color: Color(0xFF6B7F4D))),
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
                        onPressed: () => context.go('/payment', extra: product),
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
                              color: Colors.white, fontWeight: FontWeight.bold),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B7F4D),
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
      case ProductCondition.neufAvecEtiquette:
        return 'État 99 avec étiquette';
      case ProductCondition.tresSatisfaisant:
        return 'Très satisfaisant';
      case ProductCondition.bon:
        return 'Bon état';
      case ProductCondition.satisfaisant:
        return 'État satisfaisant';
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

// ── Widget d'étoiles cliquables pour noter un produit ──────────────────────
class _RatingStars extends StatelessWidget {
  final int currentRating; // 0 si l'utilisateur n'a pas encore noté
  final bool isLoading;
  final ValueChanged<int> onRate;

  const _RatingStars({
    required this.currentRating,
    required this.isLoading,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF6B7F4D),
        ),
      );
    }
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= currentRating;
        return GestureDetector(
          onTap: () => onRate(starValue),
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              size: 18,
              color: isFilled
                  ? Colors.amber
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );
      }),
    );
  }
}

// ── Liste des avis texte (Vendeurs Pro uniquement) ─────────────────────────
class _ReviewsList extends StatelessWidget {
  final String productId;
  const _ReviewsList({required this.productId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('product')
          .doc(productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6B7F4D),
              ),
            ),
          );
        }

        final reviews = (snapshot.data?.docs ?? [])
            .where((doc) =>
                ((doc.data() as Map<String, dynamic>)['comment']
                        as String?)
                    ?.trim()
                    .isNotEmpty ==
                true)
            .toList();

        if (reviews.isEmpty) {
          return Text(
            'Aucun avis pour le moment.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13),
          );
        }

        return Column(
          children: reviews.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final rating = (data['rating'] as num?)?.toInt() ?? 0;
            final userName = data['userName'] as String? ?? 'Utilisateur';
            final comment = data['comment'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 12,
                            color: i < rating
                                ? Colors.amber
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.4)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
