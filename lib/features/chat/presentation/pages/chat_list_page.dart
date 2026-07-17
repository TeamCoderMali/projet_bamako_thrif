import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bamako_thrift/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bamako_thrift/features/chat/domain/entities/message_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late final ChatRepositoryImpl _chatRepo;

  @override
  void initState() {
    super.initState();
    _chatRepo = ChatRepositoryImpl(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid =
        context.read<AuthCubit>().currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF6B7F4D)),
            tooltip: 'Nouveau message',
            onPressed: () => context.go('/messages/new'),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatEntity>>(
        stream: _chatRepo.watchChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B7F4D)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  Text('Erreur: ${snapshot.error}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun message pour l\'instant',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contactez un vendeur depuis un article',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              // Trouver le nom de l'autre participant
              final otherUid = chat.participantIds
                  .firstWhere((id) => id != currentUid, orElse: () => '');
              final otherName =
                  chat.participantNames[otherUid] ?? 'Utilisateur';
              final unread = chat.unreadCount[currentUid] ?? 0;

              return GestureDetector(
                onTap: () => context.go('/messages/${chat.id}'),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        backgroundColor: const Color(0xFFD4E4B8),
                        radius: 24,
                        child: Text(
                          otherName.isNotEmpty
                              ? otherName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF6B7F4D),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  otherName,
                                  style: TextStyle(
                                    fontWeight: unread > 0
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 14,
                                    color: const Color(0xFF2B2B2B),
                                  ),
                                ),
                                if (chat.lastMessageAt != null)
                                  Text(
                                    _formatDate(chat.lastMessageAt!),
                                    style: TextStyle(
                                      color: unread > 0
                                          ? const Color(0xFF6B7F4D)
                                          : Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Produit lié
                            if (chat.productTitle != null)
                              Text(
                                '📦 ${chat.productTitle}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7F4D),
                                  fontSize: 11,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.lastMessage ?? 'Conversation démarrée',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: unread > 0
                                          ? Colors.black87
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: unread > 0
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (unread > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6B7F4D),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.home);
              break;
            case 1:
              context.go(RouteNames.search);
              break;
            case 2:
              context.go(RouteNames.publish);
              break;
            case 3:
              context.go(RouteNames.messages);
              break;
            case 4:
              context.go(RouteNames.profile);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6B7F4D),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Chercher'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Publier'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month) {
      return DateFormat.Hm().format(dt);
    }
    if (now.difference(dt).inDays < 7) {
      return DateFormat.E('fr').format(dt);
    }
    return DateFormat('dd/MM').format(dt);
  }
}
