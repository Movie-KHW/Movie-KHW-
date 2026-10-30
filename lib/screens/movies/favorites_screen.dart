// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/favorite_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/state_view.dart';
import 'movie_detail_screen.dart';

// ===== DAFTAR FILM FAVORIT PENGGUNA =====
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  // ===== DIALOG KONFIRMASI HAPUS FAVORIT =====
  void _showRemoveFavoriteDialog(
    BuildContext context,
    FavoriteProvider favoriteProvider,
    String? userId,
    FavoriteModel favorite,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.error),
              SizedBox(width: 8),
              Text('Hapus Favorit?', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${favorite.title}" dari daftar favorit?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Tutup dialog
                final success = await favoriteProvider.removeFavorite(
                  userId: userId,
                  movieId: favorite.movieId,
                );

                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${favorite.title}" dihapus dari favorit.'),
                        backgroundColor: AppColors.surfaceLight,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          favoriteProvider.errorMessage ?? 'Gagal menghapus favorit.',
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // ===== MEMBANGUN KARTU FAVORIT =====
  Widget _buildFavoriteItem({
    required BuildContext context,
    required FavoriteModel favorite,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                // 1. Poster Film
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 65,
                    height: 95,
                    child: favorite.posterUrl != null
                        ? Image.network(
                            favorite.posterUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.surfaceLight,
                              child: const Icon(Icons.movie, color: AppColors.textMuted),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.movie, color: AppColors.textMuted),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // 2. Info Judul dan Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            favorite.formattedVote,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  Tahun ${favorite.releaseYear}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tersimpan di Cloud Firestore',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryLight.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Tombol Hapus Favorit
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  tooltip: 'Hapus dari Favorit',
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.firebaseUser?.uid;

    final favorites = favoriteProvider.favorites;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.favorite, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: 8),
            Text(
              favorites.isNotEmpty
                  ? 'Film Favorit (${favorites.length})'
                  : 'Film Favorit',
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
      ),
      body: Builder(
        builder: (context) {
          // 1. Loading State
          if (favoriteProvider.isLoading && favorites.isEmpty) {
            return const LoadingStateView(message: 'Memuat daftar film favorit...');
          }

          // 2. Error State
          if (favoriteProvider.errorMessage != null && favorites.isEmpty) {
            return ErrorStateView(
              errorMessage: favoriteProvider.errorMessage!,
              onRetry: () => favoriteProvider.initFavoritesStream(currentUserId),
            );
          }

          // 3. Empty State
          if (favorites.isEmpty) {
            return EmptyStateView(
              icon: Icons.favorite_border,
              title: 'Belum Ada Film Favorit',
              message:
                  'Anda belum menandai film horor sebagai favorit. Jelajahi katalog dan tekan ikon hati pada film yang Anda sukai!',
              buttonText: 'Jelajahi Katalog',
              onButtonPressed: () => Navigator.pop(context),
            );
          }

          // 4. Loaded State: Daftar Film Favorit
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];
              return _buildFavoriteItem(
                context: context,
                favorite: item,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailScreen(
                        movieId: item.movieId,
                        initialMovie: item.toMovieModel(),
                      ),
                    ),
                  );
                },
                onRemove: () {
                  _showRemoveFavoriteDialog(
                    context,
                    favoriteProvider,
                    currentUserId,
                    item,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
