// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';

// ===== KONSTANTA APLIKASI =====
class AppConstants {
  // Nama dan Informasi Aplikasi
  static const String appName = 'KHW Movie';
  static const String appTagline = 'Horror Stories & Movie Discovery';
  static const String appVersion = '1.0.0 (UTS PMP)';

  // Nama Koleksi Cloud Firestore
  static const String usersCollection = 'users';
  static const String storiesCollection = 'stories';
  static const String favoritesCollection = 'favorites';

  // Peran Pengguna (Role)
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';

  // Status Moderasi Cerita
  static const String statusPending = 'pending';
  static const String statusPublished = 'published';
  static const String statusRejected = 'rejected';
}

// ===== TEMA DAN WARNA APLIKASI =====
class AppColors {
  // Palet Warna Bernuansa Horor dan Sinematik
  static const Color primary = Color(0xFFB71C1C); // Merah darah gelap (Crimson)
  static const Color primaryDark = Color(0xFF7F0000);
  static const Color primaryLight = Color(0xFFF44336);
  static const Color accent = Color(0xFFFF5722); // Oranye mistis
  
  // Warna Latar Belakang & Permukaan
  static const Color background = Color(0xFF0F0F12); // Hitam pekat malam
  static const Color surface = Color(0xFF1A1A24); // Abu-abu gelap permukaan kartu
  static const Color surfaceLight = Color(0xFF262636);
  
  // Warna Teks
  static const Color textPrimary = Color(0xFFF5F5F5); // Putih terang
  static const Color textSecondary = Color(0xFFB0B0B8); // Abu-abu sekunder
  static const Color textMuted = Color(0xFF757582); // Abu-abu redup
  
  // Status Warna
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFEF5350);
  static const Color divider = Color(0xFF2C2C3A);
}
