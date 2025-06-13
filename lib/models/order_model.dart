import 'package:kebuli_mimi/models/menu_model.dart';

class Order {
  final String id;
  final String idUser;
  final double harga;
  final String metodePembayaran;
  final String status;
  final DateTime createdAt;
  final List<OrderDetail>? orderDetails;

  Order({
    required this.id,
    required this.idUser,
    required this.harga,
    required this.metodePembayaran,
    required this.status,
    required this.createdAt,
    this.orderDetails,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      idUser: json['id_user'].toString(),
      harga: json['harga'].toDouble(),
      metodePembayaran: json['metode_pembayaran'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      orderDetails:
          json['order_detail'] != null
              ? (json['order_detail'] as List)
                  .map((detail) => OrderDetail.fromJson(detail))
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'harga': harga,
      'metode_pembayaran': metodePembayaran,
      'status': status,
    };
  }
}

class OrderDetail {
  final String id;
  final String idOrder;
  final String idMenu;
  final int jumlah;
  final double subtotal;
  final Menu? menu;

  OrderDetail({
    required this.id,
    required this.idOrder,
    required this.idMenu,
    required this.jumlah,
    required this.subtotal,
    this.menu,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'].toString(),
      idOrder: json['id_order'].toString(),
      idMenu: json['id_menu'].toString(),
      jumlah: json['jumlah'],
      subtotal: json['subtotal'].toDouble(),
      menu: json['menu'] != null ? Menu.fromJson(json['menu']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_order': idOrder,
      'id_menu': idMenu,
      'jumlah': jumlah,
      'subtotal': subtotal,
    };
  }
}
