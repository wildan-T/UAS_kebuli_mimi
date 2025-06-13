import 'package:flutter/material.dart';
import 'package:kebuli_mimi/models/menu_model.dart';
import 'package:kebuli_mimi/services/menu_service.dart';
import 'package:kebuli_mimi/widgets/menu_card.dart';
import 'package:kebuli_mimi/widgets/loading_indicator.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final MenuService _menuService = MenuService();
  List<Menu> _menus = [];
  List<Kategori> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadMenus();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      _categories = await _menuService.getCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMenus() async {
    setState(() => _isLoading = true);
    try {
      _menus = await _menuService.getAllMenus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load menus: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Menu> get _filteredMenus {
    List<Menu> menus = _menus;

    // Filter berdasarkan kategori
    if (_selectedCategory != 'All') {
      menus =
          menus.where((menu) => menu.kategori == _selectedCategory).toList();
    }

    // Filter berdasarkan pencarian
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
    if (_isLoading) {
      return const LoadingIndicator();
    }

    // UI untuk kondisi kosong yang lebih baik
    if (_menus.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada menu tersedia saat ini.'),
          ],
        ),
      );
    }

    // Tampilan utama
    return Column(
      children: [
        // Widget Pencarian
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(
              hintText: 'Cari menu favoritmu...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),

        // Widget Filter Kategori
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final bool isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(category.namaKategori),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category.namaKategori);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: Theme.of(context).colorScheme.secondary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),

        // GridView Menu
        Expanded(
          child:
              _filteredMenus.isEmpty
                  ? const Center(child: Text('Menu tidak ditemukan.'))
                  : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _filteredMenus.length,
                    itemBuilder: (context, index) {
                      return MenuCard(
                        menu: _menus[index],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/menu_detail',
                            arguments: _menus[index],
                          );
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
