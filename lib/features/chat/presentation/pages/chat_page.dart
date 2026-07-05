import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation')),
      body: Center(
        child: Text('Chat — ID: $chatId'),
      ),
    );
  }
}
