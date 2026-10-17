// ─── Bamako Thrift — Conditions d'utilisation ──────────────────────────────
// Texte provisoire (2026-10-16), à valider par Fatou avant toute
// publication sur les stores — voir le bandeau affiché en haut de l'écran.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Mode clair strictement inchangé (voir privacy_page.dart, même motif) :
    // repli sur les valeurs claires exactes en clair, token du thème en sombre.
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
              : context.go(RouteNames.settings),
        ),
        title: Text(
          'Conditions d\'utilisation',
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Texte provisoire, à valider par Fatou.',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Conditions d\'utilisation',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Publier un article',
              'Tu peux publier un article à vendre s\'il t\'appartient et si '
                  'tu en décris l\'état honnêtement. DANAYA peut refuser ou '
                  'masquer un article qui ne respecte pas ces règles, ou qui '
                  'enfreint la loi (contrefaçon, objet interdit).',
            ),
            _buildSection(
              context,
              'Frais de service',
              'DANAYA prélève des frais de service de 1 000 FCFA par vente '
                  'conclue sur la plateforme. Ces frais restent acquis à '
                  'DANAYA même en cas d\'annulation après le paiement.',
            ),
            _buildSection(
              context,
              'Remise en main propre',
              'La remise de l\'article se fait en main propre entre '
                  'l\'acheteur et le vendeur, via le circuit de livraison de '
                  'l\'app. L\'acheteur confirme la réception une fois '
                  'l\'article reçu et vérifié ; c\'est cette confirmation qui '
                  'termine la vente.',
            ),
            _buildSection(
              context,
              'Litiges',
              'Si l\'article reçu ne correspond pas à l\'annonce, tu peux '
                  'signaler un problème avec des photos avant de confirmer la '
                  'réception. L\'équipe DANAYA examine le signalement et '
                  'décide de la suite (remise en état, avoir ou '
                  'remboursement).',
            ),
            _buildSection(
              context,
              'Compte et sanctions',
              'Un compte qui enfreint ces règles de façon répétée peut être '
                  'suspendu ou banni. Tu peux supprimer ton compte à tout '
                  'moment depuis les paramètres, sauf si une commande, une '
                  'offre ou un litige est encore en cours.',
            ),
            const SizedBox(height: 24),
            Text(
              'Dernière mise à jour : Octobre 2026 (brouillon)',
              style: TextStyle(
                  color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String titre, String contenu) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            contenu,
            style: TextStyle(
                color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}
