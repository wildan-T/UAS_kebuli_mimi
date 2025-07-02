import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:kebuli_mimi/models/order_model.dart';
import 'package:kebuli_mimi/models/user_model.dart';
import 'package:kebuli_mimi/services/order_service.dart';
import 'package:kebuli_mimi/services/user_service.dart';
import 'package:kebuli_mimi/utils/error_handler.dart';
import 'package:kebuli_mimi/widgets/loading_indicator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final Order order;
  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late Future<UserModel> _userFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userFuture = context.read<UserService>().getUserProfile(
      widget.order.idUser,
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await context.read<OrderService>().updateOrderPayment(
        orderId: widget.order.id,
        newStatus: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pesanan berhasil diubah menjadi $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        if (mounted) ErrorHandler.showSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        if (mounted) ErrorHandler.showSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Pesanan #${widget.order.id}')),
      body: FutureBuilder<UserModel>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat data pemesan: ${snapshot.error}'),
            );
          }
          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- PERBAIKAN DI SINI: Panggil _buildSummaryCard ---
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildCustomerInfoCard(user),
                const SizedBox(height: 16),
                _buildDeliveryInfoCard(),
                const SizedBox(height: 16),
                _buildOrderItemsCard(),
                const SizedBox(height: 16),
                _buildOrderNotesCard(),
                const SizedBox(height: 16),
                _buildPaymentInfoCard(),
                const SizedBox(height: 16),
                if (widget.order.status != 'completed' &&
                    widget.order.status != 'cancelled')
                  _buildAdminActionsCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    ),
  );

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCustomerInfoCard(UserModel user) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Pemesan', style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),
          _buildInfoRow('Nama', user.nama),
          _buildInfoRow('No. Telepon', user.no_telepon),
        ],
      ),
    ),
  );

  Widget _buildDeliveryInfoCard() => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Pengiriman',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Alamat',
            (widget.order.alamat?.isNotEmpty ?? false)
                ? widget.order.alamat!
                : '-',
          ),
          _buildInfoRow(
            'Catatan Alamat',
            (widget.order.catatanAlamat?.isNotEmpty ?? false)
                ? widget.order.catatanAlamat!
                : '-',
          ),
          const SizedBox(height: 16),
          if (widget.order.latitude != null &&
              widget.order.longitude != null) ...[
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    widget.order.latitude!,
                    widget.order.longitude!,
                  ),
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          widget.order.latitude!,
                          widget.order.longitude!,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka di Aplikasi Peta'),
                onPressed:
                    () => _launchMaps(
                      widget.order.latitude,
                      widget.order.longitude,
                    ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildOrderItemsCard() {
    final orderDetails = widget.order.orderDetails;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item Pesanan', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            if (orderDetails == null || orderDetails.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Detail item tidak tersedia.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orderDetails.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final detail = orderDetails[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${detail.menu?.namaMenu ?? 'Menu Dihapus'} (x${detail.jumlah})',
                    ),
                    trailing: Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(detail.subtotal),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNotesCard() => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan Pesanan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(height: 24),
          SizedBox(
            width: double.infinity,
            child: Text(
              (widget.order.catatanPesanan?.isNotEmpty ?? false)
                  ? widget.order.catatanPesanan!
                  : 'Tidak ada catatan.',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPaymentInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Info Pembayaran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            _buildInfoRow('Metode:', widget.order.metodePembayaran),
            const SizedBox(height: 16),
            if (widget.order.fotoPembayaran != null &&
                widget.order.fotoPembayaran!.isNotEmpty) ...[
              const Text(
                'Bukti Pembayaran Terunggah:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Image.network(widget.order.fotoPembayaran!)),
              const SizedBox(height: 16),
            ] else if (widget.order.metodePembayaran != 'COD')
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Bukti pembayaran belum diunggah.'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionsCard() => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Aksi Admin', style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),
          if (_isLoading) const LoadingIndicator(),
          if (!_isLoading) ...[
            if (widget.order.status == 'processing') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Tandai Selesai'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _updateStatus('completed'),
              ),
              if (widget.order.status == 'pending') const SizedBox(height: 12),
            ],
            if (widget.order.status == 'pending' ||
                widget.order.status == 'processing') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Batalkan Pesanan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _updateStatus('cancelled'),
              ),
            ],
            if (widget.order.status != 'pending' &&
                widget.order.status != 'processing')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    'Tidak ada aksi yang tersedia untuk status "${widget.order.status}".',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    ),
  );

  Widget _buildSummaryCard() {
    final dateFormat = DateFormat('dd MMMM HH:mm', 'id_ID');
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final double subtotal = widget.order.harga - (widget.order.ongkir ?? 0);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _buildInfoRow(
              'ID Pesanan:',
              '#${widget.order.id.toString().padLeft(4, '0')}',
            ),
            _buildInfoRow(
              'Tanggal:',
              dateFormat.format(widget.order.createdAt),
            ),
            _buildInfoRow(
              'Status:',
              widget.order.status.toUpperCase(),
              valueColor: _getStatusColor(widget.order.status),
            ),
            const Divider(),
            _buildInfoRow('Subtotal Item:', currencyFormatter.format(subtotal)),
            _buildInfoRow(
              'Ongkos Kirim:',
              currencyFormatter.format(widget.order.ongkir ?? 0),
            ),
            const Divider(thickness: 1.5),
            _buildInfoRow(
              'Total Harga:',
              currencyFormatter.format(widget.order.harga),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
}
