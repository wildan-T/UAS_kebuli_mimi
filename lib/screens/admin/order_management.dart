import 'package:flutter/material.dart';
import 'package:kebuli_mimi/models/order_model.dart';
import 'package:kebuli_mimi/screens/admin/admin_order_detail_screen.dart';
import 'package:kebuli_mimi/services/order_service.dart';
import 'package:kebuli_mimi/widgets/order_card.dart';
import 'package:kebuli_mimi/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  late OrderService _orderService;
  List<Order> _orders = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    // Mengambil instance OrderService dari Provider
    _orderService = Provider.of<OrderService>(context, listen: false);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      _orders = await _orderService.getAllOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pesanan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- FUNGSI INI DIPERBAIKI ---
  // 1. Tipe data orderId diubah menjadi int
  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      // 2. Memanggil fungsi updateOrderPayment yang benar dari service
      await _orderService.updateOrderPayment(
        orderId: orderId,
        newStatus: newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status pesanan #$orderId berhasil diubah menjadi $newStatus.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadOrders(); // Muat ulang daftar pesanan untuk melihat perubahan
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: ${e.toString()}')),
        );
      }
    }
  }
  // -------------------------

  List<Order> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((order) => order.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pesanan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _filterStatus,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua Pesanan')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(
                  value: 'processing',
                  child: Text('Processing'),
                ),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _filterStatus = value);
                }
              },
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const LoadingIndicator()
                    : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          return OrderCard(
                            order: order,
                            isAdmin: true,
                            // Pemanggilan fungsi sekarang sudah benar
                            onStatusChanged: (newStatus) {
                              _updateOrderStatus(order.id, newStatus);
                            },
                            onTap: () async {
                              final refreshed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          AdminOrderDetailScreen(order: order),
                                ),
                              );
                              if (refreshed == true && mounted) {
                                _loadOrders();
                              }
                            },
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
