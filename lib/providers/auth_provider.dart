// ===== IMPORT LIBRARY =====
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// ===== PROVIDER AUTENTIKASI =====
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  // State internal
  UserModel? _userModel;
  User? _firebaseUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Subscription untuk mendengarkan stream autentikasi Firebase
  StreamSubscription<User?>? _authSubscription;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _initAuthStateListener();
  }

  // ===== GETTER STATE =====
  UserModel? get userModel => _userModel;
  User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAdmin => _userModel?.isAdmin ?? false;

  // ===== MEMERIKSA STATUS LOGIN (STREAM LISTENER) =====
  void _initAuthStateListener() {
    // Mendengarkan authStateChanges secara asinkron
    _authSubscription = _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        // Ambil data profil dari Cloud Firestore
        try {
          _userModel = await _authService.getUserProfile(user.uid);
        } catch (_) {
          _userModel = null;
        }
      } else {
        _userModel = null;
      }

      _isInitialized = true;
      notifyListeners();
    });
  }

  // ===== MEMBUAT AKUN =====
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearErrorMessage();

    try {
      final newUser = await _authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );
      _userModel = newUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ===== LOGIN KE APLIKASI =====
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearErrorMessage();

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _userModel = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ===== LOGOUT DARI APLIKASI =====
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _userModel = null;
      _firebaseUser = null;
      _clearErrorMessage();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  // ===== MEMPERBARUI DATA PROFIL =====
  Future<void> reloadUserProfile() async {
    if (_firebaseUser == null) return;
    try {
      final updated = await _authService.getUserProfile(_firebaseUser!.uid);
      if (updated != null) {
        _userModel = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error reload profile: $e');
    }
  }

  // ===== PEMBERSIH ERROR & HELPER STATE =====
  void clearError() {
    _clearErrorMessage();
    notifyListeners();
  }

  void _clearErrorMessage() {
    _errorMessage = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ===== DISPOSE SUBSCRIPTION =====
  @override
  void dispose() {
    // Membatalkan langganan stream agar tidak terjadi kebocoran memori (memory leak)
    _authSubscription?.cancel();
    super.dispose();
  }
}
