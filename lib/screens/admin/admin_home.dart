import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kebuli_mimi/screens/admin/menu_management.dart';
import 'package:kebuli_mimi/screens/admin/order_management.dart';
import 'package:kebuli_mimi/screens/admin/reports_screen.dart';
import 'package:kebuli_mimi/services/auth_service.dart';
import 'package:kebuli_mimi/services/notification_service.dart';
import 'package:kebuli_mimi/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Channel untuk notifikasi real-time di dalam aplikasi dari Supabase
  late final RealtimeChannel _orderChannel;
  // Service untuk mengelola push notification dari Firebase
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _setupInAppNotificationListener();
    _initPushNotificationsAndSaveToken();
  }

  /// Fungsi ini menyiapkan listener ke Supabase untuk notifikasi real-time
  /// yang akan muncul sebagai popup/toast saat aplikasi admin sedang dibuka.
  void _setupInAppNotificationListener() {
    _orderChannel =
        Supabase.instance.client
            .channel('public:orders')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'orders',
              callback: (payload) {
                final newOrderId = payload.newRecord['id'];
                if (mounted && newOrderId != null) {
                  Fluttertoast.showToast(
                    msg: "Pesanan baru masuk! #$newOrderId",
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.TOP,
                    backgroundColor: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }
              },
            )
            .subscribe();
  }

  /// Fungsi ini menginisialisasi Firebase Cloud Messaging (FCM)
  /// untuk mendapatkan token perangkat dan menyimpannya ke profil admin.
  /// Ini diperlukan agar backend tahu ke mana harus mengirim push notification.
  void _initPushNotificationsAndSaveToken() async {
    try {
      await _notificationService.initNotifications();
      final token = await _notificationService.getFCMToken();

      if (token != null && mounted) {
        final userId = context.read<AuthService>().currentUser?.id;
        if (userId != null) {
          await context.read<UserService>().updateFcmToken(userId, token);
          print('FCM Token berhasil diperbarui di database.');
        }
      }
    } catch (e) {
      print('Gagal menginisialisasi push notification: $e');
    }
  }

  @override
  void dispose() {
    // Penting: Hentikan listener saat halaman tidak lagi digunakan
    // untuk mencegah kebocoran memori (memory leak).
    Supabase.instance.client.removeChannel(_orderChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final bool? confirmed = await showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Konfirmasi Logout'),
                      content: const Text('Apakah Anda yakin ingin keluar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true && mounted) {
                await authService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDashboardItem(
              context,
              icon: Icons.restaurant_menu,
              label: 'Manajemen Menu',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MenuManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardItem(
              context,
              icon: Icons.shopping_cart,
              label: 'Manajemen Pesanan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardItem(
              context,
              icon: Icons.bar_chart,
              label: 'Laporan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
