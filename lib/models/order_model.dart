import 'package:kebuli_mimi/models/menu_model.dart';

class Order {
  final int id; // Diubah dari String ke int
  final String idUser;
  final double harga;
  final String metodePembayaran;
  final String status;
  final DateTime createdAt;
  final List<OrderDetail>? orderDetails;
  final String? fotoPembayaran;
  final String? alamat;
  final String? catatanAlamat;
  final String? catatanPesanan;
  final double? latitude;
  final double? longitude;
  final double? ongkir;

  Order({
    required this.id,
    required this.idUser,
    required this.harga,
    required this.metodePembayaran,
    required this.status,
    required this.createdAt,
    this.orderDetails,
    this.fotoPembayaran, // Ditambahkan di constructor
    this.alamat,
    this.catatanAlamat,
    this.catatanPesanan,
    this.latitude,
    this.longitude,
    this.ongkir,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      idUser: json['id_user'].toString(),
      harga: json['harga'].toDouble(),
      metodePembayaran: json['metode_pembayaran'],
      status: json['status'],
      createdAt: DateTime.parse('${json['created_at']}Z').toLocal(),
      fotoPembayaran: json['foto_pembayaran'],
      alamat: json['alamat'],
      catatanAlamat: json['catatan_alamat'],
      catatanPesanan: json['catatan_pesanan'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      ongkir: (json['ongkir'] ?? 0.0).toDouble(),
      orderDetails:
          json['order_detail'] != null
              ? (json['order_detail'] as List)
                  .map((detail) => OrderDetail.fromJson(detail))
                  .toList()
              : null,
    );
  }

  // toJson tidak perlu diubah karena data ini dikirim ke RPC
  // yang di-handle di service
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
  final int id; // Diubah dari String ke int
  final int idOrder; // Diubah dari String ke int
  final int idMenu; // Diubah dari String ke int
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
      id: json['id'],
      idOrder: json['id_order'],
      idMenu: json['id_menu'],
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
