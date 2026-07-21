// ─── Bamako Thrift — Payment Page ────────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:bamako_thrift/core/router/route_names.dart';
import 'package:bamako_thrift/features/product/domain/entities/product_entity.dart';

class PaymentPage extends StatefulWidget {
  final ProductEntity? product;
  const PaymentPage({super.key, this.product});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _method = 'orange_money';
  bool _isProcessing = false;
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _fmt(double price) =>
      '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA';

  String _condition(ProductCondition c) {
    switch (c) {
      case ProductCondition.newWithTags:
        return 'Neuf avec étiquette';
      case ProductCondition.newWithoutTags:
        return 'Neuf sans étiquette';
      case ProductCondition.veryGood:
        return 'Très bon état';
      case ProductCondition.good:
        return 'Bon état';
      case ProductCondition.fair:
        return 'État correct';
    }
  }

  bool _validate() {
    if (_method == 'card' || _method == 'wave') return true;
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez un numéro de téléphone valide (8 chiffres)'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _pay() async {
    if (!_validate()) return;
    setState(() => _isProcessing = true);
    try {
      final result = await _callPaymentGateway();
      if (!mounted) return;
      if (result.success) {
        await _createOrder();
        if (mounted) context.go(RouteNames.paymentSuccess);
      } else {
        if (mounted)
          context.go(RouteNames.paymentFailed, extra: result.errorMessage);
      }
    } catch (e) {
      if (mounted) context.go(RouteNames.paymentFailed, extra: e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<_PayResult> _callPaymentGateway() async {
    await Future.delayed(const Duration(seconds: 2));
    return _PayResult(true, null);
  }

  Future<void> _createOrder() async {
    final product = widget.product;
    if (product == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('order').add({
      'buyerId': uid,
      'sellerId': product.sellerId,
      'productId': product.id,
      'productTitle': product.title,
      'productImageUrl':
          product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
      'totalAmount': product.price,
      'status': 'pending',
      'paymentMethod': _method,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _markProductSold(product.id);
    await _recordWalletTransactions(uid, product);
  }

  Future<void> _markProductSold(String productId) async {
    await FirebaseFirestore.instance
        .collection('product')
        .doc(productId)
        .update({'status': 'sold'});
  }

  Future<void> _recordWalletTransactions(
      String buyerId, ProductEntity product) async {
    final db = FirebaseFirestore.instance;
    final price = product.price;
    final title = product.title;

    final buyerWallet = db.collection('wallet').doc(buyerId);
    await buyerWallet.set({
      'balance': FieldValue.increment(-price),
      'totalSpent': FieldValue.increment(price),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await buyerWallet.collection('transactions').add({
      'type': 'debit',
      'amount': price,
      'label': 'Achat – $title',
      'productId': product.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final sellerWallet = db.collection('wallet').doc(product.sellerId);
    await sellerWallet.set({
      'balance': FieldValue.increment(price),
      'totalEarned': FieldValue.increment(price),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await sellerWallet.collection('transactions').add({
      'type': 'credit',
      'amount': price,
      'label': 'Vente – $title',
      'productId': product.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = product?.price ?? 0.0;
    final fmtPrice = _fmt(price);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B7F4D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
        title: const Text(
          'Paiement',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Sécurisé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Récapitulatif ──────────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Récapitulatif',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (product != null) ...[
                    Text(
                      product.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (product.sellerName != null) product.sellerName!,
                        if (product.size != null) 'Taille ${product.size}',
                        _condition(product.condition),
                      ].join(' · '),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ] else
                    const Text('Article',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  _PriceLine(label: 'Prix', value: fmtPrice),
                  const SizedBox(height: 6),
                  _PriceLine(
                    label: 'Frais de service',
                    value: '1 000 FCFA',
                    valueColor: const Color(0xFFC3653D),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        _fmt(price + 1000),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF6B7F4D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14, color: Color(0xFF6B7F4D)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Fonds sécurisés — libérés après confirmation de réception',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF5A6B3E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Moyens de paiement ─────────────────────────────────────────
            const Text(
              'Moyen de paiement',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 10),

            _MethodTile(
              value: 'orange_money',
              logo: 'assets/images/orange_money.png',
              name: 'Orange Money',
              detail: '*144# · Mali',
              accentColor: const Color(0xFFFF7900),
              selected: _method,
              onTap: (v) => setState(() => _method = v),
            ),
            const SizedBox(height: 8),
            _MethodTile(
              value: 'moov_money',
              logo: 'assets/images/moov_money.png',
              name: 'Moov Money',
              detail: '*155# · Mali',
              accentColor: const Color(0xFF005EB8),
              selected: _method,
              onTap: (v) => setState(() => _method = v),
            ),
            const SizedBox(height: 8),
            _MethodTile(
              value: 'wave',
              logo: 'assets/images/wave.png',
              name: 'Wave',
              detail: 'QR code',
              accentColor: const Color(0xFF1BB3F0),
              selected: _method,
              onTap: (v) => setState(() => _method = v),
            ),
            const SizedBox(height: 8),
            _MethodTile(
              value: 'card',
              logo: 'assets/images/carte_bancaire.png',
              name: 'Carte bancaire',
              detail: 'Visa / Mastercard',
              accentColor: const Color(0xFF1A1A2E),
              selected: _method,
              onTap: (v) => setState(() => _method = v),
            ),

            const SizedBox(height: 16),

            // ── Saisie selon le moyen ──────────────────────────────────────
            if (_method == 'orange_money' || _method == 'moov_money') ...[
              const Text('Numéro de téléphone',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              _SectionCard(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 8,
                  decoration: InputDecoration(
                    hintText: '70 12 34 56',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixText: '+223  ',
                    prefixStyle: const TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w600),
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _method == 'orange_money'
                    ? 'Un message de confirmation vous sera envoyé via Orange Money'
                    : 'Un message de confirmation vous sera envoyé via Moov Money',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],

            if (_method == 'wave') ...[
              _SectionCard(
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 72, color: Color(0xFF1BB3F0)),
                    const SizedBox(height: 8),
                    const Text(
                      'Ouvrez l\'app Wave et scannez le QR code',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            if (_method == 'card') ...[
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Numéro de carte',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'MM/AA',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'CVV',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Bouton Payer ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7F4D),
                  disabledBackgroundColor:
                      const Color(0xFF6B7F4D).withOpacity(0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Payer ${_fmt(price + 1000)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 14),
            const Center(
              child: Text(
                '🔒  Paiement sécurisé · Aucun remboursement sans accord vendeur',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PayResult {
  final bool success;
  final String? errorMessage;
  const _PayResult(this.success, this.errorMessage);
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _PriceLine({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: valueColor ?? Colors.black87)),
        ],
      );
}

class _MethodTile extends StatelessWidget {
  final String value;
  final String logo;
  final String name;
  final String detail;
  final Color accentColor;
  final String selected;
  final ValueChanged<String> onTap;

  const _MethodTile({
    required this.value,
    required this.logo,
    required this.name,
    required this.detail,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade200,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 28,
              child: Image.asset(
                logo,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.payment,
                  color: accentColor,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? accentColor : Colors.black87,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
