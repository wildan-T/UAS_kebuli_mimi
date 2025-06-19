import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:kebuli_mimi/models/cart_model.dart';
import 'package:kebuli_mimi/screens/user/map_picker_screen.dart';
import 'package:kebuli_mimi/screens/user/payment_screen.dart';
import 'package:kebuli_mimi/services/auth_service.dart';
import 'package:kebuli_mimi/services/order_service.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressNotesController = TextEditingController();
  final _notesController = TextEditingController();
  final _orderNotesController = TextEditingController();
  String _paymentMethod = 'Transfer';
  bool _isLoading = false;
  // State untuk lokasi
  LatLng? _pickedLocation;
  double? _distanceInKm;

  // Lokasi Toko (ganti dengan koordinat asli toko Anda)
  static const LatLng _storeLocation = LatLng(-6.168806, 106.595926);

  @override
  void initState() {
    super.initState();
    // Secara otomatis mengisi data pengguna setelah screen dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mengambil data dari AuthService menggunakan Provider
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        _nameController.text = currentUser.nama;
        _phoneController.text = currentUser.no_telepon;
      }
    });
  }

  @override
  void dispose() {
    // Membersihkan controller saat widget tidak lagi digunakan
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _addressNotesController.dispose();
    _orderNotesController.dispose();
    super.dispose();
  }

  // Fungsi untuk membuka peta dan memilih lokasi
  void _selectOnMap() async {
    final pickedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (ctx) => const MapPickerScreen()),
    );

    if (pickedLocation == null) {
      return;
    }

    setState(() {
      _pickedLocation = pickedLocation;
      // Gunakan metode perhitungan jarak dari latlong2
      const distance = Distance();
      _distanceInKm = distance.as(
        LengthUnit.Kilometer,
        _storeLocation,
        _pickedLocation!,
      );
    });
  }

  // Fungsi untuk memproses pesanan
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Validasi lokasi
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih lokasi pengiriman di peta.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final cart = context.read<Cart>();
    final authService = context.read<AuthService>();
    final orderService = context.read<OrderService>(); // Ambil instance service

    final userId = authService.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal: Pengguna tidak ditemukan.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Siapkan data untuk dikirim ke Supabase
      final orderData = {
        'id_user': userId,
        'harga': cart.totalPrice,
        'metode_pembayaran': _paymentMethod,
        'status': 'pending',
        'alamat': _addressController.text,
        'catatan_alamat': _addressNotesController.text,
        'catatan_pesanan': _orderNotesController.text,
        'latitude': _pickedLocation!.latitude,
        'longitude': _pickedLocation!.longitude,
      };

      final orderDetails =
          cart.items.map((item) {
            return {
              'id_menu': item.menu.id,
              'jumlah': item.quantity,
              'subtotal': item.subtotal,
            };
          }).toList();

      // 2. Panggil service untuk membuat pesanan dan dapatkan hasilnya
      final newOrder = await orderService.createOrder(orderData, orderDetails);

      // 3. Kosongkan keranjang
      cart.clear();

      // 4. Navigasi ke halaman pembayaran dengan data pesanan yang valid dari DB
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(order: newOrder),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat pesanan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Pengiriman',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                enabled: false,
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Masukkan nama Anda'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                enabled: false,
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Masukkan nomor telepon Anda'
                            : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Alamat & Lokasi Pengiriman',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Kolom Alamat
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
                maxLines: 3,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Masukkan alamat Anda'
                            : null,
              ),
              const SizedBox(height: 16),

              // Kolom Catatan Alamat
              TextFormField(
                controller: _addressNotesController,
                decoration: const InputDecoration(
                  labelText: 'Detail Alamat (Contoh: Rumah cat putih)',
                ),
              ),
              const SizedBox(height: 16),

              // Bagian Peta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (_pickedLocation != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Lokasi sudah dipilih!')),
                          if (_distanceInKm != null)
                            Text(
                              '~${_distanceInKm!.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.location_off, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(child: Text('Lokasi belum dipilih')),
                        ],
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map),
                        label: Text(
                          _pickedLocation == null
                              ? 'Pilih di Peta'
                              : 'Ubah Lokasi',
                        ),
                        onPressed: _selectOnMap,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Kolom Catatan Pesanan
              TextFormField(
                controller: _orderNotesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan Pesanan (Opsional)',
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              Text(
                'Metode Pembayaran',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              RadioListTile<String>(
                title: const Text('Transfer Bank (BCA)'),
                value: 'Transfer',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              RadioListTile<String>(
                title: const Text('DANA'),
                value: 'DANA',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              RadioListTile<String>(
                title: const Text('Bayar di Tempat (COD)'),
                value: 'COD',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              const SizedBox(height: 24),
              Text(
                'Ringkasan Pesanan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ...cart.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.menu.namaMenu} x ${item.quantity}'),
                      Text('Rp ${item.subtotal}'),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Rp ${cart.totalPrice}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Buat Pesanan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
