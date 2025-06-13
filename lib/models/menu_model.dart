class Menu {
  final int id;
  final String namaMenu;
  final double harga;
  final String? deskripsi;
  final String? gambar;
  final int? idKategori;
  final Kategori? kategori;

  Menu({
    required this.id,
    required this.namaMenu,
    required this.harga,
    this.deskripsi,
    this.gambar,
    required this.idKategori,
    this.kategori,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      namaMenu: json['nama_menu'],
      harga: (json['harga'] as num).toDouble(),
      deskripsi: json['deskripsi'],
      gambar: json['gambar'],
      idKategori: json['id_kategori'],
      // Cek apakah data kategori di-join atau tidak
      kategori:
          json['kategori'] != null ? Kategori.fromJson(json['kategori']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_menu': namaMenu,
      'harga': harga,
      'deskripsi': deskripsi,
      'gambar': gambar,
      'id_kategori': idKategori,
    };
  }
}

class Kategori {
  final int id;
  final String namaKategori;

  Kategori({required this.id, required this.namaKategori});

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(id: json['id'], namaKategori: json['nama_kategori']);
  }

  // Override untuk DropdownButton
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kategori && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
