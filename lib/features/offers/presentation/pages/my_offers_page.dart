// ─── Bamako Thrift — Mes offres (acheteur) ─────────────────────────────────
// Liste les offres faites par l'acheteur connecté, groupées par statut.
// Au chargement, fait aussi expirer celles dont le délai de réponse (72h)
// est dépassé (expiration paresseuse, pas de cron serveur).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bamako_thrift/core/dependency_injection/injection.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/offers/domain/entities/offer_entity.dart';
import 'package:bamako_thrift/features/offers/domain/repositories/offers_repository.dart';

class MyOffersPage extends StatefulWidget {
  const MyOffersPage({super.key});

  @override
  State<MyOffersPage> createState() => _MyOffersPageState();
}

class _MyOffersPageState extends State<MyOffersPage> {
  OffersRepository get _repo => sl<OffersRepository>();
  final Set<String> _checkedForExpiry = {};

  void _maybeExpire(OfferEntity offer) {
    if (_checkedForExpiry.contains(offer.id)) return;
    _checkedForExpiry.add(offer.id);
    if (offer.status == OfferStatus.pending &&
        DateTime.now().isAfter(offer.respondBy)) {
      _repo.expireIfNeeded(offer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyerId = context.read<AuthCubit>().currentUser?.id;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.profile),
        ),
        title: Text(
          'Mes offres',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: buyerId == null
          ? const Center(child: Text('Connecte-toi pour voir tes offres'))
          : StreamBuilder<List<OfferEntity>>(
              stream: _repo.watchBuyerOffers(buyerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final offers = snapshot.data ?? [];
                if (offers.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune offre pour le moment.\n'
                      'Proposez un prix depuis la fiche d\'un article.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  );
                }
                for (final offer in offers) {
                  _maybeExpire(offer);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: offers.length,
                  itemBuilder: (_, i) => _OfferTile(offer: offers[i]),
                );
              },
            ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final OfferEntity offer;

  const _OfferTile({required this.offer});

  (String, Color) _statusLabelColor() {
    switch (offer.status) {
      case OfferStatus.pending:
        return ('En attente', Colors.amber);
      case OfferStatus.accepted:
        return ('Acceptée', Colors.green);
      case OfferStatus.rejected:
        return ('Refusée', Colors.red);
      case OfferStatus.cancelled:
        return ('Annulée', Colors.grey);
      case OfferStatus.expired:
        return ('Expirée', Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = _statusLabelColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: offer.chatId != null
            ? () => context.push('/messages/${offer.chatId}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: offer.productImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: offer.productImageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(colors),
                        errorWidget: (_, __, ___) => _placeholder(colors),
                      )
                    : _placeholder(colors),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.productTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offer.currentPrice.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (offer.chatId != null)
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colors) => Container(
        width: 56,
        height: 56,
        color: colors.surfaceContainerHighest,
        child: Icon(Icons.checkroom, size: 24, color: colors.onSurfaceVariant),
      );
}
