import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Sebuah kelas utilitas untuk menangani dan menampilkan pesan error
/// secara konsisten di seluruh aplikasi.
class ErrorHandler {
  /// Menampilkan pesan error dalam bentuk Toast (popup singkat di bawah).
  static void showToast(String message) {
    Fluttertoast.showToast(
      msg: _getFriendlyErrorMessage(message),
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red[700],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Menampilkan pesan error dalam bentuk SnackBar (bar notifikasi di bawah).
  static void showSnackBar(BuildContext context, String message) {
    // Pastikan context masih valid sebelum digunakan
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getFriendlyErrorMessage(message)),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  /// Menerjemahkan pesan error teknis menjadi pesan yang ramah pengguna.
  static String _getFriendlyErrorMessage(String technicalError) {
    // Selalu cetak error asli ke konsol untuk kebutuhan debugging oleh developer.
    debugPrint('Error Asli yang Ditangkap: $technicalError');

    // Terjemahan dari error umum
    if (technicalError.toLowerCase().contains('network is unreachable') ||
        technicalError.toLowerCase().contains('failed host lookup')) {
      return 'Koneksi internet bermasalah. Silakan periksa koneksi Anda.';
    }

    if (technicalError.toLowerCase().contains('invalid login credentials')) {
      return 'Email atau password yang Anda masukkan salah.';
    }

    if (technicalError.toLowerCase().contains('user already registered')) {
      return 'Email ini sudah terdaftar. Silakan gunakan email lain atau login.';
    }

    if (technicalError.toLowerCase().contains(
      'violates foreign key constraint',
    )) {
      return 'Gagal: Data ini sedang digunakan oleh data lain dan tidak bisa dihapus.';
    }

    if (technicalError.toLowerCase().contains('no implementation found')) {
      return 'Gagal membuka aplikasi eksternal. Pastikan aplikasi yang dituju sudah terpasang.';
    }

    // Pesan default jika error tidak dikenali
    return 'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi.';
  }
}
