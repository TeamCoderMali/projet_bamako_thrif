import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildChat(context, '1', 'Baba Traoré', 'Nike Air Max 270 — 25 000 FCFA', 'Oui, toujours disponible !', true),
          _buildChat(context, '2', 'Awa Diallo', 'Robe longue — 5 000 FCFA', 'Je suis intéressée !', false),
          _buildChat(context, '3', 'Moussa Koné', 'Sac à main — 15 000 FCFA', 'On peut se voir ?', false),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0: context.go(RouteNames.home); break;
            case 1: context.go(RouteNames.catalog); break;
            case 2: context.go(RouteNames.publish); break;
            case 3: context.go(RouteNames.messages); break;
            case 4: context.go(RouteNames.profile); break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Chercher'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Publier'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildChat(
    BuildContext context,
    String id,
    String nom,
    String article,
    String dernierMessage,
    bool enLigne,
  ) {
    return GestureDetector(
      onTap: () => context.go('/messages/$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Text(
                    nom[0],
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (enLigne)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    article,
                    style: const TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                  Text(
                    dernierMessage,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}