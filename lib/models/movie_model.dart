// ===== IMPORT LIBRARY =====
import '../utils/app_constants.dart';

// ===== MODEL DATA FILM =====
class MovieModel {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final List<int> genreIds;
  final String? tagline;
  final int? runtime;
  final List<String>? genres;

  const MovieModel({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    required this.voteAverage,
    required this.genreIds,
    this.tagline,
    this.runtime,
    this.genres,
  });

  // ===== GETTER BANTUAN TAMPILAN & URL GAMBAR =====

  // Membangun URL poster lengkap berdasarkan dokumentasi resmi TMDB
  String? get posterUrl {
    if (posterPath == null || posterPath!.trim().isEmpty) return null;
    return '${AppConstants.tmdbImageBaseUrl}$posterPath';
  }

  // Membangun URL backdrop lebar lengkap berdasarkan dokumentasi TMDB
  String? get backdropUrl {
    if (backdropPath == null || backdropPath!.trim().isEmpty) return null;
    return '${AppConstants.tmdbBackdropBaseUrl}$backdropPath';
  }

  // Format rating menjadi 1 desimal (contoh: 7.8)
  String get formattedVote => voteAverage.toStringAsFixed(1);

  // Mengambil tahun rilis dari format YYYY-MM-DD
  String get releaseYear {
    if (releaseDate == null || releaseDate!.trim().isEmpty) return 'N/A';
    final parts = releaseDate!.split('-');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0];
    }
    return releaseDate!;
  }

  // Format durasi film dalam jam dan menit
  String? get formattedRuntime {
    if (runtime == null || runtime! <= 0) return null;
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes}m';
  }

  // ===== PARSING JSON =====
  // Deserialisasi data respon JSON dari TMDB API secara aman (safe parsing)
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    // 1. Parsing vote_average (menangani int maupun double)
    double parsedVote = 0.0;
    final rawVote = json['vote_average'];
    if (rawVote is num) {
      parsedVote = rawVote.toDouble();
    } else if (rawVote is String) {
      parsedVote = double.tryParse(rawVote) ?? 0.0;
    }

    // 2. Parsing genre_ids dari array JSON
    List<int> parsedGenreIds = [];
    if (json['genre_ids'] is List) {
      parsedGenreIds = (json['genre_ids'] as List)
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();
    }

    // 3. Parsing daftar nama genre (pada endpoint detail film)
    List<String>? parsedGenres;
    if (json['genres'] is List) {
      parsedGenres = (json['genres'] as List)
          .map((g) => (g is Map && g['name'] != null) ? g['name'].toString() : '')
          .where((name) => name.isNotEmpty)
          .toList();

      // Tambahkan ID genre jika belum ada dari endpoint detail
      if (parsedGenreIds.isEmpty) {
        parsedGenreIds = (json['genres'] as List)
            .map((g) => (g is Map && g['id'] is int) ? g['id'] as int : 0)
            .where((id) => id > 0)
            .toList();
      }
    }

    // 4. Parsing runtime durasi film
    int? parsedRuntime;
    if (json['runtime'] is int) {
      parsedRuntime = json['runtime'] as int;
    } else if (json['runtime'] is String) {
      parsedRuntime = int.tryParse(json['runtime'] as String);
    }

    return MovieModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] as String? ?? 'Tanpa Judul',
      overview: json['overview'] as String? ?? 'Tidak ada sinopsis tersedia.',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: parsedVote,
      genreIds: parsedGenreIds,
      tagline: json['tagline'] as String?,
      runtime: parsedRuntime,
      genres: parsedGenres,
    );
  }

  // Mengonversi objek film ke bentuk Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'release_date': releaseDate,
      'vote_average': voteAverage,
      'genre_ids': genreIds,
      'tagline': tagline,
      'runtime': runtime,
      'genres': genres,
    };
  }

  // Menggandakan objek dengan properti baru
  MovieModel copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? releaseDate,
    double? voteAverage,
    List<int>? genreIds,
    String? tagline,
    int? runtime,
    List<String>? genres,
  }) {
    return MovieModel(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      releaseDate: releaseDate ?? this.releaseDate,
      voteAverage: voteAverage ?? this.voteAverage,
      genreIds: genreIds ?? this.genreIds,
      tagline: tagline ?? this.tagline,
      runtime: runtime ?? this.runtime,
      genres: genres ?? this.genres,
    );
  }

  @override
  String toString() {
    return 'MovieModel(id: $id, title: $title, voteAverage: $voteAverage, releaseDate: $releaseDate)';
  }
}
