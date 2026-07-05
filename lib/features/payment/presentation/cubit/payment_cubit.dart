// ─── Bamako Thrift — Payment Cubit & State ─────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';

// ── States ─────────────────────────────────────────────────────────────────
abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentProcessing extends PaymentState {
  const PaymentProcessing();
}

class PaymentSuccess extends PaymentState {
  final PaymentEntity payment;
  const PaymentSuccess(this.payment);
  @override
  List<Object?> get props => [payment];
}

class PaymentFailed extends PaymentState {
  final String message;
  const PaymentFailed(this.message);
  @override
  List<Object?> get props => [message];
}

class PaymentHistoryLoaded extends PaymentState {
  final List<PaymentEntity> payments;
  const PaymentHistoryLoaded(this.payments);
  @override
  List<Object?> get props => [payments];
}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _repository;

  PaymentCubit({required PaymentRepository repository})
      : _repository = repository,
        super(const PaymentInitial());

  Future<void> initiatePayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? phoneNumber,
  }) async {
    emit(const PaymentProcessing());
    try {
      final payment = await _repository.initiatePayment(
        orderId: orderId,
        amount: amount,
        method: method,
        phoneNumber: phoneNumber,
      );
      emit(PaymentSuccess(payment));
    } catch (e) {
      emit(PaymentFailed(e.toString()));
    }
  }

  Future<void> loadPaymentHistory() async {
    emit(const PaymentLoading());
    try {
      final payments = await _repository.getPaymentHistory();
      emit(PaymentHistoryLoaded(payments));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  void reset() => emit(const PaymentInitial());
}
