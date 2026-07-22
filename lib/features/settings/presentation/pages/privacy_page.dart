import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.push(RouteNames.settings),
        ),
        title: const Text(
          'Confidentialité',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Politique de confidentialité',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Collecte des données',
              'Bamako Thrift collecte uniquement les données nécessaires au bon fonctionnement de la plateforme : nom, téléphone, email et historique des transactions.',
            ),
            _buildSection(
              'Utilisation des données',
              'Vos données sont utilisées pour gérer votre compte, sécuriser vos transactions et améliorer votre expérience sur la plateforme.',
            ),
            _buildSection(
              'Sécurité',
              'Toutes vos données sont chiffrées et stockées de manière sécurisée. Nous ne partageons jamais vos informations avec des tiers.',
            ),
            _buildSection(
              'Paiements',
              'Les paiements sont traités via Orange Money et Moov Money. Les fonds sont bloqués jusqu\'à validation de la transaction par notre équipe.',
            ),
            _buildSection(
              'Vos droits',
              'Vous pouvez demander la suppression de votre compte et de vos données à tout moment en contactant notre support.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Dernière mise à jour : Juillet 2026',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String titre, String contenu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            contenu,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }
}
