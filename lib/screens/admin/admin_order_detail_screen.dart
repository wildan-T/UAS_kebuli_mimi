import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:kebuli_mimi/models/order_model.dart';
import 'package:kebuli_mimi/models/user_model.dart';
import 'package:kebuli_mimi/services/order_service.dart';
import 'package:kebuli_mimi/services/user_service.dart';
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
    // Ambil data profil pemesan saat halaman dibuka
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
        // Kembali ke halaman sebelumnya dan kirim sinyal untuk refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka aplikasi peta: $e')),
        );
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
                _buildCustomerInfoCard(user),
                const SizedBox(height: 16),
                _buildDeliveryInfoCard(),
                const SizedBox(height: 16),
                _buildOrderItemsCard(context),
                const SizedBox(height: 16),
                _buildOrderNotesCard(),
                const SizedBox(height: 16),
                _buildPaymentInfoCard(context),
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

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget _buildCustomerInfoCard(UserModel user) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Pemesan', style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),
          _buildInfoRow('Nama:', user.nama),
          _buildInfoRow('No. Telepon:', user.no_telepon),
        ],
      ),
    ),
  );

  Widget _buildDeliveryInfoCard() => Card(
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
          if (widget.order.latitude != null && widget.order.longitude != null)
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
      ),
    ),
  );

  Widget _buildOrderItemsCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item Pesanan', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            if (widget.order.orderDetails == null ||
                widget.order.orderDetails!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Detail item tidak tersedia untuk pesanan ini.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.order.orderDetails!.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final detail = widget.order.orderDetails![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${detail.menu?.namaMenu ?? 'Menu Dihapus'} (x${detail.jumlah})',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(detail.subtotal),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
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

  Widget _buildPaymentInfoCard(BuildContext context) {
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
            // Tampilkan bukti pembayaran yang sudah ada
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
            ],
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
        // crossAxisAlignment.stretch akan membuat semua child di dalam Column
        // meregang memenuhi lebar parent-nya.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Aksi Admin', style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),
          if (_isLoading) const LoadingIndicator(),

          // Menggunakan collection-if untuk menampilkan tombol secara kondisional
          if (!_isLoading) ...[
            if (widget.order.status == 'processing') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Tandai Selesai'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  iconColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _updateStatus('completed'),
              ),
              // Beri jarak jika kedua tombol mungkin muncul bersamaan
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
                  iconColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _updateStatus('cancelled'),
              ),
            ],
          ],
        ],
      ),
    ),
  );
}
