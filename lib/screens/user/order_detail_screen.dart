import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kebuli_mimi/models/order_model.dart';
import 'package:kebuli_mimi/services/order_service.dart';
import 'package:provider/provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  File? _proofImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Method untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  // Method untuk mengirim bukti pembayaran
  Future<void> _submitProof() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih gambar bukti pembayaran terlebih dahulu.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderService = context.read<OrderService>();
      // 1. Unggah gambar ke Supabase Storage
      final imageUrl = await orderService.uploadPaymentProof(_proofImage!);

      // 2. Perbarui data pesanan di database
      await orderService.updateOrderPayment(
        orderId: widget.order.id,
        newStatus: 'processing', // Status diubah menjadi 'processing'
        paymentImageUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti pembayaran berhasil diunggah!'),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke halaman sebelumnya dan kirim sinyal 'true' untuk refresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah bukti: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Pesanan #${widget.order.id.toString().padLeft(4, '0')}',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context),
            const SizedBox(height: 16),
            _buildOrderItemsCard(context),
            const SizedBox(height: 16),
            _buildOrderNotesCard(),
            const SizedBox(height: 16),
            _buildPaymentCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');
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
            _buildInfoRow(
              'Ongkir:',
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(widget.order.ongkir),
            ),
            _buildInfoRow(
              'Total Harga:',
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(widget.order.harga),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

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
              widget.order.catatanPesanan != null &&
                      widget.order.catatanPesanan!.isNotEmpty
                  ? widget.order.catatanPesanan!
                  : 'Tidak ada catatan.',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPaymentCard(BuildContext context) {
    bool isPending = widget.order.status == 'pending';
    bool canUpload = isPending && widget.order.metodePembayaran != 'COD';

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
            // Jika status 'pending', tampilkan UI untuk upload/ubah bukti
            if (canUpload) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                widget.order.fotoPembayaran == null
                    ? 'Unggah Bukti Pembayaran'
                    : 'Ubah Bukti Pembayaran',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Pratinjau gambar yang baru dipilih
              if (_proofImage != null)
                Center(
                  child: Image.file(
                    _proofImage!,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(height: 12),
              // Tombol untuk memilih dan mengirim bukti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Pilih Foto'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _isLoading || _proofImage == null ? null : _submitProof,
                    icon:
                        _isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.upload_file),
                    label:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Kirim Bukti'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
