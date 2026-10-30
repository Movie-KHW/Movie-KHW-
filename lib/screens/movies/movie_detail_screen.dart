// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/movie_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/state_view.dart';

// ===== DETAIL FILM HOROR TMDB =====
class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  final MovieModel? initialMovie;

  const MovieDetailScreen({
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Ambil detail lengkap dari TMDB API saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MovieProvider>(context, listen: false)
          .fetchMovieDetail(widget.movieId);
    });
  }

  // Format tanggal rilis
  String _formatReleaseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'Tanggal rilis tidak diketahui';
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final movieProvider = Provider.of<MovieProvider>(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.firebaseUser?.uid;

    final movie = movieProvider.selectedMovie ?? widget.initialMovie;
    final isFav = favoriteProvider.isFavorite(widget.movieId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Builder(
        builder: (context) {
          // 1. Loading State jika belum ada data awal sama sekali
          if (movieProvider.detailState == MovieViewState.loading && movie == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(backgroundColor: AppColors.surface),
              body: const LoadingStateView(message: 'Memuat informasi detail film dari TMDB...'),
            );
          }

          // 2. Error State jika gagal dan tidak ada data awal
          if (movieProvider.detailState == MovieViewState.error && movie == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(backgroundColor: AppColors.surface),
              body: ErrorStateView(
                title: 'Gagal Memuat Detail',
                errorMessage: movieProvider.detailErrorMessage ?? 'Terjadi kesalahan pada TMDB API.',
                onRetry: () => movieProvider.fetchMovieDetail(widget.movieId),
              ),
            );
          }

          if (movie == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(backgroundColor: AppColors.surface),
              body: const EmptyStateView(
                title: 'Data Tidak Ditemukan',
                message: 'Informasi film tidak ditemukan di server TMDB.',
              ),
            );
          }

          // 3. Loaded State: Tampilan Detail Sinematik
          return CustomScrollView(
            slivers: [
              // Sliver AppBar dengan Backdrop Gambar TMDB
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.surface,
                actions: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.primaryLight : AppColors.textPrimary,
                    ),
                    tooltip: isFav ? 'Hapus dari Favorit' : 'Simpan ke Favorit',
                    onPressed: () async {
                      final wasFavorite = isFav;
                      final success = await favoriteProvider.toggleFavorite(
                        userId: currentUserId,
                        movie: movie,
                      );

                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                wasFavorite
                                    ? '"${movie.title}" dihapus dari daftar favorit.'
                                    : '"${movie.title}" berhasil disimpan ke favorit!',
                              ),
                              backgroundColor: wasFavorite
                                  ? AppColors.surfaceLight
                                  : AppColors.success,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                favoriteProvider.errorMessage ??
                                    'Gagal memperbarui favorit.',
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gambar Backdrop TMDB
                      if (movie.backdropUrl != null)
                        Image.network(
                          movie.backdropUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.surfaceLight,
                            child: const Center(
                              child: Icon(Icons.movie, size: 64, color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else if (movie.posterUrl != null)
                        Image.network(
                          movie.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.surfaceLight,
                          ),
                        )
                      else
                        Container(color: AppColors.surfaceLight),

                      // Gradient Overlay Atas dan Bawah
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.9),
                              AppColors.background,
                            ],
                            stops: const [0.0, 0.4, 0.85, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Konten Detail Film
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Film: Poster Kecil + Informasi Utama
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Poster Film dengan Elevasi
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 100,
                              height: 150,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: movie.posterUrl != null
                                  ? Image.network(
                                      movie.posterUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.movie, color: AppColors.textMuted),
                                    )
                                  : const Icon(Icons.movie, color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Judul, Tagline, dan Info Singkat
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                if (movie.tagline != null && movie.tagline!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '"${movie.tagline}"',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),

                                // Badge Rating Bintang
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.amber.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            movie.formattedVote,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber,
                                            ),
                                          ),
                                          const Text(
                                            ' / 10',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (movie.formattedRuntime != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        movie.formattedRuntime!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Daftar Badge Genre
                      if (movie.genres != null && movie.genres!.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: movie.genres!.map((g) {
                            final isHorror = g.toLowerCase().contains('horror') ||
                                g.toLowerCase().contains('horor');
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isHorror ? AppColors.primaryDark : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isHorror ? AppColors.primaryLight : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                g,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isHorror ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Tanggal Rilis Lengkap
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Rilis: ${_formatReleaseDate(movie.releaseDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Text(
                              'TMDB Genre #27',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sinopsis Lengkap
                      const Text(
                        'Sinopsis Cerita',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        movie.overview.isNotEmpty
                            ? movie.overview
                            : 'Tidak ada deskripsi sinopsis yang tersedia untuk film ini.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.7,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Tombol Tambah/Hapus Favorit Lebar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final wasFavorite = isFav;
                            final success = await favoriteProvider.toggleFavorite(
                              userId: currentUserId,
                              movie: movie,
                            );

                            if (context.mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      wasFavorite
                                          ? 'Dihapus dari film favorit.'
                                          : 'Berhasil ditambahkan ke favorit!',
                                    ),
                                    backgroundColor: wasFavorite
                                        ? AppColors.surfaceLight
                                        : AppColors.success,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                          ),
                          label: Text(
                            isFav ? 'Hapus dari Daftar Favorit' : 'Simpan ke Film Favorit',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFav ? AppColors.surfaceLight : AppColors.primary,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isFav ? AppColors.primaryLight : Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
