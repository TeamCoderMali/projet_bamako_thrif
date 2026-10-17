import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/services/payment_config_service.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  // Repli = desactive, meme choix que partout ailleurs. Lot 9.
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
              : context.go(RouteNames.settings),
        ),
        title: Text(
          'Confidentialité',
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Politique de confidentialité',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Collecte des données',
              'Bamako Thrift collecte uniquement les données nécessaires au bon fonctionnement de la plateforme : nom, téléphone, email et historique des transactions.',
            ),
            _buildSection(
              context,
              'Utilisation des données',
              'Tes données sont utilisées pour gérer ton compte, sécuriser tes transactions et améliorer ton expérience sur la plateforme.',
            ),
            _buildSection(
              context,
              'Sécurité',
              'Toutes tes données sont chiffrées et stockées de manière sécurisée. Nous ne partageons jamais tes informations avec des tiers.',
            ),
            _buildSection(
              context,
              'Paiements',
              _paymentEnabled
                  ? 'Les paiements sont traités via Orange Money et Moov Money. Les fonds sont bloqués jusqu\'à validation de la transaction par notre équipe.'
                  : 'Pendant la phase de test, Danaya n\'intervient pas dans le paiement : il se fait directement entre l\'acheteur et le vendeur, en dehors de l\'app.',
            ),
            _buildSection(
              context,
              'Tes droits',
              'Tu peux demander la suppression de ton compte et de tes données à tout moment en contactant notre support.',
            ),
            const SizedBox(height: 24),
            Text(
              'Dernière mise à jour : Juillet 2026',
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
