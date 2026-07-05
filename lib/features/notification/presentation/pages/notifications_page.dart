import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go(RouteNames.home),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNotif(
            Icons.check_circle,
            Colors.green,
            'Article disponible',
            'Votre Nike Air Max 270 est prêt à être récupéré.',
            'Il y a 2h',
          ),
          _buildNotif(
            Icons.access_time,
            Colors.orange,
            'Rappel dépôt',
            'Vous avez 24h pour déposer votre article vendu.',
            'Il y a 5h',
          ),
          _buildNotif(
            Icons.message,
            Colors.blue,
            'Nouveau message',
            'Baba Traoré vous a envoyé un message.',
            'Hier',
          ),
          _buildNotif(
            Icons.sell,
            Colors.purple,
            'Article vendu !',
            'Votre Robe longue bleue a été achetée.',
            'Il y a 2 jours',
          ),
          _buildNotif(
            Icons.warning_amber,
            Colors.red,
            'Frais de garde',
            'Des frais de garde s\'appliquent à partir d\'aujourd\'hui.',
            'Il y a 3 jours',
          ),
        ],
      ),
    );
  }

  Widget _buildNotif(
    IconData icon,
    Color color,
    String titre,
    String message,
    String temps,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  temps,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}