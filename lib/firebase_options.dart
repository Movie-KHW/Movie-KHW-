// ===== KONFIGURASI FIREBASE =====
// File ini dihasilkan berdasarkan data dari google-services.json
// Firebase Project ID: khwmovie-8f74c
// Dibuat oleh: Duwi Galu Gandimi (2411500010) - Anggota 2

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// ===== KONFIGURASI PLATFORM FIREBASE =====
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Platform iOS belum dikonfigurasi. Jalankan flutterfire configure untuk iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Platform macOS belum dikonfigurasi. Jalankan flutterfire configure untuk macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Platform Windows belum dikonfigurasi. Jalankan flutterfire configure untuk Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Platform Linux belum dikonfigurasi. Jalankan flutterfire configure untuk Linux.',
        );
      default:
        throw UnsupportedError(
          'Platform yang sedang digunakan tidak didukung oleh Firebase.',
        );
    }
  }

  // Konfigurasi Firebase untuk Android
  // Package Name: com.example.khw_movie
  // Firebase Project: khwmovie-8f74c
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2J0rC2Dovsm4ZgtrrNL98cggBJHxj3Qg',
    appId: '1:112389714359:android:94049d47748ffa0d353832',
    messagingSenderId: '112389714359',
    projectId: 'khwmovie-8f74c',
    storageBucket: 'khwmovie-8f74c.firebasestorage.app',
  );

  // Konfigurasi Firebase untuk Web (placeholder, aktifkan jika diperlukan)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2J0rC2Dovsm4ZgtrrNL98cggBJHxj3Qg',
    appId: '1:112389714359:android:94049d47748ffa0d353832',
    messagingSenderId: '112389714359',
    projectId: 'khwmovie-8f74c',
    storageBucket: 'khwmovie-8f74c.firebasestorage.app',
  );
}
