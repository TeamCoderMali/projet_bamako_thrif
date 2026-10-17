import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Mode clair strictement inchangé (blanc/gris Material ne correspondent
    // à aucun token exact de la palette claire) : repli explicite en clair,
    // token du thème en sombre.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
        title: Text(
          'Dashboard Admin',
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats du jour
            Text(
              'Aujourd\'hui',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStat(context, 'Ventes', '12', colorScheme.primary, Icons.sell),
                _buildStat(
                    context, 'Revenus', '12 000 FCFA', Colors.green, Icons.payments),
                _buildStat(context, 'En cours', '5', Colors.blue, Icons.pending),
                _buildStat(context, 'Nouveaux', '8', Colors.purple, Icons.person_add),
              ],
            ),

            const SizedBox(height: 24),

            // Actions rapides
            Text(
              'Actions rapides',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildAction(
                    context,
                    Icons.inventory_2_outlined,
                    'Gérer les articles',
                    'Valider, modifier, inspecter',
                    colorScheme.primary,
                  ),
                  _buildAction(
                    context,
                    Icons.people_outline,
                    'Gérer les utilisateurs',
                    'Historique, sanctions',
                    Colors.blue,
                  ),
                  _buildAction(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Gestion financière',
                    'Avoirs, remboursements',
                    Colors.green,
                  ),
                  _buildAction(
                    context,
                    Icons.warning_amber_outlined,
                    'Gérer les litiges',
                    'Historique des conflits',
                    Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Commandes en attente
            Text(
              'Commandes en attente',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            _buildCommande(
                context, 'Nike Air Max 270', 'Dépôt attendu', colorScheme.primary),
            _buildCommande(
                context, 'Robe longue bleue', 'Inspection en cours', Colors.blue),
            _buildCommande(
                context, 'Sac à main', 'Disponible — non récupéré', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
      BuildContext context, String label, String value, Color color, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
                color: isDark ? colorScheme.onSurfaceVariant : Colors.grey,
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12,
              color: isDark ? colorScheme.onSurfaceVariant : Colors.grey)),
      trailing: Icon(Icons.chevron_right,
          color: isDark ? colorScheme.onSurfaceVariant : Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildCommande(BuildContext context, String titre, String statut, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titre,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statut,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
