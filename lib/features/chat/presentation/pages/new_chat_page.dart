// ─── Bamako Thrift — New Chat Page ───────────────────────────────────────────
// Permet de démarrer une conversation avec n'importe quel utilisateur
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bamako_thrift/features/auth/domain/entities/user_entity.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/chat/data/repositories/chat_repository_impl.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  bool _isStartingChat = false;

  late final ChatRepositoryImpl _chatRepo;
  late final String _currentUid;

  @override
  void initState() {
    super.initState();
    _chatRepo = ChatRepositoryImpl(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    _currentUid =
        context.read<AuthCubit>().currentUser?.id ?? '';
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Charger tous les utilisateurs depuis Firestore ───────────────────────
  Future<void> _loadUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('fullName')
          .limit(100)
          .get();

      final users = snapshot.docs
          .where((doc) => doc.id != _currentUid) // exclure soi-même
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filtered = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _allUsers
          : _allUsers.where((u) {
              final name = (u['fullName'] as String? ?? '').toLowerCase();
              final email = (u['email'] as String? ?? '').toLowerCase();
              return name.contains(q) || email.contains(q);
            }).toList();
    });
  }

  // ── Démarrer ou reprendre un chat ────────────────────────────────────────
  Future<void> _startChat(Map<String, dynamic> user) async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);

    try {
      final currentUser = context.read<AuthCubit>().currentUser!;
      final chatId = await _chatRepo.createOrGetChatWithUsers(
        participantIds: [_currentUid, user['id'] as String],
        participantNames: {
          _currentUid: currentUser.fullName,
          user['id'] as String: user['fullName'] as String? ?? 'Utilisateur',
        },
        participantAvatars: {
          _currentUid: currentUser.avatarUrl,
          user['id'] as String: user['avatarUrl'] as String?,
        },
      );
      if (mounted) context.go('/messages/$chatId');
    } catch (e) {
      if (mounted) {
        setState(() => _isStartingChat = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nouveau message',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF7F4EE),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _isStartingChat
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6B7F4D)),
                  SizedBox(height: 12),
                  Text('Ouverture de la conversation...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF6B7F4D)),
                )
              : _filtered.isEmpty
                  ? _buildEmpty()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Text(
                            '${_filtered.length} utilisateur${_filtered.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) =>
                                _UserTile(
                              user: _filtered[i],
                              onTap: () => _startChat(_filtered[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Aucun utilisateur disponible'
                : 'Aucun résultat pour "${_searchController.text}"',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Tuile utilisateur ────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  String get _initials {
    final name = (user['fullName'] as String? ?? 'U').trim().split(' ');
    if (name.length == 1) return name[0][0].toUpperCase();
    return '${name[0][0]}${name[1][0]}'.toUpperCase();
  }

  String get _roleLabel {
    final role = user['role'] as String? ?? 'buyer';
    switch (role) {
      case 'seller': return '🏪 Vendeur';
      case 'admin':  return '⚙️ Admin';
      default:       return '🛍️ Acheteur';
    }
  }

  Color get _roleColor {
    final role = user['role'] as String? ?? 'buyer';
    switch (role) {
      case 'seller': return const Color(0xFF6B7F4D);
      case 'admin':  return Colors.purple;
      default:       return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user['avatarUrl'] as String?;
    final fullName = user['fullName'] as String? ?? 'Utilisateur';
    final email = user['email'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _roleColor.withOpacity(0.3), width: 1.5),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _initialsWidget(),
                      )
                    : _initialsWidget(),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Badge rôle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _roleLabel,
                style: TextStyle(
                  color: _roleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chat_bubble_outline,
                color: _roleColor, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _initialsWidget() => Container(
        color: const Color(0xFFD4E4B8),
        child: Center(
          child: Text(
            _initials,
            style: const TextStyle(
              color: Color(0xFF6B7F4D),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
}
