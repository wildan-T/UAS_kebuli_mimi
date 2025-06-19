import 'package:kebuli_mimi/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<UserModel> getUserProfile(String userId) async {
    try {
      final data =
          await _client.from('users').select().eq('id', userId).single();

      // Email tidak ada di tabel public.users, jadi kita beri placeholder
      // jika diperlukan di masa depan.
      data['email'] = '...';
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Gagal mengambil profil pengguna: $e');
    }
  }

  Future<void> updateFcmToken(String userId, String token) async {
    try {
      await _client
          .from('users')
          .update({
            'fcm_token': token,
          }) // Perbarui kolom fcm_token dengan token baru
          .eq('id', userId); // Untuk user dengan ID yang sesuai
    } catch (e) {
      // Anda bisa menambahkan penanganan error yang lebih baik di sini jika diperlukan
      print('Gagal memperbarui token FCM: $e');
      rethrow;
    }
  }
}
