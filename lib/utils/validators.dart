// ===== VALIDASI FORMULIR =====

class Validators {
  // Memvalidasi input nama lengkap pengguna
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap tidak boleh kosong';
    }
    if (value.trim().length < 3) {
      return 'Nama minimal terdiri dari 3 karakter';
    }
    return null;
  }

  // Memvalidasi format email menggunakan ekspresi reguler (Regex)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    
    // Pola regex standar untuk validasi format alamat email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid (contoh: nama@domain.com)';
    }
    return null;
  }

  // Memvalidasi kata sandi sesuai ketentuan minimal Firebase Authentication
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  // Memvalidasi konfirmasi kata sandi agar identik dengan kata sandi utama
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi tidak boleh kosong';
    }
    if (value != password) {
      return 'Konfirmasi kata sandi tidak cocok';
    }
    return null;
  }
}
