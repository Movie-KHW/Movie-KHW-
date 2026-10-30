// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/movie_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/state_view.dart';
import 'favorites_screen.dart';
import 'movie_detail_screen.dart';

// ===== DAFTAR KATALOG FILM HOROR =====
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inisialisasi stream favorit pengguna saat layar pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.firebaseUser?.uid;
      Provider.of<FavoriteProvider>(context, listen: false).initFavoritesStream(uid);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===== MEMBANGUN KOTAK PENCARIAN =====
  Widget _buildSearchBar(MovieProvider movieProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        textInputAction: TextInputAction.search,
        onSubmitted: (query) {
          movieProvider.searchMovies(query);
        },
        decoration: InputDecoration(
          hintText: 'Cari judul film horor (misal: The Conjuring)...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    movieProvider.clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryLight),
          ),
        ),
      ),
    );
  }

  // ===== HEADER NAVIGASI KE FAVORIT =====
  Widget _buildHeaderBar(FavoriteProvider favoriteProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Katalog Film Horor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Eksplorasi sinema horor dunia via TMDB API',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          // Tombol Layar Favorit
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoritesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.favorite, size: 16, color: AppColors.primaryLight),
            label: Text(
              favoriteProvider.favoritesCount > 0
                  ? 'Favorit (${favoriteProvider.favoritesCount})'
                  : 'Favorit',
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryLight,
              side: const BorderSide(color: AppColors.primaryLight),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== TOGGLE FAVORIT DENGAN FEEDBACK =====
  Future<void> _handleToggleFavorite({
    required FavoriteProvider favoriteProvider,
    required String? userId,
    required MovieModel movie,
  }) async {
    final wasFavorite = favoriteProvider.isFavorite(movie.id);
    final success = await favoriteProvider.toggleFavorite(
      userId: userId,
      movie: movie,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite
                ? '"${movie.title}" dihapus dari favorit.'
                : '"${movie.title}" ditambahkan ke film favorit!',
          ),
          backgroundColor: wasFavorite ? AppColors.surfaceLight : AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favoriteProvider.errorMessage ?? 'Gagal memperbarui film favorit.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final movieProvider = Provider.of<MovieProvider>(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.firebaseUser?.uid;

    final isSearching = movieProvider.isSearching;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderBar(favoriteProvider),
                  _buildSearchBar(movieProvider),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            if (isSearching) {
              await movieProvider.searchMovies(movieProvider.searchQuery);
            } else {
              await movieProvider.fetchHorrorMovies(isRefresh: true);
            }
          },
          child: Builder(
            builder: (context) {
              // KONDISI 1: PENCARIAN AKTIF
              if (isSearching) {
                // Loading State Pencarian
                if (movieProvider.isLoadingSearch) {
                  return const LoadingStateView(message: 'Mencari film di TMDB...');
                }

                // Error State Pencarian
                if (movieProvider.searchErrorMessage != null) {
                  return ErrorStateView(
                    errorMessage: movieProvider.searchErrorMessage!,
                    onRetry: () => movieProvider.searchMovies(movieProvider.searchQuery),
                  );
                }

                // Empty State Pencarian
                if (movieProvider.isSearchEmpty || movieProvider.searchResults.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: 'Film Tidak Ditemukan',
                    message:
                        'Tidak ditemukan judul film yang cocok dengan "${movieProvider.searchQuery}". Coba gunakan kata kunci lainnya.',
                    buttonText: 'Hapus Pencarian',
                    onButtonPressed: () {
                      _searchController.clear();
                      movieProvider.clearSearch();
                    },
                  );
                }

                // Loaded State Pencarian
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  itemCount: movieProvider.searchResults.length,
                  itemBuilder: (context, index) {
                    final movie = movieProvider.searchResults[index];
                    final isFav = favoriteProvider.isFavorite(movie.id);

                    return MovieCard(
                      movie: movie,
                      isFavorite: isFav,
                      onTap: () {
                        movieProvider.setSelectedMovie(movie);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovieDetailScreen(movieId: movie.id),
                          ),
                        );
                      },
                      onFavoriteToggle: () {
                        _handleToggleFavorite(
                          favoriteProvider: favoriteProvider,
                          userId: currentUserId,
                          movie: movie,
                        );
                      },
                    );
                  },
                );
              }

              // KONDISI 2: KATALOG UTAMA FILM HOROR
              // Loading State Katalog
              if (movieProvider.isLoadingCatalog && movieProvider.movies.isEmpty) {
                return const LoadingStateView(message: 'Menghubungkan ke TMDB API...');
              }

              // Error State Katalog
              if (movieProvider.hasCatalogError && movieProvider.movies.isEmpty) {
                return ErrorStateView(
                  title: 'Gagal Memuat Film',
                  errorMessage: movieProvider.errorMessage ?? 'Tidak dapat terhubung ke TMDB.',
                  onRetry: () => movieProvider.fetchHorrorMovies(isRefresh: true),
                );
              }

              // Empty State Katalog
              if (movieProvider.isCatalogEmpty || movieProvider.movies.isEmpty) {
                return EmptyStateView(
                  icon: Icons.movie_outlined,
                  title: 'Katalog Belum Tersedia',
                  message: 'Tidak ada daftar film yang dapat ditampilkan saat ini.',
                  buttonText: 'Muat Ulang',
                  onButtonPressed: () => movieProvider.fetchHorrorMovies(isRefresh: true),
                );
              }

              // Loaded State Katalog
              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                itemCount: movieProvider.movies.length,
                itemBuilder: (context, index) {
                  final movie = movieProvider.movies[index];
                  final isFav = favoriteProvider.isFavorite(movie.id);

                  return MovieCard(
                    movie: movie,
                    isFavorite: isFav,
                    onTap: () {
                      movieProvider.setSelectedMovie(movie);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailScreen(movieId: movie.id),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      _handleToggleFavorite(
                        favoriteProvider: favoriteProvider,
                        userId: currentUserId,
                        movie: movie,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
