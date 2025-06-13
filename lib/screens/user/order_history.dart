import 'package:flutter/material.dart';
import 'package:kebuli_mimi/models/order_model.dart';
import 'package:kebuli_mimi/services/auth_service.dart';
import 'package:kebuli_mimi/services/order_service.dart';
import 'package:kebuli_mimi/widgets/order_card.dart';
import 'package:kebuli_mimi/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      _orders = await _orderService.getUserOrders(user.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load orders: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    // Tampilan untuk "empty state" yang lebih baik
    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Anda belum pernah melakukan pesanan.'),
            ],
          ),
        ),
      );
    }

    // Tampilan daftar pesanan
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: OrderCard(order: _orders[index]),
          );
        },
      ),
    );
  }
}
