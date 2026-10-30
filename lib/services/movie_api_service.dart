// ===== IMPORT LIBRARY =====
import 'package:dio/dio.dart';
import '../models/movie_model.dart';
import '../utils/app_constants.dart';

// ===== SERVICE API TMDB MENGGUNAKAN DIO =====
class MovieApiService {
  final Dio _dio;
  final String _apiKey;

  // ===== KONFIGURASI DIO =====
  MovieApiService({
    Dio? dio,
    String? apiKey,
  })  : _apiKey = apiKey ??
            const String.fromEnvironment(
              'TMDB_API_KEY',
              defaultValue: AppConstants.defaultTmdbApiKey,
            ),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.tmdbBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            );

  // ===== MENGAMBIL DAFTAR FILM =====
  // Mengambil daftar film horor menggunakan endpoint /discover/movie dengan genre ID 27
  Future<List<MovieModel>> getHorrorMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/discover/movie',
        queryParameters: {
          'api_key': _apiKey,
          'with_genres': AppConstants.horrorGenreId,
          'sort_by': 'popularity.desc',
          'include_adult': false,
          'include_video': false,
          'page': page,
          'language': 'id-ID',
        },
      );

      return _parseMovieList(response.data);
    } on DioException catch (dioError) {
      throw Exception(_handleDioError(dioError));
    } catch (e) {
      throw Exception('Gagal memproses daftar film horor: $e');
    }
  }

  // ===== MENGAMBIL DETAIL FILM =====
  // Mengambil informasi lengkap satu film berdasarkan movie_id menggunakan endpoint /movie/{movie_id}
  Future<MovieModel> getMovieDetail(int movieId) async {
    try {
      final response = await _dio.get(
        '/movie/$movieId',
        queryParameters: {
          'api_key': _apiKey,
          'append_to_response': 'credits,similar',
          'language': 'id-ID',
        },
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Format data respon detail film tidak valid');
      }

      return MovieModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (dioError) {
      throw Exception(_handleDioError(dioError));
    } catch (e) {
      throw Exception('Gagal memuat detail film: $e');
    }
  }

  // ===== PENCARIAN FILM =====
  // Mencari film berdasarkan kata kunci query menggunakan endpoint /search/movie
  Future<List<MovieModel>> searchMovies(String query, {int page = 1}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get(
        '/search/movie',
        queryParameters: {
          'api_key': _apiKey,
          'query': trimmedQuery,
          'include_adult': false,
          'page': page,
          'language': 'id-ID',
        },
      );

      return _parseMovieList(response.data);
    } on DioException catch (dioError) {
      throw Exception(_handleDioError(dioError));
    } catch (e) {
      throw Exception('Gagal mencari film "$query": $e');
    }
  }

  // ===== PARSING DAFTAR HASIL TMDB =====
  List<MovieModel> _parseMovieList(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return [];
    }

    final rawResults = data['results'];
    if (rawResults is! List) {
      return [];
    }

    return rawResults
        .whereType<Map<String, dynamic>>()
        .map((json) => MovieModel.fromJson(json))
        .toList();
  }

  // ===== MENANGANI ERROR DIO =====
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Waktu koneksi ke server TMDB habis (timeout). Periksa jaringan internet Anda.';

      case DioExceptionType.connectionError:
        return 'Gagal terhubung ke server TMDB. Periksa koneksi internet Anda.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Kunci API TMDB (api_key) tidak valid atau belum diizinkan oleh TMDB.';
        } else if (statusCode == 404) {
          return 'Data film tidak ditemukan pada server TMDB.';
        } else if (statusCode == 429) {
          return 'Terlalu banyak permintaan ke server TMDB. Silakan tunggu beberapa saat.';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Server TMDB sedang mengalami kendala teknis (kode $statusCode). Silakan coba lagi nanti.';
        }
        return 'Server TMDB mengembalikan respon error (kode $statusCode).';

      case DioExceptionType.cancel:
        return 'Permintaan ke server TMDB dibatalkan.';

      case DioExceptionType.badCertificate:
        return 'Sertifikat keamanan SSL server tidak valid.';

      case DioExceptionType.unknown:
      default:
        return 'Terjadi gangguan saat memuat data dari TMDB: ${error.message ?? 'Kesalahan tidak diketahui'}';
    }
  }
}
