import 'package:flutter/material.dart';
import 'package:kebuli_mimi/models/menu_model.dart';

class CartItem {
  final Menu menu;
  int quantity;

  CartItem({required this.menu, this.quantity = 1});

  double get subtotal => menu.harga * quantity;
}

class Cart extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);

  void addItem(Menu menu) {
    final index = _items.indexWhere((item) => item.menu.id == menu.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(menu: menu));
    }
    // Memberi tahu listener agar UI diperbarui
    notifyListeners();
  }

  // Tipe data diubah menjadi 'int' agar sesuai dengan model Menu
  void removeItem(int menuId) {
    final index = _items.indexWhere((item) => item.menu.id == menuId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      // Memberi tahu listener agar UI diperbarui
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    // Memberi tahu listener agar UI diperbarui
    notifyListeners();
  }
}
