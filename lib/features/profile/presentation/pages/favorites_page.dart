import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Récupérer les favoris de l'utilisateur
      final favSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      if (favSnapshot.docs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Récupérer les détails de chaque produit
      final List<Map<String, dynamic>> products = [];
      for (final doc in favSnapshot.docs) {
        final productId = doc.data()['productId'] as String?;
        if (productId == null) continue;

        final productDoc = await FirebaseFirestore.instance
            .collection('product')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          products.add({
            'favoriteId': doc.id,
            'productId': productId,
            ...productDoc.data()!,
          });
        }
      }

      if (mounted) {
        setState(() {
          _favorites = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(productId)
        .delete();

    setState(() {
      _favorites.removeWhere((f) => f['productId'] == productId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retiré des favoris'),
        backgroundColor: Color(0xFF6B7F4D),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2B)),
          onPressed: () => context.go(RouteNames.profile),
        ),
        title: const Text(
          'Mes favoris',
          style: TextStyle(
            color: Color(0xFF2B2B2B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
            )
          : _favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 80, color: Color(0xFF6B7F4D)),
                      SizedBox(height: 16),
                      Text(
                        'Aucun favori pour l\'instant',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ajoutez des articles à vos favoris\npour les retrouver ici.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final product = _favorites[index];
                    final images = product['imageUrls'] as List<dynamic>?;
                    final imageUrl = images != null && images.isNotEmpty
                        ? images.first as String
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xFFF7F4EE),
                                    child: const Icon(Icons.checkroom,
                                        color: Color(0xFF6B7F4D)),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: const Color(0xFFF7F4EE),
                                  child: const Icon(Icons.checkroom,
                                      color: Color(0xFF6B7F4D)),
                                ),
                        ),
                        title: Text(
                          product['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                        subtitle: Text(
                          '${((product['price'] ?? 0) as num).toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: Color(0xFF6B7F4D),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () =>
                              _removeFavorite(product['productId']),
                        ),
                        onTap: () => context.go(
                          '/product/${product['productId']}',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
