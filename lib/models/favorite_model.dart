// ===== IMPORT LIBRARY =====
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_constants.dart';
import 'movie_model.dart';

// ===== MODEL DATA FILM FAVORIT =====
class FavoriteModel {
  final String id; // Deterministic ID: {uid}_{movieId}
  final String userId;
  final int movieId;
  final String title;
  final String? posterPath;
  final DateTime createdAt;
  final String? overview;
  final double? voteAverage;
  final String? releaseDate;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.title,
    this.posterPath,
    required this.createdAt,
    this.overview,
    this.voteAverage,
    this.releaseDate,
  });

  // Helper pembentuk ID deterministik: {uid}_{movieId}
  static String generateDocId(String userId, int movieId) {
    return '${userId}_$movieId';
  }

  // Getter poster URL lengkap
  String? get posterUrl {
    if (posterPath == null || posterPath!.trim().isEmpty) return null;
    return '${AppConstants.tmdbImageBaseUrl}$posterPath';
  }

  // Format rating
  String get formattedVote =>
      voteAverage != null ? voteAverage!.toStringAsFixed(1) : '-';

  // Format tahun rilis
  String get releaseYear {
    if (releaseDate == null || releaseDate!.trim().isEmpty) return 'N/A';
    final parts = releaseDate!.split('-');
    return parts.isNotEmpty ? parts[0] : releaseDate!;
  }

  // ===== MEMBACA DATA DARI FIRESTORE =====
  factory FavoriteModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return FavoriteModel.fromMap(data, doc.id);
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map, String docId) {
    // Parsing tanggal createdAt dari Timestamp Firestore
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    // Parsing movieId
    int parsedMovieId = 0;
    final rawMovieId = map['movieId'];
    if (rawMovieId is int) {
      parsedMovieId = rawMovieId;
    } else if (rawMovieId != null) {
      parsedMovieId = int.tryParse(rawMovieId.toString()) ?? 0;
    }

    // Parsing voteAverage
    double? parsedVote;
    final rawVote = map['voteAverage'];
    if (rawVote is num) {
      parsedVote = rawVote.toDouble();
    }

    return FavoriteModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      movieId: parsedMovieId,
      title: map['title'] as String? ?? 'Tanpa Judul',
      posterPath: map['posterPath'] as String?,
      createdAt: parsedDate,
      overview: map['overview'] as String?,
      voteAverage: parsedVote,
      releaseDate: map['releaseDate'] as String?,
    );
  }

  // ===== MENGONVERSI DATA KE FIRESTORE (SERIALISASI) =====
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'movieId': movieId,
      'title': title,
      'posterPath': posterPath,
      'createdAt': Timestamp.fromDate(createdAt),
      'overview': overview,
      'voteAverage': voteAverage,
      'releaseDate': releaseDate,
    };
  }

  // Mengonversi FavoriteModel menjadi MovieModel untuk navigasi detail
  MovieModel toMovieModel() {
    return MovieModel(
      id: movieId,
      title: title,
      overview: overview ?? 'Tidak ada sinopsis tersedia.',
      posterPath: posterPath,
      releaseDate: releaseDate,
      voteAverage: voteAverage ?? 0.0,
      genreIds: const [AppConstants.horrorGenreId],
    );
  }

  @override
  String toString() {
    return 'FavoriteModel(id: $id, userId: $userId, movieId: $movieId, title: $title)';
  }
}
