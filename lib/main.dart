// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_constants.dart';

// Catatan Firebase Options:
// Setelah menjalankan perintah `flutterfire configure`, file `firebase_options.dart`
// akan dihasilkan di direktori `lib/`. Impor file tersebut dan gunakan:
// import 'firebase_options.dart';
// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// ===== INISIALISASI APLIKASI =====
void main() async {
  // Memastikan binding framework Flutter telah siap sebelum pemanggilan asinkron
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase Core
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Catatan inisialisasi Firebase: $e');
  }

  runApp(const KHWMovieApp());
}

// ===== ROOT APLIKASI DENGAN MULTIPROVIDER =====
class KHWMovieApp extends StatelessWidget {
  const KHWMovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider Anggota 1 (Melani Astuti - 2411500036): Autentikasi dan Profil
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),

        // Tempat integrasi Provider Anggota lain (Akan dihubungkan oleh Anggota 4):
        // Provider Anggota 2 (Duwi Galu Gandimi - 2411500010):
        // ChangeNotifierProvider<StoryProvider>(create: (_) => StoryProvider()),

        // Provider Anggota 3 (Fathurrahman Safari Lubis - 2411500025):
        // ChangeNotifierProvider<MovieProvider>(create: (_) => MovieProvider()),
        // ChangeNotifierProvider<FavoriteProvider>(create: (_) => FavoriteProvider()),

        // Provider Anggota 4 (Hanin Fadhilah - 2411500033):
        // ChangeNotifierProvider<ModerationProvider>(create: (_) => ModerationProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surface,
            error: AppColors.error,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        // AuthGate mengarahkan pengguna secara reaktif berdasarkan status login
        home: const AuthGate(),
      ),
    );
  }
}

// ===== PINTU AUTENTIKASI (AUTH GATE) =====
// Memeriksa status autentikasi secara realtime melalui AuthProvider
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 1. Tampilkan layar pemuatan awal saat status autentikasi sedang diinisialisasi
    if (!authProvider.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_filter_rounded,
                size: 64,
                color: AppColors.primaryLight,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              ),
              SizedBox(height: 16),
              Text(
                'Menyiapkan KHW Movie...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Jika pengguna sudah login, arahkan ke Beranda (HomeScreen)
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    }

    // 3. Jika pengguna belum login, arahkan ke Layar Masuk (LoginScreen)
    return const LoginScreen();
  }
}
