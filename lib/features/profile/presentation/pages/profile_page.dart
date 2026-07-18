import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(RouteNames.login);
        }
      },
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header profil ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF6B7F4D),
                              backgroundImage: user?.avatarUrl != null
                                  ? CachedNetworkImageProvider(user!.avatarUrl!)
                                  : null,
                              child: user?.avatarUrl == null
                                  ? Text(
                                      user?.initials ?? '?',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            if (user?.isEmailVerified == true)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.fullName ?? 'Utilisateur',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            user.bio!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Rôle badge
                        if (user != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isSeller
                                  ? const Color(0xFF6B7F4D).withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: user.isSeller
                                    ? const Color(0xFF6B7F4D)
                                    : Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              user.isSeller ? '🏪 Vendeur' : '🛍️ Acheteur',
                              style: TextStyle(
                                color: user.isSeller
                                    ? const Color(0xFF6B7F4D)
                                    : Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(
                                '${user?.totalListings ?? 0}', 'Annonces'),
                            _buildStat('${user?.totalSales ?? 0}', 'Ventes'),
                            _buildStat(
                              user != null && user.reviewCount > 0
                                  ? '${user.rating.toStringAsFixed(1)}★'
                                  : '—',
                              'Note',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Bouton modifier profil
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go('${RouteNames.profile}/edit'),
                          icon: const Icon(Icons.edit_outlined,
                              size: 16, color: Color(0xFF6B7F4D)),
                          label: const Text(
                            'Modifier le profil',
                            style: TextStyle(color: Color(0xFF6B7F4D)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6B7F4D)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Portefeuille ──────────────────────────────────────────
                  GestureDetector(
                    onTap: () => context.go(RouteNames.wallet),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7F4D),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mon Portefeuille',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                'Voir le solde →',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.account_balance_wallet,
                              color: Colors.white70),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Menu ──────────────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildMenuItem(Icons.list_alt, 'Mes annonces',
                            () => context.go(RouteNames.myListings)),
                        _buildMenuItem(Icons.favorite_border, 'Mes favoris',
                            () => context.go(RouteNames.favorites)),
                        _buildMenuItem(
                          Icons.shopping_bag_outlined,
                          'Mes commandes',
                          () => context.go(RouteNames.orders),
                        ),
                        _buildMenuItem(
                          Icons.notifications_outlined,
                          'Notifications',
                          () => context.go(RouteNames.notifications),
                        ),
                        _buildMenuItem(
                          Icons.settings_outlined,
                          'Paramètres',
                          () => context.go(RouteNames.settings),
                        ),
                        _buildMenuItem(Icons.help_outline, 'Aide & Support',
                            () => context.go(RouteNames.support)),
                        const Divider(height: 1),
                        _buildMenuItem(
                          Icons.logout,
                          'Se déconnecter',
                          () => _confirmSignOut(context),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 4,
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go(RouteNames.home);
                  break;
                case 1:
                  context.go(RouteNames.search);
                  break;
                case 2:
                  context.go(RouteNames.publish);
                  break;
                case 3:
                  context.go(RouteNames.messages);
                  break;
                case 4:
                  context.go(RouteNames.profile);
                  break;
              }
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF6B7F4D),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), label: 'Accueil'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.search), label: 'Chercher'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline), label: 'Publier'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.message_outlined), label: 'Messages'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Voulez-vous vraiment quitter votre compte ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
            },
            child: const Text('Se déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2B2B)),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(color: color, fontSize: 14)),
      trailing: Icon(Icons.chevron_right,
          color: color == Colors.red ? Colors.red.shade200 : Colors.grey,
          size: 20),
      onTap: onTap,
    );
  }
}
