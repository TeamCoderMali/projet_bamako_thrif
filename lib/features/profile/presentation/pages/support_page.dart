import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2B2B2B)),
          onPressed: () => context.go(RouteNames.profile),
        ),
        title: const Text(
          'Aide & Support',
          style: TextStyle(
            color: Color(0xFF2B2B2B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact
            const Text(
              'Nous contacter',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              Icons.email_outlined,
              'Email',
              'support@danaya.ml',
            ),
            _buildContactItem(
              Icons.phone_outlined,
              'WhatsApp',
              '+223 XX XX XX XX',
            ),
            const SizedBox(height: 24),

            // FAQ
            const Text(
              'Questions fréquentes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),
            _buildFaq(
              'Comment vendre un article ?',
              'Cliquez sur "Publier" en bas de l\'écran, ajoutez des photos, remplissez les informations et publiez gratuitement.',
            ),
            _buildFaq(
              'Comment fonctionne le paiement ?',
              'L\'argent est bloqué jusqu\'à validation par notre équipe. Vous pouvez payer via Orange Money, Moov Money ou votre avoir.',
            ),
            _buildFaq(
              'Qu\'est-ce que le badge Vérifié ?',
              'Le badge Vérifié signifie que notre équipe a inspecté, lavé et repassé le vêtement avant remise à l\'acheteur.',
            ),
            _buildFaq(
              'Que faire si mon colis ne correspond pas ?',
              'Vous pouvez refuser le vêtement et être remboursé, ou accepter avec une remise en état à la charge du vendeur.',
            ),
            _buildFaq(
              'Combien de temps pour récupérer mon article ?',
              'Vous avez 7 jours après notification pour récupérer votre article. Des frais de garde s\'appliquent à partir du 8e jour.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7F4D)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2B2B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaq(String question, String reponse) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2B2B2B),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              reponse,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
