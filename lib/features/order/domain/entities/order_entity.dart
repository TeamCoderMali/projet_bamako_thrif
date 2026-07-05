// ─── Bamako Thrift — Order Entity (Domain Layer) ───────────────────────────
import 'package:equatable/equatable.dart';

class OrderEntity extends Equatable {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productTitle;
  final String productImageUrl;
  final double amount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentReference;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;

  const OrderEntity({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.paymentReference,
    required this.deliveryAddress,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
  });

  bool get isPaid => status != OrderStatus.pending && status != OrderStatus.cancelled;
  bool get isCompleted => status == OrderStatus.delivered;

  @override
  List<Object?> get props => [
        id, buyerId, sellerId, productId, amount,
        status, paymentMethod, createdAt,
      ];
}

enum OrderStatus {
  pending,    // En attente de paiement
  confirmed,  // Paiement confirmé
  processing, // En préparation
  shipped,    // Expédié
  delivered,  // Livré
  cancelled,  // Annulé
  refunded,   // Remboursé
  disputed,   // Litige
}

enum PaymentMethod {
  orangeMoney,
  wave,
  creditCard,
  cash,
}
