import 'package:flutter/material.dart';

class OrderTrackingPage extends StatelessWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi commande')),
      body: Center(
        child: Text('Order Tracking — ID: $orderId'),
      ),
    );
  }
}
