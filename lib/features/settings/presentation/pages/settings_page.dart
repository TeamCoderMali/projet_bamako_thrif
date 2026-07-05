import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go(RouteNames.profile),
        ),
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Compte
          const Text(
            'Compte',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildItem(
                  Icons.person_outline,
                  'Modifier le profil',
                  () => context.go(RouteNames.editProfile),
                ),
                _buildItem(
                  Icons.lock_outline,
                  'Changer le mot de passe',
                  () {},
                ),
                _buildItem(
                  Icons.privacy_tip_outlined,
                  'Confidentialité',
                  () => context.go(RouteNames.privacy),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Préférences
          const Text(
            'Préférences',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  value: _notifications,
                  activeColor: const Color(0xFF6B7F4D),
                  onChanged: (val) => setState(() => _notifications = val),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Mode sombre'),
                  value: _darkMode,
                  activeColor: const Color(0xFF6B7F4D),
                  onChanged: (val) => setState(() => _darkMode = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // À propos
          const Text(
            'À propos',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildItem(
                  Icons.info_outline,
                  'À propos de l\'app',
                  () => context.go(RouteNames.about),
                ),
                _buildItem(
                  Icons.help_outline,
                  'Aide & Support',
                  () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Déconnexion
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => context.go(RouteNames.login),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Se déconnecter',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
