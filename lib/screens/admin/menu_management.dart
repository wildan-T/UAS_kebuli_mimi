import 'package:flutter/material.dart';
import 'package:kebuli_mimi/models/menu_model.dart';
import 'package:kebuli_mimi/screens/admin/menu_form_dialog.dart';
import 'package:kebuli_mimi/services/menu_service.dart';
import 'package:intl/intl.dart';
import 'package:kebuli_mimi/utils/error_handler.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final MenuService _menuService = MenuService();
  late Future<List<Menu>> _menusFuture;
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  void _loadMenus() {
    setState(() {
      _menusFuture = _menuService.getAllMenus();
    });
  }

  Future<void> _showMenuDialog({Menu? menu}) async {
    final bool? success = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MenuFormDialog(menu: menu, menuService: _menuService),
    );

    if (success == true) {
      _loadMenus();
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteMenu(Menu menu) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Anda yakin ingin menghapus menu "${menu.namaMenu}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _menuService.deleteMenu(menu.id, imageUrl: menu.gambar);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu "${menu.namaMenu}" berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMenus();
      } catch (e) {
        if (mounted) ErrorHandler.showSnackBar(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showMenuDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<Menu>>(
        future: _menusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada menu.'));
          }

          final menus = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadMenus(),
            child: ListView.builder(
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final menu = menus[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child:
                          menu.gambar != null && menu.gambar!.isNotEmpty
                              ? Image.network(
                                menu.gambar!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                loadingBuilder:
                                    (_, child, progress) =>
                                        progress == null
                                            ? child
                                            : const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                              )
                              : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.restaurant_menu,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                    ),
                    title: Text(
                      menu.namaMenu,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${currencyFormatter.format(menu.harga)}\nKategori: ${menu.kategori?.namaKategori ?? 'N/A'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showMenuDialog(menu: menu),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMenu(menu),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
