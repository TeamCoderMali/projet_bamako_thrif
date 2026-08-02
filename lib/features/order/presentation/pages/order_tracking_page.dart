// ─── Bamako Thrift — Order Tracking Page ────────────────────────────────────
// Suivi de commande en direct depuis Firestore (statut, délai J+7 réel)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

// ── Ordre exact du parcours (aligné avec le back-office) ────────────────────
const List<String> _stepsOrder = [
  'pending',
  'deposited',
  'processing',
  'ready_pickup',
  'completed',
];

const Map<String, Map<String, String>> _stepLabels = {
  'pending': {'title': 'Vendu', 'subtitle': 'Paiement reçu'},
  'deposited': {'title': 'Dépôt vendeur', 'subtitle': 'Reçu au point relais'},
  'processing': {
    'title': 'Inspection',
    'subtitle': 'Vérification, lavage, repassage'
  },
  'ready_pickup': {'title': 'Disponible', 'subtitle': 'Prêt à être récupéré'},
  'completed': {'title': 'Récupéré', 'subtitle': 'Commande finalisée'},
};

class OrderTrackingPage extends StatelessWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  String _fmtPrice(dynamic p) {
    final price = (p is num) ? p.toDouble() : 0.0;
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA';
  }

  String _fmtDate(DateTime d) {
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${d.day} ${mois[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.push(RouteNames.orders),
        ),
        title: const Text(
          'Suivi de commande',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('order')
            .doc(orderId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
            );
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Commande introuvable'));
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'pending';
          final productTitle = data['productTitle'] as String? ?? 'Article';
          final productImageUrl = data['productImageUrl'] as String?;
          final totalAmount = data['totalAmount'];
          final readyPickupAt = data['readyPickupAt'] as Timestamp?;

          final isCancelled = status == 'cancelled';
          final currentIndex = _stepsOrder.indexOf(status);

          // ── Calcul du vrai délai J+7 (frais de garde) ─────────────────────
          DateTime? deadline;
          bool overdue = false;
          if (status == 'ready_pickup' && readyPickupAt != null) {
            deadline = readyPickupAt.toDate().add(const Duration(days: 7));
            overdue = DateTime.now().isAfter(deadline);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Article
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4EE),
                          borderRadius: BorderRadius.circular(12),
                          image: productImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(productImageUrl),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: productImageUrl == null
                            ? const Icon(Icons.checkroom,
                                color: Color(0xFF6B7F4D))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productTitle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _fmtPrice(totalAmount),
                              style: const TextStyle(
                                color: Color(0xFF6B7F4D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isCancelled
                                  ? 'Annulée'
                                  : _stepLabels[status]?['title'] ?? status,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Étapes de votre commande',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 16),

                if (isCancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Cette commande a été annulée.',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else
                  // ── Timeline dynamique, basée sur le vrai statut ──────────
                  ..._stepsOrder.asMap().entries.map((entry) {
                    final index = entry.key;
                    final key = entry.value;
                    final label = _stepLabels[key]!;
                    final done = currentIndex >= 0 && index <= currentIndex;
                    final active = index == currentIndex;
                    return _buildStep(
                      label['title']!,
                      active ? 'En cours...' : label['subtitle']!,
                      done,
                      active,
                      isLast: key == 'completed',
                    );
                  }),

                const SizedBox(height: 24),

                // ── Alerte J+7, avec vraie date calculée ────────────────────
                if (status == 'ready_pickup' && deadline != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: overdue
                          ? Colors.red.shade50
                          : const Color(0xFFF7F4EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: overdue
                            ? Colors.red.shade200
                            : const Color(0xFFD4E4B8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          overdue ? Icons.warning_amber_rounded : Icons.access_time,
                          color: overdue ? Colors.red : const Color(0xFF6B7F4D),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            overdue
                                ? 'Délai dépassé — des frais de garde s\'appliquent (100 à 200 FCFA/jour) jusqu\'au retrait.'
                                : 'Action requise — Venez récupérer avant le ${_fmtDate(deadline)}\n(J+7 — frais de garde après)',
                            style: TextStyle(
                              color: overdue
                                  ? Colors.red.shade700
                                  : const Color(0xFF6B7F4D),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(String title, String subtitle, bool done, bool active,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done
                    ? Colors.orange
                    : active
                        ? const Color(0xFFD4E4B8)
                        : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check : Icons.circle,
                color: Colors.white,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: done ? Colors.orange : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: done ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
