import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
          'Historique',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildCommande(
            'Nike Air Max 270',
            '25 000 FCFA',
            'Récupéré',
            Colors.green,
            Icons.check_circle,
          ),
          _buildCommande(
            'Robe longue bleue',
            '5 000 FCFA',
            'En cours',
            const Color(0xFF6B7F4D),
            Icons.access_time,
          ),
          _buildCommande(
            'Sac à main',
            '15 000 FCFA',
            'Disponible',
            Colors.blue,
            Icons.store,
          ),
        ],
      ),
    );
  }

  Widget _buildCommande(
    String titre,
    String prix,
    String statut,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.checkroom, color: const Color(0xFF6B7F4D)),
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
                Text(
                  prix,
                  style: const TextStyle(
                    color: const Color(0xFF6B7F4D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  statut,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
