// ─── Bamako Thrift — Feuille "Faire une offre" ─────────────────────────────
// Bouton réutilisable (fiche article) : propose un prix à l'acheteur, crée
// ou relance l'offre déterministe {productId}_{buyerId}, puis ouvre/retrouve
// la conversation et y poste la bulle d'offre (MessageType.offer + offerId)
// (lot "offres", voir PLAN_OFFRES.md).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/dependency_injection/injection.dart';
import '../../core/services/offers_config_service.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/entities/message_entity.dart';
import '../../features/offers/data/models/offer_model.dart';
import '../../features/offers/domain/entities/offer_entity.dart';
import '../../features/offers/domain/repositories/offers_repository.dart';
import '../../features/product/domain/entities/product_entity.dart';

Future<void> showMakeOfferSheet(
  BuildContext context, {
  required ProductEntity product,
  required UserEntity buyer,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _MakeOfferSheet(product: product, buyer: buyer),
  );
}

class _MakeOfferSheet extends StatefulWidget {
  final ProductEntity product;
  final UserEntity buyer;

  const _MakeOfferSheet({required this.product, required this.buyer});

  @override
  State<_MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<_MakeOfferSheet> {
  final _amountController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  OffersConfig _config = OffersConfig.fallback;
  OfferEntity? _existingOffer;

  OffersRepository get _repo => sl<OffersRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Les deux lectures sont indépendantes (audit lenteurs du 2026-10-17) :
    // en parallèle plutôt qu'en série.
    final results = await Future.wait([
      OffersConfigService.instance.getConfig(),
      _repo.getOffer(productId: widget.product.id, buyerId: widget.buyer.id),
    ]);
    if (!mounted) return;
    setState(() {
      _config = results[0] as OffersConfig;
      _existingOffer = results[1] as OfferEntity?;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _minAmount => widget.product.price * _config.minOfferRatio;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      setState(() => _error = 'Entrez un montant valide.');
      return;
    }
    if (amount >= widget.product.price) {
      setState(() => _error =
          'L\'offre doit être strictement inférieure au prix affiché.');
      return;
    }
    if (amount < _minAmount) {
      setState(() => _error =
          'L\'offre minimale est de ${_minAmount.toStringAsFixed(0)} FCFA '
          '(${(_config.minOfferRatio * 100).toStringAsFixed(0)} % du prix).');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // Résout d'abord la conversation : chatId est immuable une fois
      // l'offre créée (voir firestore.rules.chantier-candidat), il faut
      // le connaître AVANT la création, pas l'ajouter après coup.
      final chatRepo = ChatRepositoryImpl(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      );
      final chatId = await chatRepo.createOrGetChatWithUsers(
        participantIds: [widget.buyer.id, widget.product.sellerId],
        participantNames: {
          widget.buyer.id: widget.buyer.fullName,
          widget.product.sellerId: widget.product.sellerName,
        },
        participantAvatars: {
          widget.buyer.id: widget.buyer.avatarUrl,
          widget.product.sellerId: null,
        },
        productId: widget.product.id,
        productTitle: widget.product.title,
      );

      await _repo.createOrRelance(
        productId: widget.product.id,
        productTitle: widget.product.title,
        productImageUrl: widget.product.mainImageUrl,
        sellerId: widget.product.sellerId,
        buyerId: widget.buyer.id,
        originalPrice: widget.product.price,
        offerPrice: amount,
        chatId: chatId,
      );

      // Best-effort : l'offre existe déjà si l'envoi du message échoue.
      try {
        final offerId = OfferModel.buildId(
          productId: widget.product.id,
          buyerId: widget.buyer.id,
        );
        await chatRepo.sendMessage(
          chatId: chatId,
          content: 'Offre : ${amount.toStringAsFixed(0)} FCFA',
          type: MessageType.offer,
          offerId: offerId,
        );
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre envoyée au vendeur.'),
            backgroundColor: Color(0xFF6B7F4D),
          ),
        );
      }
    } on OfferAlreadyActiveException {
      setState(() => _error =
          'Tu as déjà une offre en cours sur cet article.');
    } catch (e) {
      setState(() => _error = 'Erreur : impossible d\'envoyer l\'offre.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildContent(colors),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    final existing = _existingOffer;

    if (existing != null && existing.status == OfferStatus.pending) {
      return _buildInfoState(
        colors: colors,
        icon: Icons.hourglass_top,
        title: 'Offre en attente',
        message: 'Tu as déjà proposé '
            '${existing.currentPrice.toStringAsFixed(0)} FCFA pour cet '
            'article. En attente de la réponse du vendeur.',
      );
    }

    if (existing != null && existing.status == OfferStatus.accepted) {
      return _buildInfoState(
        colors: colors,
        icon: Icons.check_circle_outline,
        title: 'Offre acceptée',
        message: 'Le vendeur a accepté ton offre de '
            '${existing.currentPrice.toStringAsFixed(0)} FCFA. '
            'Mets-toi d\'accord sur la remise avec lui.',
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faire une offre',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Prix affiché : ${widget.product.price.toStringAsFixed(0)} FCFA. '
          'Minimum : ${_minAmount.toStringAsFixed(0)} FCFA '
          '(${(_config.minOfferRatio * 100).toStringAsFixed(0)} % du prix).',
          style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Ton montant (FCFA)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7F4D),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Envoyer l\'offre',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoState({
    required ColorScheme colors,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6B7F4D)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ),
      ],
    );
  }
}
