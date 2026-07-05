import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header profil
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF6B7F4D),
                      child: Text(
                        'AK',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Awa Kane',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('12', 'Annonces'),
                        _buildStat('8', 'Achats'),
                        _buildStat('4.8★', 'Note'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Portefeuille
              Container(
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
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '3 500 FCFA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Expire dans 68j',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Menu items
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildMenuItem(Icons.list_alt, 'Mes annonces', () {}),
                    _buildMenuItem(Icons.favorite_border, 'Mes favoris', () {}),
                    _buildMenuItem(
                        Icons.shopping_bag_outlined, 'Mes commandes', () {}),
                    _buildMenuItem(Icons.payment_outlined, 'Paiements', () {}),
                    _buildMenuItem(
                        Icons.notifications_outlined, 'Notifications', () {}),
                    _buildMenuItem(
                        Icons.settings_outlined, 'Paramètres', () {}),
                    _buildMenuItem(Icons.help_outline, 'Aide', () {}),
                    _buildMenuItem(
                      Icons.logout,
                      'Se déconnecter',
                      () => context.go(RouteNames.login),
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
              context.go(RouteNames.catalog);
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
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Chercher'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Publier'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
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
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.black87}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
