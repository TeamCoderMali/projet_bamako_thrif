// ─── Bamako Thrift — Payment Repository (Domain Contract) ──────────────────
import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<PaymentEntity> initiatePayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? phoneNumber,
  });
  Future<PaymentEntity> getPaymentStatus(String paymentId);
  Future<PaymentEntity> confirmPayment(String paymentId);
  Future<void> refundPayment(String paymentId);
  Future<List<PaymentEntity>> getPaymentHistory();
}
