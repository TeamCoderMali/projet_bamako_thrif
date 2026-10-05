import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/constants/feature_flags.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/services/payment_config_service.dart';

class FaqItem {
  final String question;
  final String answer;
  const FaqItem(this.question, this.answer);
}

// ─── Contenu FAQ, centralisé ici (seul endroit à modifier) ─────────────────
// Deux variantes selon l'interrupteur de paiement (config/payment, lu via
// PaymentConfigService — même repli que le bouton Acheter : actif par
// défaut). "Comment vendre un article ?" est identique dans les deux.

// Variante "paiement sécurisé" = textes ACTUELS, volontairement non modifiés
// ici. Fatou les réécrira elle-même avant la réactivation du paiement.
const _faqPaiementSecurise = <FaqItem>[
  FaqItem(
    'Comment vendre un article ?',
    'Cliquez sur "Publier" en bas de l\'écran, ajoutez des photos, remplissez les informations et publiez gratuitement.',
  ),
  FaqItem(
    'Comment fonctionne le paiement ?',
    'L\'argent est bloqué jusqu\'à validation par notre équipe. Vous pouvez payer via Orange Money, Moov Money ou votre avoir.',
  ),
  FaqItem(
    'Qu\'est-ce que le badge Vérifié ?',
    'Le badge Vérifié signifie que notre équipe a inspecté, lavé et repassé le vêtement avant remise à l\'acheteur.',
  ),
  FaqItem(
    'Que faire si mon colis ne correspond pas ?',
    'Vous pouvez refuser le vêtement et être remboursé, ou accepter avec une remise en état à la charge du vendeur.',
  ),
  FaqItem(
    'Combien de temps pour récupérer mon article ?',
    'Vous avez 7 jours après notification pour récupérer votre article. Des frais de garde s\'appliquent à partir du 8e jour.',
  ),
];

// Variante "paiement désactivé" (phase test) — textes exacts fournis par
// Fatou, aucun mot changé.
const _faqPaiementDesactive = <FaqItem>[
  FaqItem(
    'Comment vendre un article ?',
    'Cliquez sur "Publier" en bas de l\'écran, ajoutez des photos, remplissez les informations et publiez gratuitement.',
  ),
  FaqItem(
    'Comment fonctionne le paiement ?',
    'Pour l\'instant, Danaya est en phase de test : le paiement se fait directement entre l\'acheteur et le vendeur, en dehors de l\'app. Transaction directe — non sécurisée par Danaya. Danaya ne garantit ni le paiement ni la livraison. Contactez le vendeur via la messagerie pour vous mettre d\'accord.',
  ),
  FaqItem(
    'Qu\'est-ce que le badge Vérifié ?',
    'Le badge Vérifié signifie que notre équipe a inspecté, lavé et repassé le vêtement avant remise à l\'acheteur.',
  ),
  FaqItem(
    'Que faire si mon colis ne correspond pas ?',
    'Contactez d\'abord le vendeur via la messagerie pour trouver une solution ensemble. Si le problème persiste, utilisez le bouton « Signaler ». Pendant la phase de test, Danaya ne peut pas rembourser les transactions.',
  ),
  FaqItem(
    'Combien de temps pour récupérer mon article ?',
    'La remise de l\'article (rendez-vous ou livraison) s\'organise directement avec le vendeur via la messagerie.',
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
        .where((item) => pressingEnabled || item.question != 'Qu\'est-ce que le badge Vérifié ?')
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B7F4D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go(RouteNames.profile),
        ),
        title: const Text(
          'Aide & Support',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          Icon(icon, color: const Color(0xFF6B7F4D)),
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
