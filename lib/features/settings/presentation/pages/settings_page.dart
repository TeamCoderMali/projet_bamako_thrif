// ─── Bamako Thrift — Settings Page ───────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/theme/theme_cubit.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.profile),
        ),
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // ── Compte ──────────────────────────────────────────────────────────
          _sectionLabel('Compte'),
          _card([
            _item(context, Icons.person_outline, 'Modifier le profil',
                () => context.go(RouteNames.editProfile)),
            _item(context, Icons.lock_outline, 'Changer le mot de passe', () {}),
            _item(context, Icons.privacy_tip_outlined, 'Confidentialité',
                () => context.go(RouteNames.privacy)),
          ]),

          const SizedBox(height: 22),

          // ── Préférences ───────────────────────────────────────────────────
          _sectionLabel('Préférences'),
          _card([
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              subtitle: const Text('Push et alertes en temps réel'),
              value: _notifications,
              activeColor: const Color(0xFF6B7F4D),
              onChanged: (val) => setState(() => _notifications = val),
            ),
            const Divider(height: 1, indent: 56),
            SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode_outlined,
              ),
              title: const Text('Mode sombre'),
              subtitle: Text(isDark ? 'Activé' : 'Désactivé'),
              value: isDark,
              activeColor: const Color(0xFF6B7F4D),
              onChanged: (_) => context.read<ThemeCubit>().toggle(),
            ),
          ]),

          const SizedBox(height: 22),

          // ── À propos ──────────────────────────────────────────────────────
          _sectionLabel('À propos'),
          _card([
            _item(context, Icons.info_outline, 'À propos de l\'app',
                () => context.go(RouteNames.about)),
            _item(context, Icons.help_outline, 'Aide & Support', () {}),
            _item(context, Icons.star_outline, 'Noter l\'application', () {}),
          ]),

          const SizedBox(height: 22),

          // ── Déconnexion ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout, color: Colors.red, size: 18),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
              color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      );

  Widget _item(BuildContext context, IconData icon, String title,
      VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B7F4D), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
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
            child: const Text('Déconnexion',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
