// ─── Bamako Thrift — Payment Model (Data Layer) ────────────────────────────
import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.userId,
    required super.amount,
    required super.method,
    required super.status,
    super.reference,
    super.phoneNumber,
    required super.createdAt,
    super.confirmedAt,
  });

  factory PaymentModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PaymentModel(
      id: id,
      orderId: data['orderId'] as String,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      method: _parseMethod(data['method'] as String?),
      status: _parseStatus(data['status'] as String?),
      reference: data['reference'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int? ?? 0,
      ),
      confirmedAt: data['confirmedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['confirmedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'userId': userId,
        'amount': amount,
        'method': method.name,
        'status': status.name,
        'reference': reference,
        'phoneNumber': phoneNumber,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'confirmedAt': confirmedAt?.millisecondsSinceEpoch,
      };

  static PaymentMethod _parseMethod(String? value) =>
      PaymentMethod.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaymentMethod.orangeMoney,
      );

  static PaymentStatus _parseStatus(String? value) =>
      PaymentStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaymentStatus.pending,
      );
}
