import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kebuli_mimi/models/order_model.dart';

class PaymentScreen extends StatelessWidget {
  final Order order;

  const PaymentScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Total Payment', style: TextStyle(fontSize: 18)),
                    Text(
                      'Rp ${order.harga}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (order.metodePembayaran == 'QRIS')
                      Column(
                        children: [
                          QrImageView(
                            data: 'kebulimimi://payment?amount=${order.harga}',
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                          const Text('Scan QR code to pay'),
                        ],
                      ),
                    if (order.metodePembayaran == 'Transfer')
                      const Column(
                        children: [
                          Text('Bank BCA: 1234567890 (Kebuli Mimi)'),
                          SizedBox(height: 10),
                          Text('Please transfer the exact amount'),
                        ],
                      ),
                    if (order.metodePembayaran == 'COD')
                      const Column(
                        children: [
                          Icon(Icons.money, size: 50),
                          Text('Please prepare cash on delivery'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
