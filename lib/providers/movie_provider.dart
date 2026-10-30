// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../services/movie_api_service.dart';

// ===== ENUM POLA VIEW STATE (UTS P03/P05) =====
enum MovieViewState { initial, loading, loaded, error, empty }

// ===== PROVIDER FILM TMDB =====
class MovieProvider extends ChangeNotifier {
  final MovieApiService _apiService;

  // ===== STATE DATA =====
  List<MovieModel> _movies = [];
  List<MovieModel> _searchResults = [];
  MovieModel? _selectedMovie;
  String _searchQuery = '';

  // Status ViewState sesuai spesifikasi UTS P03
  MovieViewState _catalogState = MovieViewState.initial;
  MovieViewState _searchState = MovieViewState.initial;
  MovieViewState _detailState = MovieViewState.initial;

  String? _errorMessage;
  String? _searchErrorMessage;
  String? _detailErrorMessage;

  MovieProvider({MovieApiService? apiService})
      : _apiService = apiService ?? MovieApiService() {
    fetchHorrorMovies();
  }

  // ===== GETTER STATE =====
  List<MovieModel> get movies => _movies;
  List<MovieModel> get searchResults => _searchResults;
  MovieModel? get selectedMovie => _selectedMovie;
  String get searchQuery => _searchQuery;

  MovieViewState get catalogState => _catalogState;
  MovieViewState get searchState => _searchState;
  MovieViewState get detailState => _detailState;

  String? get errorMessage => _errorMessage;
  String? get searchErrorMessage => _searchErrorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  bool get isLoadingCatalog => _catalogState == MovieViewState.loading;
  bool get isCatalogEmpty => _catalogState == MovieViewState.empty;
  bool get hasCatalogError => _catalogState == MovieViewState.error;

  bool get isSearching => _searchQuery.isNotEmpty;
  bool get isLoadingSearch => _searchState == MovieViewState.loading;
  bool get isSearchEmpty => _searchState == MovieViewState.empty;

  // ===== MENGAMBIL DAFTAR FILM HOROR =====
  // Menggunakan Future asinkron (Dart Async P01) dengan Dio GET
  Future<void> fetchHorrorMovies({bool isRefresh = false}) async {
    // Jika bukan refresh dan data sudah ada, hindari loading berulang
    if (!isRefresh && _movies.isNotEmpty) return;

    _catalogState = MovieViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _apiService.getHorrorMovies();
      _movies = results;

      if (_movies.isEmpty) {
        _catalogState = MovieViewState.empty;
      } else {
        _catalogState = MovieViewState.loaded;
      }
      _errorMessage = null;
    } catch (e) {
      _catalogState = MovieViewState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  // ===== PENCARIAN FILM =====
  Future<void> searchMovies(String query) async {
    final trimmed = query.trim();
    _searchQuery = trimmed;

    if (trimmed.isEmpty) {
      _searchResults = [];
      _searchState = MovieViewState.initial;
      _searchErrorMessage = null;
      notifyListeners();
      return;
    }

    _searchState = MovieViewState.loading;
    _searchErrorMessage = null;
    notifyListeners();

    try {
      final results = await _apiService.searchMovies(trimmed);
      _searchResults = results;

      if (_searchResults.isEmpty) {
        _searchState = MovieViewState.empty;
      } else {
        _searchState = MovieViewState.loaded;
      }
      _searchErrorMessage = null;
    } catch (e) {
      _searchState = MovieViewState.error;
      _searchErrorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  // Membersihkan pencarian
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _searchState = MovieViewState.initial;
    _searchErrorMessage = null;
    notifyListeners();
  }

  // ===== MENGAMBIL DETAIL FILM =====
  Future<void> fetchMovieDetail(int movieId) async {
    _detailState = MovieViewState.loading;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final detail = await _apiService.getMovieDetail(movieId);
      _selectedMovie = detail;
      _detailState = MovieViewState.loaded;
      _detailErrorMessage = null;
    } catch (e) {
      _detailState = MovieViewState.error;
      _detailErrorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  // Mengatur film yang dipilih langsung dari objek katalog
  void setSelectedMovie(MovieModel movie) {
    _selectedMovie = movie;
    _detailState = MovieViewState.loaded;
    _detailErrorMessage = null;
    notifyListeners();
  }

  // ===== MENANGANI ERROR & RESET =====
  void clearErrors() {
    _errorMessage = null;
    _searchErrorMessage = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Membersihkan state saat provider dihancurkan
    _movies.clear();
    _searchResults.clear();
    super.dispose();
  }
}
