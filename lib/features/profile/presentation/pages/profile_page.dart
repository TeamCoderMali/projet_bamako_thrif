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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) context.go(RouteNames.home);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F4EE),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Header vert gradient ────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6B7F4D), Color(0xFF8FA85A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 3,
                              ),
                            ),
                            child: user?.avatarUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: user!.avatarUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      user?.initials ?? '?',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.fullName ?? 'Utilisateur',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              user?.isSeller == true
                                  ? '🏪 Vendeur'
                                  : '🛍️ Acheteur',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _buildStat(
                                    '${user?.totalListings ?? 0}', 'Annonces'),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withOpacity(0.2)),
                                _buildStat(
                                    '${user?.totalSales ?? 0}', 'Ventes'),
                                Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withOpacity(0.2)),
                                _buildStat(
                                  user != null && user.reviewCount > 0
                                      ? '${user.rating.toStringAsFixed(1)}★'
                                      : '—',
                                  'Note',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () =>
                                context.push('${RouteNames.profile}/edit'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_outlined,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Modifier le profil',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // ── Portefeuille ──────────────────────────────
                          GestureDetector(
                            onTap: () => context.push(RouteNames.wallet),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFC3653D),
                                    Color(0xFFE08A5E)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC3653D)
                                        .withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mon Portefeuille',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(height: 4),
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
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white70,
                                    size: 32,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Dashboard Admin ───────────────────────────
                          if (user != null && user.isAdmin) ...[
                            _buildMenuSection([
                              _buildMenuItem(
                                context,
                                icon: Icons.admin_panel_settings,
                                iconBg:
                                    const Color(0xFFC3653D).withOpacity(0.1),
                                iconColor: const Color(0xFFC3653D),
                                title: 'Dashboard Admin',
                                titleColor: const Color(0xFFC3653D),
                                onTap: () =>
                                    context.push(RouteNames.adminDashboard),
                              ),
                            ]),
                            const SizedBox(height: 12),
                          ],

                          // ── Menu principal ────────────────────────────
                          _buildMenuSection([
                            _buildMenuItem(
                              context,
                              icon: Icons.list_alt,
                              iconBg: const Color(0xFF6B7F4D).withOpacity(0.1),
                              iconColor: const Color(0xFF6B7F4D),
                              title: 'Mes annonces',
                              onTap: () => context.push(RouteNames.myListings),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.favorite_border,
                              iconBg: const Color(0xFF6B7F4D).withOpacity(0.1),
                              iconColor: const Color(0xFF6B7F4D),
                              title: 'Mes favoris',
                              onTap: () => context.push(RouteNames.favorites),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.shopping_bag_outlined,
                              iconBg: const Color(0xFF6B7F4D).withOpacity(0.1),
                              iconColor: const Color(0xFF6B7F4D),
                              title: 'Mes commandes',
                              onTap: () => context.push(RouteNames.orders),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.credit_card_outlined,
                              iconBg: const Color(0xFF6B7F4D).withOpacity(0.1),
                              iconColor: const Color(0xFF6B7F4D),
                              title: 'Paiements',
                              onTap: () => context.push(RouteNames.payment),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.notifications_outlined,
                              iconBg: const Color(0xFF6B7F4D).withOpacity(0.1),
                              iconColor: const Color(0xFF6B7F4D),
                              title: 'Notifications',
                              onTap: () =>
                                  context.push(RouteNames.notifications),
                              isLast: true,
                            ),
                          ]),

                          const SizedBox(height: 12),

                          // ── Menu secondaire ───────────────────────────
                          _buildMenuSection([
                            _buildMenuItem(
                              context,
                              icon: Icons.settings_outlined,
                              iconBg: Colors.grey.withOpacity(0.1),
                              iconColor: Colors.grey,
                              title: 'Paramètres',
                              onTap: () => context.push(RouteNames.settings),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.help_outline,
                              iconBg: Colors.grey.withOpacity(0.1),
                              iconColor: Colors.grey,
                              title: 'Aide & Support',
                              onTap: () => context.push(RouteNames.support),
                              isLast: true,
                            ),
                          ]),

                          const SizedBox(height: 12),

                          // ── Déconnexion ───────────────────────────────
                          _buildMenuSection([
                            _buildMenuItem(
                              context,
                              icon: Icons.logout,
                              iconBg: Colors.red.withOpacity(0.1),
                              iconColor: Colors.red,
                              title: 'Se déconnecter',
                              titleColor: Colors.red,
                              onTap: () => _confirmSignOut(context),
                              isLast: true,
                            ),
                          ]),

                          const SizedBox(height: 20),
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
              backgroundColor: Colors.white,
              elevation: 8,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Accueil'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.search), label: 'Chercher'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle_outline),
                    activeIcon: Icon(Icons.add_circle),
                    label: 'Publier'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.message_outlined),
                    activeIcon: Icon(Icons.message),
                    label: 'Messages'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profil'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color titleColor = const Color(0xFF2B2B2B),
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: titleColor == const Color(0xFF2B2B2B)
                  ? Colors.grey.shade300
                  : titleColor.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
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
}
