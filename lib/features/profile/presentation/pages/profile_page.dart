import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/shared/widgets/bottom_navigation.dart';
import 'package:bamako_thrift/shared/widgets/vendeur_pro_badge.dart';

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

        return TabRootBackHandler(
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Header : avatar + nom centrés ───────────────────
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6B7F4D), Color(0xFF8FA85A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Stack(
                        children: [
                          // Bouton modifier en haut à droite
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  context.push('${RouteNames.profile}/edit'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          // Avatar + nom + email + badge, centrés
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 2,
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
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  user?.fullName ?? 'Utilisateur',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (user?.isVendeurPro == true) ...[
                                  const SizedBox(height: 8),
                                  const VendeurProBadge(),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // ── Stats : 3 cartes séparées, live depuis Firestore ──
                          StreamBuilder<DocumentSnapshot>(
                            stream: user != null
                                ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.id)
                                    .snapshots()
                                : null,
                            builder: (context, snap) {
                              final data =
                                  snap.data?.data() as Map<String, dynamic>?;
                              final totalListings =
                                  data?['totalListings'] as int? ??
                                      user?.totalListings ??
                                      0;
                              final totalSales = data?['totalSales'] as int? ??
                                  user?.totalSales ??
                                  0;
                              final rating =
                                  (data?['rating'] as num?)?.toDouble() ??
                                      user?.rating ??
                                      0;
                              final reviewCount =
                                  data?['reviewCount'] as int? ??
                                      user?.reviewCount ??
                                      0;

                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      '$totalListings',
                                      'Annonces',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      '$totalSales',
                                      'Achats',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      reviewCount > 0
                                          ? '${rating.toStringAsFixed(1)}★'
                                          : '—',
                                      'Note',
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // ── Portefeuille ──────────────────────────────
                          GestureDetector(
                            onTap: () => context.push(RouteNames.wallet),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white70,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Dashboard Admin ───────────────────────────
                          if (user != null && user.isAdmin) ...[
                            _buildMenuSection(context, [
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
                          _buildMenuSection(context, [
                            _buildMenuItem(
                              context,
                              icon: Icons.list_alt,
                              iconBg: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              iconColor: Theme.of(context).colorScheme.primary,
                              title: 'Mes annonces',
                              onTap: () => context.push(RouteNames.myListings),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.local_offer_outlined,
                              iconBg: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              iconColor: Theme.of(context).colorScheme.primary,
                              title: 'Mes offres',
                              onTap: () => context.push(RouteNames.myOffers),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.favorite_border,
                              iconBg: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              iconColor: Theme.of(context).colorScheme.primary,
                              title: 'Mes favoris',
                              onTap: () => context.push(RouteNames.favorites),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.shopping_bag_outlined,
                              iconBg: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              iconColor: Theme.of(context).colorScheme.primary,
                              title: 'Mes commandes',
                              onTap: () => context.push(RouteNames.orders),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.credit_card_outlined,
                              iconBg: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              iconColor: Theme.of(context).colorScheme.primary,
                              title: 'Paiements',
                              onTap: () => context.push(RouteNames.payment),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.notifications_outlined,
                              iconBg: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              iconColor: Theme.of(context).colorScheme.primary,
                              title: 'Notifications',
                              onTap: () =>
                                  context.push(RouteNames.notifications),
                              isLast: true,
                            ),
                          ]),

                          const SizedBox(height: 12),

                          // ── Menu secondaire ───────────────────────────
                          _buildMenuSection(context, [
                            _buildMenuItem(
                              context,
                              icon: Icons.settings_outlined,
                              iconBg: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.1),
                              iconColor:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              title: 'Paramètres',
                              onTap: () => context.push(RouteNames.settings),
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.help_outline,
                              iconBg: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.1),
                              iconColor:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              title: 'Aide & Support',
                              onTap: () => context.push(RouteNames.support),
                              isLast: true,
                            ),
                          ]),

                          const SizedBox(height: 12),

                          // ── Déconnexion ───────────────────────────────
                          _buildMenuSection(context, [
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
            bottomNavigationBar: const AppBottomNav(currentIndex: 4),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
    Color? titleColor,
    bool isLast = false,
  }) {
    final defaultTitleColor = Theme.of(context).colorScheme.onSurface;
    final resolvedTitleColor = titleColor ?? defaultTitleColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1)),
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
                  color: resolvedTitleColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: titleColor == null
                  ? Theme.of(context).colorScheme.outlineVariant
                  : resolvedTitleColor.withOpacity(0.4),
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
        content: const Text('Veux-tu vraiment quitter ton compte ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
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
