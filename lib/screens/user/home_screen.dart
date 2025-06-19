import 'package:flutter/material.dart';
import 'package:kebuli_mimi/screens/user/cart_screen.dart';
import 'package:kebuli_mimi/screens/user/menu_list.dart';
import 'package:kebuli_mimi/screens/user/order_history.dart';
import 'package:kebuli_mimi/screens/user/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    MenuListScreen(), // Dibuat tidak const untuk pembaruan
    const OrderHistoryScreen(),
    const ProfileScreen(),
  ];

  final List<String> _pageTitles = [
    'Menu Kebuli Mimi', // Judul ini tidak akan terpakai di AppBar baru
    'Riwayat Pesanan',
    'Profil Saya',
  ];

  // Fungsi untuk membangun AppBar dinamis
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_currentIndex == 0) {
      // AppBar kustom untuk halaman menu
      return AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Kebuli Mimi'),
            Text(
              'Masakan Timur Tengah Asli',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
        centerTitle: false,
      );
    } else {
      // AppBar default untuk halaman lain
      return AppBar(title: Text(_pageTitles[_currentIndex]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      // floatingActionButton sudah dihapus
    );
  }
}
