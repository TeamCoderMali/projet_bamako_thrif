import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bamako_thrift/core/router/route_names.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {'text': 'L\'article est-il disponible ?', 'isMe': false},
    {'text': 'Oui, toujours disponible !', 'isMe': true},
    {'text': 'Je suis intéressé !', 'isMe': false},
    {'text': 'On peut se voir ?', 'isMe': false},
    {'text': 'Oui, cet après-midi', 'isMe': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go(RouteNames.messages),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFD4E4B8),
                  child: const Text(
                    'B',
                    style: TextStyle(
                      color: const Color(0xFF6B7F4D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baba Traoré',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'En ligne',
                  style: TextStyle(color: Colors.green, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Article concerné
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF7F4EE),
            child: const Row(
              children: [
                Icon(Icons.checkroom, color: const Color(0xFF6B7F4D), size: 20),
                SizedBox(width: 8),
                Text(
                  'Nike Air Max 270 — 25 000 FCFA',
                  style: TextStyle(
                    color: const Color(0xFF6B7F4D),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] as bool;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.orange : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message['text'] as String,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Champ message
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_messageController.text.isNotEmpty) {
                      setState(() {
                        _messages.add({
                          'text': _messageController.text,
                          'isMe': true,
                        });
                        _messageController.clear();
                      });
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: const Color(0xFF6B7F4D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
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
