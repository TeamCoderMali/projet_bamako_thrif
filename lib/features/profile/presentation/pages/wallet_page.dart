// ─── Bamako Thrift — Wallet Page ─────────────────────────────────────────────
// Portefeuille complet : solde live (crédits expirés à 3 mois exclus),
// gains/dépenses historiques, et historique des transactions.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  String _fmt(dynamic amount) {
    final v = (amount is num) ? amount.toDouble() : 0.0;
    return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA';
  }

  String _fmtDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = (ts as Timestamp).toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B7F4D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.profile),
        ),
        title: const Text(
          'Mon Portefeuille',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Connectez-vous'))
          : StreamBuilder<QuerySnapshot>(
              // Toutes les transactions pilotent l'affichage : le solde
              // disponible est recalculé en direct en excluant les crédits
              // dont la date d'expiration (3 mois) est dépassée.
              stream: FirebaseFirestore.instance
                  .collection('wallet')
                  .doc(uid)
                  .collection('transactions')
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, txSnap) {
                if (txSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
                  );
                }

                final txs = txSnap.data?.docs ?? [];
                final now = DateTime.now();

                double availableBalance = 0;
                double totalEarned = 0;
                double totalSpent = 0;
                DateTime? nextExpiry;

                for (final doc in txs) {
                  final tx = doc.data() as Map<String, dynamic>;
                  final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
                  final isCredit = tx['type'] == 'credit';
                  final expiresAt = tx['expiresAt'] as Timestamp?;
                  final isExpired =
                      expiresAt != null && expiresAt.toDate().isBefore(now);

                  if (isCredit) {
                    totalEarned += amount; // historique, jamais affecté
                    if (!isExpired) {
                      availableBalance += amount;
                      if (expiresAt != null &&
                          (nextExpiry == null ||
                              expiresAt.toDate().isBefore(nextExpiry))) {
                        nextExpiry = expiresAt.toDate();
                      }
                    }
                  } else {
                    totalSpent += amount;
                    availableBalance -= amount;
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Carte solde ────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B7F4D), Color(0xFF4F6035)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B7F4D).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Solde disponible',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'FCFA',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _fmt(availableBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _WalletStat(
                                    label: 'Gains totaux',
                                    value: _fmt(totalEarned),
                                    icon: Icons.trending_up),
                                Container(
                                    height: 32,
                                    width: 1,
                                    color: Colors.white30),
                                _WalletStat(
                                    label: 'Dépenses totales',
                                    value: _fmt(totalSpent),
                                    icon: Icons.trending_down),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Info escrow ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                color: Color(0xFF6B7F4D), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Les gains des ventes sont crédités après confirmation de réception par l\'acheteur.',
                                style: TextStyle(
                                    color: Color(0xFF5A6B3E), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Alerte expiration prochaine ─────────────────────────
                      if (nextExpiry != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF0D999)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: Color(0xFFB8860B), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Une partie de votre solde expire le ${_fmtDate(Timestamp.fromDate(nextExpiry!))} si non utilisée (validité 3 mois).',
                                  style: const TextStyle(
                                      color: Color(0xFF8A6A1A), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Historique ─────────────────────────────────────────
                      const Text(
                        'Historique',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      if (txs.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 56, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                const Text('Aucune transaction',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: txs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final tx = txs[i].data() as Map<String, dynamic>;
                            final isCredit = tx['type'] == 'credit';
                            final amount = tx['amount'] ?? 0;
                            final label = tx['label'] as String? ?? '—';
                            final date = _fmtDate(tx['createdAt']);
                            final expiresAt = tx['expiresAt'] as Timestamp?;
                            final isExpired = isCredit &&
                                expiresAt != null &&
                                expiresAt.toDate().isBefore(now);

                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isExpired
                                      ? Colors.grey.shade100
                                      : isCredit
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: isExpired
                                      ? Colors.grey
                                      : isCredit
                                          ? Colors.green
                                          : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(label,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isExpired ? Colors.grey : null)),
                              subtitle: Text(
                                isExpired ? '$date · Expiré' : date,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isExpired
                                      ? Colors.orange.shade700
                                      : Colors.grey,
                                ),
                              ),
                              trailing: Text(
                                '${isCredit ? '+' : '-'}${_fmt(amount)}',
                                style: TextStyle(
                                  color: isExpired
                                      ? Colors.grey
                                      : isCredit
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: isExpired
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _WalletStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _WalletStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      );
}
