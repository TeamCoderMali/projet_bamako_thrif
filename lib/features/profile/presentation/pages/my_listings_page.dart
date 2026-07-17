// ─── Bamako Thrift — My Listings Page ────────────────────────────────────────
// Affiche toutes les annonces du vendeur connecté avec gestion (supprimer/masquer)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  String _fmtPrice(dynamic p) {
    final price = (p is num) ? p.toDouble() : 0.0;
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA';
  }

  // ── Statut ─────────────────────────────────────────────────────────────────
  String _statusLabel(String status) {
    switch (status) {
      case 'available': return 'Disponible';
      case 'sold':      return 'Vendu';
      case 'inactive':  return 'Masqué';
      case 'reserved':  return 'Réservé';
      case 'pending':   return 'En attente';
      case 'rejected':  return 'Rejeté';
      default:          return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available': return Colors.green;
      case 'sold':      return Colors.blue;
      case 'inactive':  return Colors.orange;
      case 'reserved':  return Colors.purple;
      case 'pending':   return Colors.amber;
      case 'rejected':  return Colors.red;
      default:          return Colors.grey;
    }
  }

  // ── Actions Firestore ──────────────────────────────────────────────────────
  Future<void> _toggleStatus(BuildContext context, String docId, String currentStatus) async {
    final newStatus = currentStatus == 'available' ? 'inactive' : 'available';
    await FirebaseFirestore.instance
        .collection('product')
        .doc(docId)
        .update({'status': newStatus});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 'available' ? 'Annonce publiée' : 'Annonce masquée'),
          backgroundColor: const Color(0xFF6B7F4D),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, String docId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'annonce ?'),
        content: Text('L\'annonce "$title" sera supprimée définitivement.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await FirebaseFirestore.instance.collection('product').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce supprimée'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.profile),
        ),
        title: const Text('Mes annonces',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Publier une annonce',
            onPressed: () => context.go(RouteNames.publish),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Connectez-vous pour voir vos annonces'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('product')
                  .where('sellerId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_mall_directory_outlined,
                            size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune annonce publiée',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => context.go(RouteNames.publish),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Publier une annonce'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B7F4D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final title = data['title'] as String? ?? 'Sans titre';
                    final price = data['price'];
                    final status = data['status'] as String? ?? 'available';
                    final images = data['imageUrls'] as List<dynamic>?;
                    final imageUrl = images?.isNotEmpty == true
                        ? images!.first as String
                        : null;
                    final canToggle =
                        status == 'available' || status == 'inactive';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(14)),
                            child: imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _placeholder(),
                                  )
                                : _placeholder(),
                          ),
                          const SizedBox(width: 12),
                          // Infos
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fmtPrice(price),
                                    style: const TextStyle(
                                      color: Color(0xFF6B7F4D),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Badge statut
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _statusLabel(status),
                                      style: TextStyle(
                                        color: _statusColor(status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Actions
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (canToggle)
                                IconButton(
                                  icon: Icon(
                                    status == 'available'
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  tooltip: status == 'available'
                                      ? 'Masquer'
                                      : 'Publier',
                                  onPressed: () =>
                                      _toggleStatus(context, docId, status),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                tooltip: 'Supprimer',
                                onPressed: () =>
                                    _delete(context, docId, title),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _placeholder() => Container(
        width: 90,
        height: 90,
        color: const Color(0xFFF7F4EE),
        child: const Icon(Icons.checkroom,
            size: 36, color: Color(0xFF6B7F4D)),
      );
}
