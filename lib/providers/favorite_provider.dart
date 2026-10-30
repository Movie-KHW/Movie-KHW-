// ===== IMPORT LIBRARY =====
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/favorite_model.dart';
import '../models/movie_model.dart';
import '../utils/app_constants.dart';

// ===== PROVIDER FILM FAVORIT FIRESTORE =====
class FavoriteProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  // ===== STATE DATA =====
  List<FavoriteModel> _favorites = [];
  final Set<int> _favoriteMovieIds = <int>{};
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  // Langganan stream Firestore (Dart Async P01: Stream snapshots)
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritesSubscription;

  FavoriteProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Koleksi favorites di Firestore
  CollectionReference<Map<String, dynamic>> get _favoritesCollection =>
      _firestore.collection(AppConstants.favoritesCollection);

  // ===== GETTER STATE =====
  List<FavoriteModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get favoritesCount => _favorites.length;

  // Pemeriksaan cepat O(1) apakah film berstatus favorit
  bool isFavorite(int movieId) => _favoriteMovieIds.contains(movieId);

  // ===== MENDENGARKAN PERUBAHAN FAVORIT (STREAM LISTENER) =====
  // Menginisialisasi stream realtime data favorit milik pengguna yang sedang login
  void initFavoritesStream(String? userId) {
    // Jika user sama dan stream sudah aktif, jangan re-subscribe
    if (userId == _currentUserId && _favoritesSubscription != null) {
      return;
    }

    _currentUserId = userId;
    _favoritesSubscription?.cancel();
    _favoriteMovieIds.clear();

    if (userId == null || userId.trim().isEmpty) {
      _favorites = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Query Firestore hanya dengan filter userId (tanpa orderBy sesuai aturan UTS P05 Poin 7)
    _favoritesSubscription = _favoritesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        final list = snapshot.docs
            .map((doc) => FavoriteModel.fromFirestore(doc))
            .toList();

        // Pengurutan dilakukan di sisi client (Dart) berdasarkan tanggal terbaru
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _favorites = list;
        _favoriteMovieIds
          ..clear()
          ..addAll(list.map((f) => f.movieId));

        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Gagal memuat film favorit: $error';
        notifyListeners();
      },
    );
  }

  // ===== MENAMBAHKAN FAVORIT =====
  // Menyimpan dokumen dengan ID deterministik: {uid}_{movieId}
  Future<bool> addFavorite({
    required String? userId,
    required MovieModel movie,
  }) async {
    if (userId == null || userId.trim().isEmpty) {
      _errorMessage = 'Silakan masuk ke akun Anda untuk menyimpan film favorit.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;

    try {
      final docId = FavoriteModel.generateDocId(userId, movie.id);
      final newFavorite = FavoriteModel(
        id: docId,
        userId: userId,
        movieId: movie.id,
        title: movie.title,
        posterPath: movie.posterPath,
        createdAt: DateTime.now(),
        overview: movie.overview,
        voteAverage: movie.voteAverage,
        releaseDate: movie.releaseDate,
      );

      // Simpan langsung menggunakan docId deterministik
      await _favoritesCollection.doc(docId).set(newFavorite.toMap());

      _favoriteMovieIds.add(movie.id);
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menyimpan ke favorit: ${e.message ?? e.code}';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }

  // ===== MENGHAPUS FAVORIT =====
  Future<bool> removeFavorite({
    required String? userId,
    required int movieId,
  }) async {
    if (userId == null || userId.trim().isEmpty) {
      _errorMessage = 'Pengguna belum terautentikasi.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;

    try {
      final docId = FavoriteModel.generateDocId(userId, movieId);
      await _favoritesCollection.doc(docId).delete();

      _favoriteMovieIds.remove(movieId);
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = 'Gagal menghapus dari favorit: ${e.message ?? e.code}';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }

  // ===== TOGGLE FAVORIT (TAMBAH / HAPUS) =====
  Future<bool> toggleFavorite({
    required String? userId,
    required MovieModel movie,
  }) async {
    if (isFavorite(movie.id)) {
      return await removeFavorite(userId: userId, movieId: movie.id);
    } else {
      return await addFavorite(userId: userId, movie: movie);
    }
  }

  // ===== MENANGANI ERROR =====
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ===== DISPOSE SUBSCRIPTION =====
  @override
  void dispose() {
    // Membatalkan stream subscription saat provider ditutup agar tidak terjadi memory leak
    _favoritesSubscription?.cancel();
    _favorites.clear();
    _favoriteMovieIds.clear();
    super.dispose();
  }
}
