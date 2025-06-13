import 'dart:io';
import 'package:kebuli_mimi/models/menu_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class MenuService {
  final SupabaseClient supabase = Supabase.instance.client;

  final String _menuTable = 'menu';
  final String _kategoriTable = 'kategori';
  final String _storageBucket =
      'menu.images'; // NAMA BUCKET DI SUPABASE STORAGE

  Future<List<Kategori>> getCategories() async {
    try {
      final response = await supabase.from(_kategoriTable).select();
      return response.map((item) => Kategori.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil kategori: $e');
    }
  }

  Future<List<Menu>> getAllMenus() async {
    try {
      // Join dengan tabel kategori untuk mendapatkan nama kategori
      final response = await supabase
          .from(_menuTable)
          .select('*, kategori(id, nama_kategori)');
      return response.map((item) => Menu.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil menu: $e');
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';

      await supabase.storage.from(_storageBucket).upload(fileName, file);

      final urlResponse = supabase.storage
          .from(_storageBucket)
          .getPublicUrl(fileName);
      return urlResponse;
    } catch (e) {
      throw Exception('Gagal mengunggah gambar: $e');
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await supabase.storage.from(_storageBucket).remove([fileName]);
    } catch (e) {
      // Tidak melempar exception agar proses delete menu tetap berjalan
      // jika file tidak ada di storage.
      print('Gagal menghapus gambar: $e');
    }
  }

  Future<void> addMenu(Map<String, dynamic> data, {XFile? imageFile}) async {
    try {
      if (imageFile != null) {
        final imageUrl = await _uploadImage(imageFile);
        data['gambar'] = imageUrl;
      }
      await supabase.from(_menuTable).insert(data);
    } catch (e) {
      throw Exception('Gagal menambah menu: $e');
    }
  }

  Future<void> updateMenu(
    int id,
    Map<String, dynamic> data, {
    XFile? imageFile,
    String? oldImageUrl,
  }) async {
    try {
      if (imageFile != null) {
        // Hapus gambar lama jika ada dan unggah yang baru
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await _deleteImage(oldImageUrl);
        }
        final newImageUrl = await _uploadImage(imageFile);
        data['gambar'] = newImageUrl;
      }
      await supabase.from(_menuTable).update(data).eq('id', id);
    } catch (e) {
      throw Exception('Gagal memperbarui menu: $e');
    }
  }

  Future<void> deleteMenu(int id, {String? imageUrl}) async {
    try {
      // Hapus gambar dari storage terlebih dahulu
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _deleteImage(imageUrl);
      }
      await supabase.from(_menuTable).delete().eq('id', id);
    } catch (e) {
      // Handle error jika menu terkait dengan order
      if (e.toString().contains('violates foreign key constraint')) {
        throw Exception('Gagal: Menu ini sudah digunakan dalam data order.');
      }
      throw Exception('Gagal menghapus menu: $e');
    }
  }
}
