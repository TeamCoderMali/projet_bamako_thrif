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
            backgroundColor: Theme.of(context).colorScheme.primary,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.settings),
        ),
        title: Text(
          'Vendeurs bloqués',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<({String sellerId, String? sellerName})>>(
        stream: _blockedUsers.watchBlocked(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary),
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
                    Icon(Icons.block,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun vendeur bloqué.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.block,
                        color: Theme.of(context).colorScheme.onPrimary, size: 18),
                  ),
                  title: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14)),
                  trailing: TextButton(
                    onPressed: () => _unblock(entry.sellerId, label),
                    child: Text('Débloquer',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
