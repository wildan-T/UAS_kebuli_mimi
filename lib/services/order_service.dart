import 'package:kebuli_mimi/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Order>> getAllOrders() async {
    final response = await _client
        .from('orders')
        .select('*, order_detail(*, menu(*))')
        .order('created_at', ascending: false);
    return (response as List).map((json) => Order.fromJson(json)).toList();
  }

  Future<List<Order>> getUserOrders(String userId) async {
    final response = await _client
        .from('orders')
        .select('*, order_detail(*, menu(*))')
        .eq('id_user', userId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Order.fromJson(json)).toList();
  }

  Future<void> createOrder(
    Order order,
    List<Map<String, dynamic>> orderDetails,
  ) async {
    await _client.rpc(
      'create_order_with_details',
      params: {'order_data': order.toJson(), 'order_details': orderDetails},
    );
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _client
        .from('orders')
        .update({'status': newStatus})
        .eq('id', orderId);
  }
}
