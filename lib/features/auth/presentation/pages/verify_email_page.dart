import 'package:flutter/material.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification Email')),
      body: const Center(
        child: Text('Vérification Email'),
      ),
    );
  }
}
