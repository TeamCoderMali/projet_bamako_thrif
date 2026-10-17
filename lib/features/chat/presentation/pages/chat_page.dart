import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bamako_thrift/core/dependency_injection/injection.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/services/offers_config_service.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bamako_thrift/features/chat/domain/entities/message_entity.dart';
import 'package:bamako_thrift/features/offers/domain/entities/offer_entity.dart';
import 'package:bamako_thrift/features/offers/domain/repositories/offers_repository.dart';
import 'package:bamako_thrift/shared/widgets/report_dialog.dart';
import 'package:bamako_thrift/shared/widgets/vendeur_pro_badge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatRepositoryImpl _chatRepo;

  String _otherName = 'Conversation';
  String? _otherAvatarUrl;
  bool _otherIsVendeurPro = false;

  @override
  void initState() {
    super.initState();
    _chatRepo = ChatRepositoryImpl(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    // Marquer comme lu au chargement
    _chatRepo.markAsRead(widget.chatId).catchError((_) {});
    _loadOtherParticipant();
    _maybeShowWarningDialog();
  }

  // Lot 4 (2026-10-13) : avertissement affiché une seule fois par
  // conversation et par utilisateur — clé locale (SharedPreferences), pas
  // un champ Firestore : simple repli "déjà vu", pas une donnée à
  // synchroniser entre appareils.
  Future<void> _maybeShowWarningDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'warning_seen_${uid}_${widget.chatId}';
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        // Le bouton retour du téléphone ne doit pas fermer ce pop-up :
        // seule la croix (pop explicite) le ferme.
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                  child: Text(
                    'Danaya ne garantit pas les transactions entre vous, '
                    'et n\'intervient pas en cas de retour ou de litige',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Le document chat dénormalise déjà nom/avatar des participants (pas de
  // lecture supplémentaire) ; isVendeurPro n'y est pas dupliqué, d'où la
  // lecture ponctuelle du doc users/{uid}. Échec silencieux : l'en-tête
  // garde son libellé générique plutôt que de bloquer l'écran.
  Future<void> _loadOtherParticipant() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final chatDoc = await FirebaseFirestore.instance
          .collection('chat')
          .doc(widget.chatId)
          .get();
      final data = chatDoc.data();
      if (data == null) return;
      final participantIds =
          (data['participantIds'] as List?)?.cast<String>() ?? <String>[];
      final otherUid =
          participantIds.firstWhere((id) => id != currentUid, orElse: () => '');
      if (otherUid.isEmpty) return;
      final names = (data['participantNames'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final avatars =
          (data['participantAvatars'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .get();
      if (!mounted) return;
      setState(() {
        _otherName = names[otherUid] as String? ?? 'Utilisateur';
        _otherAvatarUrl = avatars[otherUid] as String?;
        _otherIsVendeurPro = userDoc.data()?['isVendeurPro'] == true;
      });
    } catch (_) {
      // Repli silencieux, voir commentaire ci-dessus.
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    try {
      await _chatRepo.sendMessage(chatId: widget.chatId, content: text);
      // Scroll vers le bas
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur envoi : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _chatRepo.deleteMessage(
        chatId: widget.chatId,
        messageId: messageId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur suppression : $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthCubit>().currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.messages),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: (_otherAvatarUrl != null &&
                      _otherAvatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(_otherAvatarUrl!)
                  : null,
              child: (_otherAvatarUrl == null || _otherAvatarUrl!.isEmpty)
                  ? Text(
                      _otherName.isNotEmpty
                          ? _otherName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _otherName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_otherIsVendeurPro) ...[
                        const SizedBox(width: 6),
                        const VendeurProBadge(),
                      ],
                    ],
                  ),
                  const Text('En ligne',
                      style: TextStyle(color: Colors.green, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.flag_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            tooltip: 'Signaler',
            onPressed: () => showReportDialog(
              context,
              targetType: ReportTargetType.chat,
              targetId: widget.chatId,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages en temps réel ──────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<MessageEntity>>(
              stream: _chatRepo.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Commencez la conversation !',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUid;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      currentUid: currentUid,
                      onDelete: isMe ? () => _deleteMessage(message.id) : null,
                    );
                  },
                );
              },
            ),
          ),

          // ── Barre d'envoi ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send,
                          color: Theme.of(context).colorScheme.onPrimary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bulle message ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final String currentUid;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.currentUid,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.offer && message.offerId != null) {
      return Align(
        child: _OfferMessageBubble(
          offerId: message.offerId!,
          currentUid: currentUid,
        ),
      );
    }
    return GestureDetector(
      onLongPress: isMe && onDelete != null
          ? () => _showDeleteConfirmation(context)
          : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isMe
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: isMe
                      ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le message ?'),
        content: const Text('Cette action est irréversible.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Bulle d'offre ──────────────────────────────────────────────────────────
// S'abonne en direct à offers/{offerId} plutôt que d'afficher un contenu
// figé (voir PLAN_OFFRES.md). Vérifie aussi l'expiration paresseuse à
// chaque rendu (pas de cron serveur).
class _OfferMessageBubble extends StatefulWidget {
  final String offerId;
  final String currentUid;

  const _OfferMessageBubble({
    required this.offerId,
    required this.currentUid,
  });

  @override
  State<_OfferMessageBubble> createState() => _OfferMessageBubbleState();
}

class _OfferMessageBubbleState extends State<_OfferMessageBubble> {
  bool _expireChecked = false;
  bool _acting = false;

  OffersRepository get _repo => sl<OffersRepository>();

  void _maybeExpire(OfferEntity offer) {
    if (_expireChecked) return;
    if (offer.status == OfferStatus.pending &&
        DateTime.now().isAfter(offer.respondBy)) {
      _expireChecked = true;
      _repo.expireIfNeeded(offer);
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action impossible, réessayez.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _showCounterDialog(OfferEntity offer) async {
    final config = await OffersConfigService.instance.getConfig();
    final minAmount = offer.originalPrice * config.minOfferRatio;
    final controller = TextEditingController();
    String? error;

    final newPrice = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Contre-proposer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entre ${minAmount.toStringAsFixed(0)} et '
                '${offer.originalPrice.toStringAsFixed(0)} FCFA.',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Montant (FCFA)'),
              ),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(controller.text.trim());
                if (v == null || v < minAmount || v > offer.originalPrice) {
                  setDialogState(() => error =
                      'Montant hors bornes (${minAmount.toStringAsFixed(0)} - '
                      '${offer.originalPrice.toStringAsFixed(0)} FCFA).');
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('Proposer'),
            ),
          ],
        ),
      ),
    );
    if (newPrice == null) return;
    await _act(() => _repo.counter(offerId: offer.id, newPrice: newPrice));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OfferEntity?>(
      stream: _repo.watchOffer(widget.offerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final offer = snapshot.data!;
        _maybeExpire(offer);

        final isBuyer = widget.currentUid == offer.buyerId;
        final myTurn = isBuyer
            ? offer.turn == OfferTurn.buyer
            : offer.turn == OfferTurn.seller;
        final colors = Theme.of(context).colorScheme;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer_outlined,
                      color: colors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Offre : ${offer.currentPrice.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _statusText(offer, isBuyer, myTurn),
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
              if (offer.status == OfferStatus.pending) ...[
                const SizedBox(height: 10),
                if (_acting)
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (myTurn)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => _act(() => _repo.accept(offer.id)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                        ),
                        child: Text('Accepter',
                            style: TextStyle(color: colors.onPrimary)),
                      ),
                      OutlinedButton(
                        onPressed: () => _act(() => _repo.reject(offer.id)),
                        child: const Text('Refuser'),
                      ),
                      OutlinedButton(
                        onPressed: () => _showCounterDialog(offer),
                        child: const Text('Contre-proposer'),
                      ),
                    ],
                  )
                else if (isBuyer)
                  OutlinedButton(
                    onPressed: () => _act(() => _repo.cancel(offer.id)),
                    child: const Text('Annuler l\'offre'),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _statusText(OfferEntity offer, bool isBuyer, bool myTurn) {
    switch (offer.status) {
      case OfferStatus.accepted:
        return 'Offre acceptée, mets-toi d\'accord sur la remise dans le chat.';
      case OfferStatus.rejected:
        return 'Offre refusée.';
      case OfferStatus.cancelled:
        return 'Offre annulée.';
      case OfferStatus.expired:
        return 'Offre expirée (délai de réponse dépassé).';
      case OfferStatus.pending:
        return myTurn
            ? 'À toi de répondre.'
            : 'En attente de la réponse de l\'autre partie.';
    }
  }
}
