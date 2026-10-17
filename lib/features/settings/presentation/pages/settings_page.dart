// ─── Bamako Thrift — Settings Page ───────────────────────────────────────────
import 'package:firebase_auth/firebase_auth.dart';
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
    final themeMode = context.watch<ThemeCubit>().state;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.profile),
        ),
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _sectionLabel(context, 'Compte'),
          _card(context, [
            _item(context, Icons.person_outline, 'Modifier le profil',
                () => context.push(RouteNames.editProfile)),
            _item(context, Icons.lock_outline, 'Changer le mot de passe',
                () => context.push(RouteNames.changePassword)),
            _item(context, Icons.privacy_tip_outlined, 'Confidentialité',
                () => context.push(RouteNames.privacy)),
            _item(context, Icons.block, 'Vendeurs bloqués',
                () => context.push(RouteNames.blockedSellers)),
            _item(context, Icons.description_outlined, 'Conditions d\'utilisation',
                () => context.push(RouteNames.termsOfService)),
          ]),
          const SizedBox(height: 22),
          _sectionLabel(context, 'Préférences'),
          _card(context, [
            SwitchListTile(
              secondary: Icon(Icons.notifications_outlined,
                  color: Theme.of(context).colorScheme.primary),
              title: Text('Notifications',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text('Push et alertes en temps réel',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              value: _notifications,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) => setState(() => _notifications = val),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: Icon(
                switch (themeMode) {
                  ThemeMode.dark => Icons.dark_mode,
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.system => Icons.brightness_auto_outlined,
                },
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('Apparence',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text(_themeModeLabel(themeMode),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.chevron_right,
                  size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
              onTap: () => _showThemeModeSheet(context, themeMode),
            ),
          ]),
          const SizedBox(height: 22),
          _sectionLabel(context, 'À propos'),
          _card(context, [
            _item(context, Icons.info_outline, 'À propos de l\'app',
                () => context.push(RouteNames.about)),
            _item(context, Icons.help_outline, 'Aide & Support',
                () => context.push(RouteNames.support)),
            _item(context, Icons.star_outline, 'Noter l\'application', () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      'Disponible après publication sur le Play Store'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }),
          ]),
          const SizedBox(height: 22),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDeleteAccount(context),
              icon: const Icon(Icons.delete_forever_outlined,
                  color: Colors.red, size: 18),
              label: const Text(
                'Supprimer mon compte',
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

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );

  // Carte volontairement plus claire que le fond de l'écran (deux niveaux de
  // gris/beige, motif déjà utilisé dans le reste de l'app) : en clair, le
  // blanc pur reste tel quel (ne correspond à aucun token exact de la
  // palette claire, qui est en beige) ; en sombre, une surface du thème.
  Widget _card(BuildContext context, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Colors.white,
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

  Widget _item(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      title: Text(title,
          style: TextStyle(
              fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
      trailing: Icon(Icons.chevron_right,
          size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Clair',
        ThemeMode.dark => 'Sombre',
        ThemeMode.system => 'Automatique (système)',
      };

  void _showThemeModeSheet(BuildContext context, ThemeMode current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Widget option(ThemeMode mode, IconData icon) {
          return ListTile(
            leading: Icon(icon, color: Theme.of(sheetContext).colorScheme.primary),
            title: Text(_themeModeLabel(mode)),
            trailing: current == mode
                ? Icon(Icons.check, color: Theme.of(sheetContext).colorScheme.primary)
                : null,
            onTap: () {
              context.read<ThemeCubit>().setMode(mode);
              Navigator.pop(sheetContext);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Apparence',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              option(ThemeMode.light, Icons.light_mode_outlined),
              option(ThemeMode.dark, Icons.dark_mode),
              option(ThemeMode.system, Icons.brightness_auto_outlined),
              const SizedBox(height: 8),
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
        content: const Text('Veux-tu vraiment quitter ton compte ?'),
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

  // ── Suppression de compte (étape 1 : avertissement) ─────────────────────
  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ton compte ?'),
        content: const Text(
          'Cette action est définitive : tu seras déconnecté et ne pourras '
          'plus te reconnecter avec ce compte.\n\n'
          'Tes articles en ligne seront masqués. Tes commandes et messages '
          'déjà échangés restent visibles pour les autres, mais ton nom et '
          'ta photo y apparaîtront comme "Utilisateur supprimé".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteAccountStep2(context);
            },
            child: const Text('Continuer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Suppression de compte (étape 2 : reconfirmation) ─────────────────────
  // Mot de passe pour un compte email, Google pour un compte Google — le
  // seul autre provider que l'app gère (voir AuthRepositoryImpl.deleteAccount).
  void _confirmDeleteAccountStep2(BuildContext context) {
    final hasPasswordProvider = FirebaseAuth.instance.currentUser?.providerData
            .any((p) => p.providerId == 'password') ??
        true;

    if (!hasPasswordProvider) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirmer avec Google'),
          content: const Text(
            'Reconnecte-toi avec Google pour confirmer la suppression définitive de ton compte.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(ctx);
                _performAccountDeletion(context);
              },
              child: const Text('Confirmer avec Google',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final passwordCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirme ton mot de passe'),
        content: TextField(
          controller: passwordCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Mot de passe'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final password = passwordCtrl.text;
              Navigator.pop(ctx);
              _performAccountDeletion(context, password: password);
            },
            child: const Text('Supprimer définitivement',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Suppression de compte (exécution) ─────────────────────────────────────
  Future<void> _performAccountDeletion(BuildContext context,
      {String? password}) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Center(
        child: CircularProgressIndicator(
            color: Theme.of(dialogCtx).colorScheme.primary),
      ),
    );

    final cubit = context.read<AuthCubit>();
    final success = await cubit.deleteAccount(password: password);

    if (!context.mounted) return;
    Navigator.pop(context); // ferme le loader

    if (success) {
      context.go(RouteNames.login);
    } else {
      final state = cubit.state;
      final message =
          state is AuthError ? state.message : 'La suppression a échoué.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
