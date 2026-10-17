// ─── Bamako Thrift — Order Tracking Page ────────────────────────────────────
// Nouveau circuit (remplace le circuit pressing) :
// Vendu → Collecté (par le vendeur) → Reçu (par l'acheteur, termine la vente)
// Le vendeur et l'acheteur confirment eux-mêmes chaque étape, sans relais
// physique ni livreur ayant accès à l'app (cahier des charges v2).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bamako_thrift/core/dependency_injection/injection.dart';
import 'package:bamako_thrift/core/extensions/double_extension.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/services/logger_service.dart';
import 'package:bamako_thrift/core/services/storage_service.dart';

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
    return price.toPriceFCFA;
  }

  // ── Vendeur : "Marquer collecté" (le livreur externe est passé) ─────────
  Future<void> _markCollected() async {
    setState(() => _isSubmitting = true);
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('order').doc(widget.orderId).update({
        'status': 'collecte',
        'collectedAt': Timestamp.now(),
      });
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await db.collection('users').doc(uid).update({
          'lastActivityAt': Timestamp.now(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Article marqué comme collecté'),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
        // Compteur + signal d'activité pour la relance des utilisateurs
        // inactifs (profil "vendeur" vs "acheteur").
        await db.collection('users').doc(sellerId).update({
          'totalSales': FieldValue.increment(1),
          'lastActivityAt': Timestamp.now(),
        });
      }

      final buyerId = orderData['buyerId'] as String?;
      if (buyerId != null) {
        await db.collection('users').doc(buyerId).update({
          'totalPurchases': FieldValue.increment(1),
          'lastActivityAt': Timestamp.now(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Réception confirmée. Merci !'),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ID deterministe {orderId}_{buyerId} : un seul signalement actif par
    // commande et par acheteur (voir audit du 2026-10-08).
    final ncId = '${widget.orderId}_$uid';
    final existing = await FirebaseFirestore.instance
        .collection('non_conformities')
        .doc(ncId)
        .get();
    if (existing.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu as déjà déclaré un problème pour cette commande.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportIssueSheet(
        orderId: widget.orderId,
        orderData: orderData,
        ncId: ncId,
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signalement envoyé'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final colorScheme = Theme.of(context).colorScheme;
    // Mode clair strictement inchangé (blanc/gris Material ne correspondent
    // à aucun token exact de la palette claire, qui est en beige) : repli
    // sur les valeurs claires exactes en clair, token du thème en sombre.
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.push(RouteNames.orders),
        ),
        title: Text(
          'Remise de l\'article',
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('order')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
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
                    color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.primary.withOpacity(0.15)
                              : const Color(0xFFF7F4EE),
                          borderRadius: BorderRadius.circular(12),
                          image: productImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(productImageUrl),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: productImageUrl == null
                            ? Icon(Icons.checkroom, color: colorScheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productTitle,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface),
                            ),
                            Text(
                              _fmtPrice(totalAmount),
                              style: TextStyle(
                                color: colorScheme.primary,
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
                    'Étapes de ta commande',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2B2B2B)),
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
                  _buildStep(context, 'Vendu', 'Paiement reçu',
                      done: true, active: status == 'pending'),
                  _buildStep(context, 'Remis en main propre',
                      'Tu as remis l\'article à l\'acheteur',
                      done: status == 'collecte' || status == 'completed',
                      active: status == 'pending'),
                  _buildStep(context, 'Reçu', 'L\'acheteur a confirmé la réception',
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
                        icon: Icon(Icons.inventory_2_outlined,
                            color: colorScheme.onPrimary),
                        label: Text('Marquer comme remis',
                            style: TextStyle(color: colorScheme.onPrimary)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
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
                        icon: Icon(Icons.check_circle_outline,
                            color: colorScheme.onPrimary),
                        label: Text('Confirmer réception',
                            style: TextStyle(color: colorScheme.onPrimary)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
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
        return 'Vendu — en attente de la remise';
      case 'collecte':
        return 'Remise en main propre en cours';
      case 'completed':
        return 'Reçu';
      default:
        return status;
    }
  }

  Widget _buildStep(BuildContext context, String title, String subtitle,
      {required bool done, required bool active, bool isLast = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    ? colorScheme.primary
                    : active
                        ? colorScheme.primaryContainer
                        : (isDark
                            ? colorScheme.surfaceContainerHighest
                            : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check : Icons.circle,
                color: colorScheme.onPrimary,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: done
                    ? colorScheme.primary
                    : (isDark
                        ? colorScheme.surfaceContainerHighest
                        : Colors.grey.shade200),
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
                    color: done
                        ? colorScheme.onSurface
                        : (isDark ? colorScheme.onSurfaceVariant : Colors.grey),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
                      fontSize: 12),
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
  final String ncId;
  const _ReportIssueSheet({
    required this.orderId,
    required this.orderData,
    required this.ncId,
  });

  @override
  State<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<_ReportIssueSheet> {
  String _reason = '';
  final _descCtrl = TextEditingController();
  // XFile (pas dart:io.File) : readAsBytes() marche sur le web (lot
  // "putFile web", 2026-10-15).
  final List<XFile> _photos = [];
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
      setState(() => _photos.addAll(picked));
    }
  }

  Future<void> _submitKeepWithCompensation() async {
    if (!_validateBeforeSubmit()) return;
    setState(() => _isSending = true);
    try {
      final ncId = await _createNonConformity(status: 'buyer_continue');
      if (mounted) Navigator.pop(context, true);
      // La suite (évaluation du coût par l'équipe, acceptation vendeur)
      // est gérée côté admin, comme avant.
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _submitCancelSale() async {
    if (!_validateBeforeSubmit()) return;

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annulation de la vente'),
        content: const Text(
          'Comment souhaites-tu être remboursé ?\n\n'
          '(les frais de service de 1 000 FCFA restent acquis à la plateforme)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'avoir'),
            child: Text('Avoir (3 mois)',
                style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.primary),
            onPressed: () => Navigator.pop(ctx, 'remboursement'),
            child: Text('Remboursement',
                style: TextStyle(color: Theme.of(ctx).colorScheme.onPrimary)),
          ),
        ],
      ),
    );
    if (choice == null) return;

    setState(() => _isSending = true);
    try {
      final ncStatus =
          choice == 'avoir' ? 'buyer_refused_avoir' : 'buyer_refused_refund';
      await _createNonConformity(status: ncStatus);

      final db = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final amount =
          (widget.orderData['totalAmount'] as num?)?.toDouble() ?? 0;
            final productId = widget.orderData['productId'] as String?;

      // La vente est annulée, l'article redevient disponible
      await db.collection('order').doc(widget.orderId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
      if (productId != null) {
        await db
            .collection('product')
            .doc(productId)
            .update({'status': 'available'});
      }

      if (choice == 'avoir' && uid != null) {
        final walletRef = db.collection('wallet').doc(uid);
        await walletRef.set({
          'balance': FieldValue.increment(amount),
          'totalEarned': FieldValue.increment(amount),
        }, SetOptions(merge: true));
        await walletRef.collection('transactions').add({
          'type': 'credit',
          'label': 'Avoir — vente annulée (signalement)',
          'amount': amount,
          'orderId': widget.orderId,
          'createdAt': Timestamp.now(),
          'expiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 90))),
        });
      } else if (choice == 'remboursement' && uid != null) {
        // ID deterministe {orderId}_{buyerId} : une seule demande de
        // remboursement active par commande et par acheteur.
        await db
            .collection('refund_requests')
            .doc('${widget.orderId}_$uid')
            .set({
          'orderId': widget.orderId,
          'buyerId': uid,
          'amount': amount,
          'status': 'pending',
          'createdAt': Timestamp.now(),
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _validateBeforeSubmit() {
    if (_reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Choisis un motif'), backgroundColor: Colors.orange),
      );
      return false;
    }
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Au moins une photo est requise'),
            backgroundColor: Colors.orange),
      );
      return false;
    }
    return true;
  }

  void _showError(Object e) {
    // Jamais le message technique brut à l'écran — journalisé pour debug.
    final isUnsupportedImage = e is UnsupportedImageException;
    logger.severe('Échec signalement de litige', error: e.toString());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUnsupportedImage
              ? 'Cette photo n\'est pas compatible. Choisis une photo JPG ou PNG.'
              : 'L\'envoi a échoué. Vérifie ta connexion et réessaie.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _createNonConformity({required String status}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final storageService = sl<StorageService>();

    // Délai max par photo : sans ça, un envoi qui ne progresse jamais
    // laisse le dialogue bloqué indéfiniment sans erreur visible (même
    // constat que pour la publication, voir publish_product_page.dart).
    final photoUrls = <String>[];
    for (int i = 0; i < _photos.length; i++) {
      final url = await storageService
          .uploadDisputePhoto(_photos[i])
          .timeout(const Duration(seconds: 60));
      photoUrls.add(url);
    }

    // Photos de l'annonce initiale (déjà en ligne), pour comparaison par
    // l'équipe — plus besoin d'un relais pour les prendre séparément.
    final listingPhotoUrls =
        (widget.orderData['productImageUrl'] as String?) != null
            ? [widget.orderData['productImageUrl'] as String]
            : <String>[];

    final docRef =
        FirebaseFirestore.instance.collection('non_conformities').doc(widget.ncId);
    await docRef.set({
      'orderId': widget.orderId,
      'productId': widget.orderData['productId'],
      'productTitle': widget.orderData['productTitle'],
      'buyerId': uid,
      'sellerId': widget.orderData['sellerId'],
      'reason': _reason,
      'description': _descCtrl.text.trim(),
      'photoUrls': photoUrls,
      'listingPhotoUrls': listingPhotoUrls,
      'status': status,
      'createdAt': Timestamp.now(),
    });
    return docRef.id;
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
                final colorScheme = Theme.of(context).colorScheme;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return GestureDetector(
                  onTap: () => setState(() => _reason = r),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primary
                          : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary
                            : (isDark ? colorScheme.outlineVariant : Colors.grey.shade300),
                      ),
                    ),
                    child: Text(r,
                        style: TextStyle(
                            color: selected
                                ? colorScheme.onPrimary
                                : (isDark ? colorScheme.onSurface : Colors.black87),
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
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Décris le problème...',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.outlineVariant
                          : Colors.grey.shade300),
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                          : const Color(0xFFF7F4EE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                    ),
                    child: Icon(Icons.add_a_photo_outlined,
                        color: Theme.of(context).colorScheme.primary),
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
                        child: kIsWeb
                            ? Image.network(_photos[i].path,
                                width: 64, height: 64, fit: BoxFit.cover)
                            : Image.file(File(_photos[i].path),
                                width: 64, height: 64, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Que souhaites-tu faire ?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submitKeepWithCompensation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 2),
                      )
                    : Text('Garder avec dédommagement',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _isSending ? null : _submitCancelSale,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('Annuler et être remboursé',
                    style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
