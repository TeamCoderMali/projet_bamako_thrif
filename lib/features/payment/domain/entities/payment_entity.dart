// ─── Bamako Thrift — Payment Entity (Domain Layer) ─────────────────────────
import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? reference;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  const PaymentEntity({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    this.reference,
    this.phoneNumber,
    required this.createdAt,
    this.confirmedAt,
  });

  bool get isSuccessful => status == PaymentStatus.completed;

  @override
  List<Object?> get props => [id, orderId, amount, method, status, createdAt];
}

/// Méthodes de paiement disponibles au Mali.
enum PaymentMethod {
  orangeMoney,
  wave,
  creditCard,
  cash,
}

enum PaymentStatus {
  pending,    // En attente
  processing, // En cours
  completed,  // Réussi
  failed,     // Échoué
  refunded,   // Remboursé
  cancelled,  // Annulé
}
