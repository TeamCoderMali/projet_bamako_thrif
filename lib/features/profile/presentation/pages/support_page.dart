import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/constants/feature_flags.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/services/payment_config_service.dart';

class FaqItem {
  final String question;
  final String answer;
  // Marque les questions liées au pressing (badge "Vérifié"), masquées tant
  // que pressingEnabled=false — un champ dédié plutôt qu'une comparaison de
  // texte, pour ne pas dépendre du libellé exact de la question (fragile :
  // les deux variantes ci-dessous n'utilisent déjà plus la même formulation
  // pour cette question depuis le lot 1, 2026-10-12).
  final bool requiresPressing;
  const FaqItem(this.question, this.answer, {this.requiresPressing = false});
}

// ─── Contenu FAQ, centralisé ici (seul endroit à modifier) ─────────────────
// Deux variantes selon l'interrupteur de paiement (config/payment, lu via
// PaymentConfigService — même repli que le bouton Acheter : actif par
// défaut).

// Variante "paiement sécurisé" = textes ACTUELS, passés en tutoiement
// (lot 1, 2026-10-12). Contenu pas réécrit : Fatou le fera elle-même avant
// la réactivation du paiement.
const _faqPaiementSecurise = <FaqItem>[
  FaqItem(
    'Comment vendre un article ?',
    'Clique sur "Publier" en bas de l\'écran, ajoute des photos, remplis les informations et publie gratuitement.',
  ),
  FaqItem(
    'Comment se passe la remise de l\'article ?',
    'La remise de l\'article se fait en main propre, directement avec le vendeur. Mets-toi d\'accord avec lui sur le lieu et l\'heure.',
  ),
  FaqItem(
    'Comment fonctionne le paiement ?',
    'L\'argent est bloqué jusqu\'à validation par notre équipe. Tu peux payer via Orange Money, Moov Money ou ton avoir.',
  ),
  FaqItem(
    'Qu\'est-ce que le badge Vérifié ?',
    'Le badge Vérifié signifie que notre équipe a inspecté, lavé et repassé le vêtement avant remise à l\'acheteur.',
    requiresPressing: true,
  ),
  FaqItem(
    'Que faire si mon colis ne correspond pas ?',
    'Tu peux refuser le vêtement et être remboursé, ou accepter avec une remise en état à la charge du vendeur.',
  ),
  FaqItem(
    'Combien de temps pour récupérer mon article ?',
    'Tu as 7 jours après notification pour récupérer ton article. Des frais de garde s\'appliquent à partir du 8e jour.',
  ),
];

// Variante "paiement désactivé" (phase test) — texte validé par Fatou
// (2026-10-12), tutoiement, aucun mot changé.
const _faqPaiementDesactive = <FaqItem>[
  FaqItem(
    'Comment publier un article ?',
    'Clique sur « Je publie », ajoute des photos, décris ton article et son état, fixe ton prix. Ton annonce est en ligne en quelques minutes.',
  ),
  FaqItem(
    'Comment contacter un vendeur ou un acheteur ?',
    'Depuis la fiche de l\'article, clique sur « Contacter le vendeur » pour lui envoyer un message. Les acheteurs te contactent de la même façon.',
  ),
  FaqItem(
    'Comment faire une offre ?',
    'Sur la fiche d\'un article, clique sur « Faire une offre » et propose ton prix. Le vendeur a 72 heures pour te répondre : il peut accepter, refuser ou te faire une contre-offre.',
  ),
  FaqItem(
    'Comment se passe la remise de l\'article ?',
    'La remise de l\'article se fait en main propre, directement avec le vendeur. Mets-toi d\'accord avec lui sur le lieu et l\'heure.',
  ),
  FaqItem(
    'Que faire en cas de problème avec un article ?',
    'Signale-le-nous directement depuis la conversation ou la fiche de l\'article. On ne peut pas intervenir sur la transaction elle-même, mais si c\'est frauduleux ou suspect, on peut mettre en garde contre le vendeur, surtout s\'il s\'agit d\'un Vendeur Pro.',
  ),
  FaqItem(
    'Comment fonctionne le badge Vérifié ?',
    'Il est attribué aux articles vérifiés et remis en état par notre pressing partenaire avant publication.',
    requiresPressing: true,
  ),
  FaqItem(
    'Le paiement est-il sécurisé dans l\'app ?',
    'Pas encore : pour l\'instant, tu t\'arranges directement avec le vendeur pour le paiement et la remise de l\'article. Le paiement intégré arrive bientôt !',
  ),
];

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  // Repli = paiement désactivé (même choix que partout ailleurs, voir
  // PaymentConfigService) tant que la config n'est pas chargée ou si la
  // lecture échoue — donc variante "phase de test" par défaut.
  bool _paymentEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentConfig();
  }

  Future<void> _loadPaymentConfig() async {
    final enabled = await PaymentConfigService.instance.isPaymentEnabled();
    if (mounted) setState(() => _paymentEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    // Le partenaire pressing n'existe pas encore pour Fatou : la question est
    // masquée (texte conservé dans les listes ci-dessus) sans rien supprimer.
    final faq = (_paymentEnabled ? _faqPaiementSecurise : _faqPaiementDesactive)
        .where((item) => pressingEnabled || !item.requiresPressing)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.profile),
        ),
        title: Text(
          'Aide & Support',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact
            Text(
              'Nous contacter',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              context,
              Icons.email_outlined,
              'Email',
              'support@danaya.ml',
            ),
            _buildContactItem(
              context,
              Icons.phone_outlined,
              'WhatsApp',
              '+223 XX XX XX XX',
            ),
            const SizedBox(height: 24),

            // FAQ
            Text(
              'Questions fréquentes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in faq)
              _buildFaq(context, item.question, item.answer),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
      BuildContext context, IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaq(BuildContext context, String question, String reponse) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              reponse,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
