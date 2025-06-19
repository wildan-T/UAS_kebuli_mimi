import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kebuli_mimi/models/cart_model.dart';
import 'package:kebuli_mimi/models/menu_model.dart';
import 'package:provider/provider.dart';

class MenuDetailScreen extends StatelessWidget {
  final Menu menu;

  const MenuDetailScreen({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final cart = Provider.of<Cart>(context, listen: false);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Membuat AppBar menjadi transparan agar gambar bisa terlihat di belakangnya
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Memberi bayangan pada ikon agar terlihat jelas di atas gambar
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
        ),
      ),
      body: SingleChildScrollView(
        // Menggunakan padding: EdgeInsets.zero agar gambar menempel di atas
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gambar Menu di bagian paling atas
            Hero(
              tag: 'menu_image_${menu.id}',
              child: Image.network(
                menu.gambar ?? '',
                width: double.infinity,
                height: 350,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 350,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.grey,
                        size: 100,
                      ),
                    ),
              ),
            ),

            // 2. Konten detail menu dengan padding
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Menu (sekarang di bawah foto)
                  Text(
                    menu.namaMenu,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row(
                  //   children: [
                  //     const Icon(Icons.star, color: Colors.amber, size: 20),
                  //     const SizedBox(width: 4),
                  //     Text('4.8', style: textTheme.bodyLarge),
                  //     const SizedBox(width: 24),
                  //     Icon(
                  //       Icons.timer_outlined,
                  //       color: Colors.grey[700],
                  //       size: 20,
                  //     ),
                  //     const SizedBox(width: 4),
                  //     Text('15 menit', style: textTheme.bodyLarge),
                  //   ],
                  // ),
                  // const SizedBox(height: 16),

                  // Harga
                  Text(
                    currencyFormatter.format(menu.harga),
                    style: textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1),
                  const SizedBox(height: 20),

                  // Deskripsi
                  Text(
                    'Deskripsi',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    menu.deskripsi ?? 'Tidak ada deskripsi untuk menu ini.',
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Tombol Aksi di bagian bawah layar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Tambah ke Keranjang'),
            onPressed: () {
              cart.addItem(menu);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${menu.namaMenu} ditambahkan ke keranjang.'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
