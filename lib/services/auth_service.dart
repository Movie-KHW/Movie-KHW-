// ===== IMPORT LIBRARY =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

// ===== SERVICE AUTENTIKASI =====
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  // Injeksi dependensi dengan nilai bawaan instance singleton Firebase
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ===== MEMERIKSA STATUS LOGIN (STREAM) =====
  // Mendengarkan perubahan status autentikasi secara realtime
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Mengambil objek pengguna Firebase saat ini (sinkron)
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // ===== MEMBUAT AKUN (REGISTRASI) =====
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    UserCredential? credential;
    try {
      // 1. Membuat akun pada Firebase Authentication
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Gagal membuat akun: Data pengguna tidak ditemukan.');
      }

      // 2. Memperbarui nama tampilan di Firebase Auth
      await firebaseUser.updateDisplayName(name.trim());

      // 3. Menyiapkan model profil pengguna dengan role baku 'user'
      final newUser = UserModel(
        uid: firebaseUser.uid,
        displayName: name.trim(),
        email: email.trim(),
        role: AppConstants.roleUser, // Sesuai aturan: akun baru selalu berstatus 'user'
        createdAt: DateTime.now(),
      );

      // 4. Menyimpan dokumen profil ke Cloud Firestore pada users/{uid}
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(firebaseUser.uid)
            .set(newUser.toMap());
      } catch (firestoreError) {
        // Rollback kritis: Jika penulisan Firestore gagal, hapus akun auth yang baru dibuat
        // agar tidak meninggalkan akun menggantung tanpa dokumen profil
        await firebaseUser.delete().catchError((_) => null);
        throw Exception(
          'Gagal menyimpan profil pengguna ke database. Akun dibatalkan demi konsistensi data. Detail: $firestoreError',
        );
      }

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ===== LOGIN MENGGUNAKAN EMAIL DAN PASSWORD =====
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autentikasi kredensial pengguna di Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Login gagal: Data pengguna tidak ditemukan.');
      }

      // 2. Membaca data profil pengguna dari Firestore users/{uid}
      final userProfile = await getUserProfile(firebaseUser.uid);

      if (userProfile != null) {
        return userProfile;
      }

      // Jika dokumen profil belum ada (misal registrasi lama tanpa profil Firestore),
      // buatkan profil default dengan role 'user' secara aman
      final fallbackProfile = UserModel(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'Pengguna KHW',
        email: firebaseUser.email ?? email.trim(),
        role: AppConstants.roleUser, // Tidak boleh otomatis menjadi admin
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(fallbackProfile.toMap());

      return fallbackProfile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ===== MENGAMBIL PROFIL PENGGUNA =====
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserModel.fromMap(docSnapshot.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal membaca profil pengguna: $e');
    }
  }

  // ===== LOGOUT DARI APLIKASI =====
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Gagal keluar dari aplikasi: $e');
    }
  }

  // ===== MENANGANI ERROR DARI FIREBASE AUTH =====
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Format email yang dimasukkan tidak valid.';
      case 'user-disabled':
        return 'Akun pengguna ini telah dinonaktifkan.';
      case 'user-not-found':
        return 'Akun dengan email tersebut tidak ditemukan.';
      case 'wrong-password':
        return 'Kata sandi yang Anda masukkan salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.';
      case 'operation-not-allowed':
        return 'Metode login Email/Password belum diaktifkan di Firebase Console.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Minimal 6 karakter.';
      case 'invalid-credential':
        return 'Email atau kata sandi tidak cocok. Periksa kembali data Anda.';
      case 'network-request-failed':
        return 'Gagal terhubung. Periksa koneksi internet Anda.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.';
      default:
        return e.message ?? 'Terjadi kesalahan pada proses autentikasi.';
    }
  }
}
