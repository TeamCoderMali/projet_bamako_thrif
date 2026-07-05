import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: const Center(
        child: Text('Mes commandes'),
      ),
    );
  }
}
