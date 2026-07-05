// ─── Bamako Thrift — Order Cubit & State ───────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

// ── States ─────────────────────────────────────────────────────────────────
abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrdersLoaded extends OrderState {
  final List<OrderEntity> orders;
  const OrdersLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrderState {
  final OrderEntity order;
  const OrderDetailLoaded(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class OrderCubit extends Cubit<OrderState> {
  final OrderRepository _repository;

  OrderCubit({required OrderRepository repository})
      : _repository = repository,
        super(const OrderInitial());

  Future<void> loadMyOrders() async {
    emit(const OrderLoading());
    try {
      final orders = await _repository.getMyOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> loadOrderDetail(String orderId) async {
    emit(const OrderLoading());
    try {
      final order = await _repository.getOrderById(orderId);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _repository.cancelOrder(orderId);
      await loadMyOrders();
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Stream<OrderEntity> watchOrder(String orderId) =>
      _repository.watchOrder(orderId);
}
