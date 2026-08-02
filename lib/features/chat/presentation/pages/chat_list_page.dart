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
    final currentUid = context.read<AuthCubit>().currentUser?.id ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(RouteNames.home);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4EE),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6B7F4D),
          elevation: 0,
          title: const Text(
            'Messages',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
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
                    const Icon(Icons.error_outline,
                        color: Colors.grey, size: 48),
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
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7F4D).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Color(0xFF6B7F4D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun message pour l\'instant',
                      style: TextStyle(
                        color: Color(0xFF2B2B2B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherUid = chat.participantIds
                    .firstWhere((id) => id != currentUid, orElse: () => '');
                final otherName =
                    chat.participantNames[otherUid] ?? 'Utilisateur';
                final unread = chat.unreadCount[currentUid] ?? 0;

                return GestureDetector(
                  onTap: () => context.go('/messages/${chat.id}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: unread > 0
                          ? Border.all(
                              color:
                                  const Color(0xFF6B7F4D).withOpacity(0.3),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6B7F4D).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              otherName.isNotEmpty
                                  ? otherName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF6B7F4D),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
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
                                          : FontWeight.w600,
                                      fontSize: 15,
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
                                        fontWeight: unread > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                ],
                              ),
                              if (chat.productTitle != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.checkroom,
                                      size: 12,
                                      color: Color(0xFFC3653D),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      chat.productTitle!,
                                      style: const TextStyle(
                                        color: Color(0xFFC3653D),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat.lastMessage ??
                                          'Conversation démarrée',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: unread > 0
                                            ? const Color(0xFF2B2B2B)
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
                                        color: Color(0xFFC3653D),
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
              case 0: context.go(RouteNames.home); break;
              case 1: context.go(RouteNames.search); break;
              case 2: context.go(RouteNames.publish); break;
              case 3: context.go(RouteNames.messages); break;
              case 4: context.go(RouteNames.profile); break;
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF6B7F4D),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil'),
            BottomNavigationBarItem(
                icon: Icon(Icons.search), label: 'Chercher'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'Publier'),
            BottomNavigationBarItem(
                icon: Icon(Icons.message), label: 'Messages'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil'),
          ],
        ),
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