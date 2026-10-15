// ─── Bamako Thrift — Vendeurs bloqués ──────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/dependency_injection/injection.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/core/services/blocked_users_service.dart';

class BlockedSellersPage extends StatefulWidget {
  const BlockedSellersPage({super.key});

  @override
  State<BlockedSellersPage> createState() => _BlockedSellersPageState();
}

class _BlockedSellersPageState extends State<BlockedSellersPage> {
  final _blockedUsers = sl<BlockedUsersService>();

  Future<void> _unblock(String sellerId, String label) async {
    try {
      await _blockedUsers.unblock(sellerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label a été débloqué.'),
            backgroundColor: const Color(0xFF6B7F4D),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le déblocage a échoué. Réessaie.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B7F4D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.settings),
        ),
        title: const Text(
          'Vendeurs bloqués',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<({String sellerId, String? sellerName})>>(
        stream: _blockedUsers.watchBlocked(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
            );
          }
          final blocked = snapshot.data!;
          if (blocked.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun vendeur bloqué.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: blocked.length,
            itemBuilder: (context, i) {
              final entry = blocked[i];
              final label = (entry.sellerName?.isNotEmpty ?? false)
                  ? entry.sellerName!
                  : 'Vendeur';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF6B7F4D),
                    child: Icon(Icons.block, color: Colors.white, size: 18),
                  ),
                  title: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14)),
                  trailing: TextButton(
                    onPressed: () => _unblock(entry.sellerId, label),
                    child: const Text('Débloquer',
                        style: TextStyle(color: Color(0xFF6B7F4D))),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
