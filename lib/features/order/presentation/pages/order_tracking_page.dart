// ─── Bamako Thrift — Order Tracking Page ────────────────────────────────────
// Nouveau circuit (remplace le circuit pressing) :
// Vendu → Collecté (par le vendeur) → Reçu (par l'acheteur, termine la vente)
// Le vendeur et l'acheteur confirment eux-mêmes chaque étape, sans relais
// physique ni livreur ayant accès à l'app (cahier des charges v2).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:bamako_thrift/core/router/route_names.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  bool _isSubmitting = false;

  String _fmtPrice(dynamic p) {
    final price = (p is num) ? p.toDouble() : 0.0;
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA';
  }

  bool get _isSeller {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null;
  }

  // ── Vendeur : "Marquer collecté" (le livreur externe est passé) ─────────
  Future<void> _markCollected() async {
    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('order')
          .doc(widget.orderId)
          .update({
        'status': 'collecte',
        'collectedAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article marqué comme collecté'),
            backgroundColor: Color(0xFF6B7F4D),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Acheteur : "Confirmer réception" ─────────────────────────────────────
  // Règle métier (Fatou) : même si le vendeur a oublié de marquer "Collecté",
  // la confirmation de l'acheteur fait passer la commande à "terminée" —
  // on ne bloque jamais la transaction sur cet oubli.
  // Les fonds sont libérés immédiatement au vendeur (pas de Cloud Function
  // disponible pour un délai automatique de 24h à ce stade).
  Future<void> _confirmReceipt(Map<String, dynamic> orderData) async {
    setState(() => _isSubmitting = true);
    try {
      final db = FirebaseFirestore.instance;
      final sellerId = orderData['sellerId'] as String?;
      final totalAmount = (orderData['totalAmount'] as num?)?.toDouble() ?? 0;
      final productTitle = orderData['productTitle'] as String? ?? 'Article';

      await db.collection('order').doc(widget.orderId).update({
        'status': 'completed',
        'receivedAt': Timestamp.now(),
      });

      // Libère les fonds au vendeur (moins les frais de service déjà
      // retenus au moment du paiement — voir payment_page.dart).
      if (sellerId != null) {
        final walletRef = db.collection('wallet').doc(sellerId);
        await walletRef.set({
          'balance': FieldValue.increment(totalAmount),
          'totalEarned': FieldValue.increment(totalAmount),
        }, SetOptions(merge: true));
        await walletRef.collection('transactions').add({
          'type': 'credit',
          'label': 'Vente — $productTitle',
          'amount': totalAmount,
          'orderId': widget.orderId,
          'createdAt': Timestamp.now(),
          'expiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 90))),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réception confirmée. Merci !'),
            backgroundColor: Color(0xFF6B7F4D),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Acheteur : signaler un problème (fenêtre 24h après réception) ───────
  // Remplace l'ancien système où le relais photographiait l'article à la
  // réception : désormais l'équipe compare les photos de l'annonce
  // (déjà en ligne) aux photos envoyées ici par l'acheteur.
  Future<void> _reportIssue(Map<String, dynamic> orderData) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportIssueSheet(
        orderId: widget.orderId,
        orderData: orderData,
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signalement envoyé à l\'équipe'),
          backgroundColor: Color(0xFF6B7F4D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.push(RouteNames.orders),
        ),
        title: const Text(
          'Suivi de commande',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('order')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
            );
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Commande introuvable'));
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'pending';
          final productTitle = data['productTitle'] as String? ?? 'Article';
          final productImageUrl = data['productImageUrl'] as String?;
          final totalAmount = data['totalAmount'];
          final sellerId = data['sellerId'] as String?;
          final buyerId = data['buyerId'] as String?;
          final receivedAt = data['receivedAt'] as Timestamp?;

          final isCancelled = status == 'cancelled';
          final isSellerOfThisOrder = uid != null && uid == sellerId;
          final isBuyerOfThisOrder = uid != null && uid == buyerId;

          // Fenêtre de 24h pour signaler un problème après réception
          final canReport = status == 'completed' &&
              receivedAt != null &&
              DateTime.now()
                  .isBefore(receivedAt.toDate().add(const Duration(hours: 24)));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Article
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4EE),
                          borderRadius: BorderRadius.circular(12),
                          image: productImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(productImageUrl),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: productImageUrl == null
                            ? const Icon(Icons.checkroom,
                                color: Color(0xFF6B7F4D))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productTitle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _fmtPrice(totalAmount),
                              style: const TextStyle(
                                color: Color(0xFF6B7F4D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isCancelled
                                  ? 'Annulée'
                                  : _statusLabel(status),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Étapes de votre commande',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 16),

                if (isCancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Cette commande a été annulée.',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else ...[
                  _buildStep('Vendu', 'Paiement reçu',
                      done: true, active: status == 'pending'),
                  _buildStep('Collecté', 'Récupéré chez le vendeur',
                      done: status == 'collecte' || status == 'completed',
                      active: status == 'pending'),
                  _buildStep('Reçu', 'Livré à l\'acheteur',
                      done: status == 'completed',
                      active: status == 'collecte',
                      isLast: true),
                ],

                const SizedBox(height: 24),

                // ── Actions selon le rôle et l'étape ────────────────────────
                if (!isCancelled) ...[
                  if (isSellerOfThisOrder && status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _markCollected,
                        icon: const Icon(Icons.inventory_2_outlined,
                            color: Colors.white),
                        label: const Text('Marquer collecté',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7F4D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  if (isBuyerOfThisOrder &&
                      (status == 'pending' || status == 'collecte'))
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isSubmitting ? null : () => _confirmReceipt(data),
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.white),
                        label: const Text('Confirmer réception',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7F4D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  if (isBuyerOfThisOrder && canReport) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _reportIssue(data),
                        icon: Icon(Icons.report_problem_outlined,
                            color: Colors.red.shade600),
                        label: Text('Signaler un problème',
                            style: TextStyle(color: Colors.red.shade600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Disponible pendant 24h après la réception',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Vendu — en attente de collecte';
      case 'collecte':
        return 'Collecté — en cours de livraison';
      case 'completed':
        return 'Reçu';
      default:
        return status;
    }
  }

  Widget _buildStep(String title, String subtitle,
      {required bool done, required bool active, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done
                    ? const Color(0xFF6B7F4D)
                    : active
                        ? const Color(0xFFD4E4B8)
                        : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check : Icons.circle,
                color: Colors.white,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: done ? const Color(0xFF6B7F4D) : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: done ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fiche de signalement acheteur (remplace la NC créée par un relais) ─────
class _ReportIssueSheet extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  const _ReportIssueSheet({required this.orderId, required this.orderData});

  @override
  State<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<_ReportIssueSheet> {
  String _reason = '';
  final _descCtrl = TextEditingController();
  final List<File> _photos = [];
  bool _isSending = false;

  final List<String> _reasons = [
    'Article endommagé',
    'Ne correspond pas à l\'annonce',
    'Taille incorrecte',
    'Article manquant',
    'Autre',
  ];

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 75, limit: 5);
    if (picked.isNotEmpty) {
      setState(() => _photos.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _submit() async {
    if (_reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Choisis un motif'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Au moins une photo est requise'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final storage = FirebaseStorage.instance;

      final photoUrls = <String>[];
      for (int i = 0; i < _photos.length; i++) {
        final ref = storage.ref(
            'non_conformities/$uid/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(_photos[i]);
        photoUrls.add(await ref.getDownloadURL());
      }

      // Photos de l'annonce initiale (déjà en ligne), pour comparaison par
      // l'équipe — plus besoin d'un relais pour les prendre séparément.
      final listingPhotoUrls =
          (widget.orderData['productImageUrl'] as String?) != null
              ? [widget.orderData['productImageUrl'] as String]
              : <String>[];

      await FirebaseFirestore.instance.collection('non_conformities').add({
        'orderId': widget.orderId,
        'productId': widget.orderData['productId'],
        'productTitle': widget.orderData['productTitle'],
        'buyerId': uid,
        'sellerId': widget.orderData['sellerId'],
        'reason': _reason,
        'description': _descCtrl.text.trim(),
        'photoUrls': photoUrls,
        'listingPhotoUrls': listingPhotoUrls,
        'status': 'awaiting_buyer_choice',
        'createdAt': Timestamp.now(),
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Signaler un problème',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Motif *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((r) {
                final selected = _reason == r;
                return GestureDetector(
                  onTap: () => setState(() => _reason = r),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF6B7F4D) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF6B7F4D)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(r,
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontSize: 12)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Décris le problème...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Photos (preuve) *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickPhotos,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4EE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF6B7F4D).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined,
                        color: Color(0xFF6B7F4D)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_photos[i],
                            width: 64, height: 64, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7F4D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Envoyer',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
