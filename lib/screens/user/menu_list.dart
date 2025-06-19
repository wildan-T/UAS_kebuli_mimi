import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kebuli_mimi/models/cart_model.dart';
import 'package:kebuli_mimi/models/menu_model.dart';
import 'package:kebuli_mimi/screens/user/menu_detail_screen.dart';
import 'package:kebuli_mimi/services/menu_service.dart';
import 'package:kebuli_mimi/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';

class MenuListScreen extends StatefulWidget {
  MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final MenuService _menuService = MenuService();
  List<Menu> _menus = [];
  List<Kategori> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Mengambil data menu dan kategori secara bersamaan
      final results = await Future.wait([
        _menuService.getAllMenus(),
        _menuService.getCategories(),
      ]);
      _menus = results[0] as List<Menu>;
      _categories = results[1] as List<Kategori>;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Logika filter yang diperbarui
  List<Menu> get _filteredMenus {
    List<Menu> menus = _menus;

    if (_selectedCategory != 'Semua') {
      menus =
          menus
              .where((menu) => menu.kategori?.namaKategori == _selectedCategory)
              .toList();
    }

    if (_searchQuery.isNotEmpty) {
      menus =
          menus
              .where(
                (menu) => menu.namaMenu.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }
    return menus;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari menu favorit...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // 2. Filter Kategori
        _buildCategoryFilter(),

        // 3. Daftar Menu (ListView)
        Expanded(
          child:
              _isLoading
                  ? const LoadingIndicator()
                  : RefreshIndicator(
                    onRefresh: _loadData,
                    child:
                        _filteredMenus.isEmpty
                            ? const Center(child: Text('Menu tidak ditemukan.'))
                            : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              itemCount: _filteredMenus.length,
                              itemBuilder: (context, index) {
                                return _buildNewMenuCard(_filteredMenus[index]);
                              },
                            ),
                  ),
        ),
      ],
    );
  }

  // Widget untuk filter kategori
  Widget _buildCategoryFilter() {
    final List<Kategori> displayCategories = [
      Kategori(id: -1, namaKategori: 'Semua'), // Kategori dummy 'Semua'
      ..._categories,
    ];

    final categoryIcons = {
      'Semua': Icons.fastfood_outlined,
      'Nasi': Icons.rice_bowl_outlined,
      'Snack': Icons.cookie_outlined,
      'Dessert': Icons.cake_outlined,
      'Minuman': Icons.local_drink_outlined,
    };

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          final bool isSelected = category.namaKategori == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                categoryIcons[category.namaKategori] ?? Icons.label_outline,
                color:
                    isSelected ? Colors.white : Theme.of(context).primaryColor,
                size: 20,
              ),
              label: Text(category.namaKategori),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category.namaKategori);
                }
              },
              backgroundColor:
                  isSelected ? Theme.of(context).primaryColor : Colors.white,
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: StadiumBorder(
                side: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
              elevation: 1,
              pressElevation: 3,
            ),
          );
        },
      ),
    );
  }

  // Widget untuk kartu menu baru
  Widget _buildNewMenuCard(Menu menu) {
    final cart = Provider.of<Cart>(context, listen: false);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Bungkus dengan GestureDetector untuk membuatnya bisa di-tap
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MenuDetailScreen(menu: menu)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero widget untuk animasi gambar yang halus
              Hero(
                tag: 'menu_image_${menu.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child:
                      menu.gambar != null && menu.gambar!.isNotEmpty
                          ? Image.network(
                            menu.gambar!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                          : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.grey,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 12),

              // Detail Menu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      menu.namaMenu,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // const SizedBox(height: 5),
                    // Row(
                    //   children: [
                    //     const Icon(Icons.star, color: Colors.amber, size: 18),
                    //     const SizedBox(width: 4),
                    //     Text(
                    //       '4.8',
                    //       style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    //     ),
                    //     const SizedBox(width: 12),
                    //     Icon(
                    //       Icons.timer_outlined,
                    //       color: Colors.grey[700],
                    //       size: 16,
                    //     ),
                    //     const SizedBox(width: 4),
                    //     Text(
                    //       '15 menit',
                    //       style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(menu.harga),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tombol Tambah
              // ElevatedButton(
              //   onPressed: () {
              //     cart.addItem(menu);
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(
              //         content: Text('${menu.namaMenu} ditambahkan ke keranjang.'),
              //         duration: const Duration(seconds: 1),
              //         backgroundColor: Colors.green,
              //       ),
              //     );
              //   },
              //   style: ElevatedButton.styleFrom(
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 16,
              //       vertical: 12,
              //     ),
              //   ),
              //   child: const Text('Tambah'),
              // ),
              FloatingActionButton.small(
                heroTag: 'add_menu_${menu.id}', // Tag unik untuk setiap tombol
                onPressed: () {
                  cart.addItem(menu);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${menu.namaMenu} ditambahkan ke keranjang.',
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
