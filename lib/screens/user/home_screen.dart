import 'package:flutter/material.dart';
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
    const MenuListScreen(),
    const OrderHistoryScreen(),
    const ProfileScreen(),
  ];

  final List<String> _pageTitles = [
    'Menu Kebuli Mimi',
    'Riwayat Pesanan',
    'Profil Saya',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitles[_currentIndex])),
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
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                onPressed: () {
                  // Arahkan ke halaman keranjang (cart)
                },
                child: const Icon(Icons.shopping_cart),
              )
              : null,
    );
  }
}
