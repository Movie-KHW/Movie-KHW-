// ===== IMPORT LIBRARY PENGUJIAN =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khw_movie/models/favorite_model.dart';
import 'package:khw_movie/models/movie_model.dart';
import 'package:khw_movie/utils/app_constants.dart';

void main() {
  group('Pengujian Unit - Model Film (MovieModel - Anggota 3)', () {
    test('Deserialisasi JSON Respon TMDB API ke MovieModel', () {
      final jsonResponse = {
        'id': 580489,
        'title': 'Venom: Let There Be Carnage',
        'overview': 'Eddie Brock struggles to adjust to life as the host of the alien symbiote...',
        'poster_path': '/rjkmN1dniUHVYAtwuV3Tji7Fs79.jpg',
        'backdrop_path': '/vI1Y8ikRJjqgyHaCl2MR4856OWi.jpg',
        'release_date': '2021-09-30',
        'vote_average': 7.1,
        'genre_ids': [27, 28, 878],
      };

      final movie = MovieModel.fromJson(jsonResponse);

      expect(movie.id, equals(580489));
      expect(movie.title, equals('Venom: Let There Be Carnage'));
      expect(movie.voteAverage, equals(7.1));
      expect(movie.formattedVote, equals('7.1'));
      expect(movie.releaseYear, equals('2021'));
      expect(movie.genreIds, contains(AppConstants.horrorGenreId));
      expect(
        movie.posterUrl,
        equals('${AppConstants.tmdbImageBaseUrl}/rjkmN1dniUHVYAtwuV3Tji7Fs79.jpg'),
      );
      expect(
        movie.backdropUrl,
        equals('${AppConstants.tmdbBackdropBaseUrl}/vI1Y8ikRJjqgyHaCl2MR4856OWi.jpg'),
      );
    });

    test('Penanganan Safe Parsing Data JSON Kosong atau Tidak Lengkap', () {
      final incompleteJson = <String, dynamic>{
        'id': '12345', // String ID bukan int
        'title': null,
        'overview': null,
        'poster_path': null,
        'vote_average': '8.5', // String vote bukan num
        'genre_ids': null,
      };

      final movie = MovieModel.fromJson(incompleteJson);

      expect(movie.id, equals(12345));
      expect(movie.title, equals('Tanpa Judul'));
      expect(movie.overview, isNotEmpty);
      expect(movie.posterUrl, isNull);
      expect(movie.backdropUrl, isNull);
      expect(movie.voteAverage, equals(8.5));
      expect(movie.releaseYear, equals('N/A'));
      expect(movie.genreIds, isEmpty);
    });

    test('Format Durasi Film (formattedRuntime)', () {
      const movieWithDuration = MovieModel(
        id: 101,
        title: 'Film Horor',
        overview: 'Sinopsis',
        voteAverage: 8.0,
        genreIds: [27],
        runtime: 115, // 1 jam 55 menit
      );

      expect(movieWithDuration.formattedRuntime, equals('1j 55m'));

      const movieShort = MovieModel(
        id: 102,
        title: 'Film Pendek',
        overview: 'Sinopsis',
        voteAverage: 6.5,
        genreIds: [27],
        runtime: 45, // 45 menit
      );

      expect(movieShort.formattedRuntime, equals('45m'));
    });

    test('Serialisasi toMap / toJson dan copyWith MovieModel', () {
      const original = MovieModel(
        id: 1,
        title: 'The Conjuring',
        overview: 'Paranormal investigators Ed and Lorraine Warren...',
        voteAverage: 7.5,
        genreIds: [27, 53],
        releaseDate: '2013-07-19',
      );

      final json = original.toJson();
      expect(json['id'], equals(1));
      expect(json['title'], equals('The Conjuring'));
      expect(json['vote_average'], equals(7.5));

      final copied = original.copyWith(title: 'The Conjuring 2', id: 2);
      expect(copied.id, equals(2));
      expect(copied.title, equals('The Conjuring 2'));
      expect(copied.voteAverage, equals(7.5));
    });
  });

  group('Pengujian Unit - Model Favorit (FavoriteModel - Anggota 3)', () {
    test('Pola ID Dokumen Deterministik {uid}_{movieId}', () {
      final docId = FavoriteModel.generateDocId('user_fathur_001', 580489);
      expect(docId, equals('user_fathur_001_580489'));
    });

    test('Serialisasi toMap dan Deserialisasi fromMap FavoriteModel', () {
      final now = DateTime(2026, 10, 30, 20, 0, 0);
      final favorite = FavoriteModel(
        id: 'user_fathur_001_101',
        userId: 'user_fathur_001',
        movieId: 101,
        title: 'Insidious',
        posterPath: '/path_poster.jpg',
        createdAt: now,
        overview: 'A family looks to prevent evil spirits...',
        voteAverage: 7.2,
        releaseDate: '2010-09-13',
      );

      // Serialisasi
      final map = favorite.toMap();
      expect(map['userId'], equals('user_fathur_001'));
      expect(map['movieId'], equals(101));
      expect(map['title'], equals('Insidious'));
      expect(map['posterPath'], equals('/path_poster.jpg'));
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['voteAverage'], equals(7.2));

      // Deserialisasi
      final restored = FavoriteModel.fromMap(map, 'user_fathur_001_101');
      expect(restored.id, equals('user_fathur_001_101'));
      expect(restored.userId, equals(favorite.userId));
      expect(restored.movieId, equals(favorite.movieId));
      expect(restored.title, equals(favorite.title));
      expect(restored.posterPath, equals(favorite.posterPath));
      expect(restored.voteAverage, equals(7.2));
      expect(restored.formattedVote, equals('7.2'));
      expect(restored.releaseYear, equals('2010'));
    });

    test('Konversi FavoriteModel ke MovieModel untuk Navigasi Detail', () {
      final favorite = FavoriteModel(
        id: 'user_01_99',
        userId: 'user_01',
        movieId: 99,
        title: 'Hereditary',
        posterPath: '/hereditary.jpg',
        createdAt: DateTime.now(),
        overview: 'When Ellen passes away...',
        voteAverage: 7.3,
        releaseDate: '2018-06-07',
      );

      final movie = favorite.toMovieModel();
      expect(movie.id, equals(99));
      expect(movie.title, equals('Hereditary'));
      expect(movie.overview, equals(favorite.overview));
      expect(movie.genreIds, contains(AppConstants.horrorGenreId));
    });
  });

  group('Pengujian Unit - Konstanta TMDB API (AppConstants - Anggota 3)', () {
    test('ID Genre Horor TMDB adalah 27', () {
      expect(AppConstants.horrorGenreId, equals(27));
    });

    test('URL Dasar TMDB dan Gambar Valid', () {
      expect(AppConstants.tmdbBaseUrl, startsWith('https://api.themoviedb.org'));
      expect(AppConstants.tmdbImageBaseUrl, startsWith('https://image.tmdb.org'));
      expect(AppConstants.favoritesCollection, equals('favorites'));
    });
  });
}
