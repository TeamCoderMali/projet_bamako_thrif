import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail Produit')),
      body: Center(
        child: Text('Product Detail — ID: $productId'),
      ),
    );
  }
}
