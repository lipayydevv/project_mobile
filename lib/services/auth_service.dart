import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/siswa.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<Siswa?> login(String username, String password) async {
    try {
      final response = await supabase
          .from('siswa')
          .select('*')
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) {
        return null; // Login gagal
      }

      return Siswa.fromJson(response);
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  // Optional: Simpan session atau token di SharedPreferences / Riverpod / GetX
  Future<void> saveSession(Siswa siswa) async {
    // Contoh simpan di SharedPreferences (install package: shared_preferences)
    // Atau bisa pake Riverpod/GetX state management
    // Untuk sementara, kita cuma print
    debugPrint('User logged in: ${siswa.nama}');
  }
}
