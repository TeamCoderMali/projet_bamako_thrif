// ─── Bamako Thrift — Order Repository (Domain Contract) ────────────────────
import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<List<OrderEntity>> getMyOrders({int page = 0, int limit = 20});
  Future<List<OrderEntity>> getMySales({int page = 0, int limit = 20});
  Future<OrderEntity> getOrderById(String orderId);
  Future<OrderEntity> createOrder(OrderEntity order);
  Future<OrderEntity> updateOrderStatus(String orderId, OrderStatus status);
  Future<void> cancelOrder(String orderId);
  Stream<OrderEntity> watchOrder(String orderId);
}
