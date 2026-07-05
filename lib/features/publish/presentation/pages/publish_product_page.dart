import 'package:flutter/material.dart';

class PublishProductPage extends StatelessWidget {
  const PublishProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier un article')),
      body: const Center(
        child: Text('Publier un article'),
      ),
    );
  }
}
