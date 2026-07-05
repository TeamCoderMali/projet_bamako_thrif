// ─── Bamako Thrift — Order Model (Data Layer) ──────────────────────────────
import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.buyerId,
    required super.sellerId,
    required super.productId,
    required super.productTitle,
    required super.productImageUrl,
    required super.amount,
    required super.status,
    required super.paymentMethod,
    super.paymentReference,
    required super.deliveryAddress,
    required super.createdAt,
    super.updatedAt,
    super.deliveredAt,
  });

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OrderModel(
      id: id,
      buyerId: data['buyerId'] as String,
      sellerId: data['sellerId'] as String,
      productId: data['productId'] as String,
      productTitle: data['productTitle'] as String,
      productImageUrl: data['productImageUrl'] as String,
      amount: (data['amount'] as num).toDouble(),
      status: _parseStatus(data['status'] as String?),
      paymentMethod: _parsePaymentMethod(data['paymentMethod'] as String?),
      paymentReference: data['paymentReference'] as String?,
      deliveryAddress: data['deliveryAddress'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int? ?? 0,
      ),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deliveredAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'buyerId': buyerId,
        'sellerId': sellerId,
        'productId': productId,
        'productTitle': productTitle,
        'productImageUrl': productImageUrl,
        'amount': amount,
        'status': status.name,
        'paymentMethod': paymentMethod.name,
        'paymentReference': paymentReference,
        'deliveryAddress': deliveryAddress,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
      };

  static OrderStatus _parseStatus(String? value) => OrderStatus.values
      .firstWhere((e) => e.name == value, orElse: () => OrderStatus.pending);

  static PaymentMethod _parsePaymentMethod(String? value) =>
      PaymentMethod.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaymentMethod.orangeMoney,
      );
}
