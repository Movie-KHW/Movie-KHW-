// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../utils/app_constants.dart';
import 'story_form_screen.dart';

// ===== DETAIL CERITA HOROR =====
class StoryDetailScreen extends StatelessWidget {
  final StoryModel story;

  const StoryDetailScreen({super.key, required this.story});

  // Format tanggal dalam bahasa Indonesia
  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ===== DIALOG KONFIRMASI HAPUS =====
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: AppColors.error),
              SizedBox(width: 8),
              Text('Hapus Cerita?', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus cerita "${story.title}"? Tindakan ini tidak dapat dibatalkan.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            Consumer<StoryProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  onPressed: provider.isActionLoading
                      ? null
                      : () async {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final success = await provider.deleteStory(
                            storyId: story.id,
                            authorId: auth.firebaseUser?.uid ?? '',
                            imagePath: story.imagePath,
                            isAdmin: auth.isAdmin,
                          );

                          if (context.mounted) {
                            Navigator.pop(dialogContext); // Tutup dialog
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cerita berhasil dihapus.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              Navigator.pop(context); // Kembali ke halaman sebelumnya
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.errorMessage ?? 'Gagal menghapus cerita.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  child: provider.isActionLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Hapus'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ===== MEMBANGUN BANNER STATUS MODERASI =====
  Widget _buildModerationStatusBanner(BuildContext context, bool isAuthor) {
    if (!isAuthor && story.isPublished) return const SizedBox.shrink();

    Color bgColor;
    Color borderColor;
    IconData icon;
    String title;
    String desc;

    if (story.isPending) {
      bgColor = AppColors.warning.withValues(alpha: 0.12);
      borderColor = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
      title = 'Status: Menunggu Moderasi';
      desc =
          'Cerita ini telah dikirim dan sedang menunggu peninjauan oleh admin sebelum dipublikasikan.';
    } else if (story.isRejected) {
      bgColor = AppColors.error.withValues(alpha: 0.12);
      borderColor = AppColors.error;
      icon = Icons.cancel_outlined;
      title = 'Status: Cerita Ditolak';
      desc = story.moderationNote != null && story.moderationNote!.isNotEmpty
          ? 'Alasan penolakan: ${story.moderationNote}\nSilakan perbaiki cerita ini dan ajukan ulang.'
          : 'Cerita ini belum memenuhi pedoman komunitas. Silakan perbaiki dan ajukan ulang.';
    } else {
      bgColor = AppColors.success.withValues(alpha: 0.12);
      borderColor = AppColors.success;
      icon = Icons.check_circle_outline;
      title = 'Status: Telah Diterbitkan';
      desc = 'Cerita ini dapat dibaca oleh seluruh komunitas KHW Movie.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: borderColor.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.firebaseUser?.uid;
    final bool isAuthor = currentUserId != null && currentUserId == story.authorId;
    final bool canManage = isAuthor || authProvider.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Cerita'),
        backgroundColor: AppColors.surface,
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryFormScreen(storyToEdit: story),
                    ),
                  );
                } else if (value == 'delete') {
                  _showDeleteDialog(context);
                }
              },
              itemBuilder: (context) => [
                if (isAuthor)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 18, color: AppColors.primaryLight),
                        const SizedBox(width: 10),
                        Text(
                          story.isRejected ? 'Edit & Ajukan Ulang' : 'Edit Cerita',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Hapus Cerita', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Status Moderasi (jika pengguna adalah penulis atau admin)
            if (isAuthor || authProvider.isAdmin)
              _buildModerationStatusBanner(context, isAuthor),

            // Foto Sampul Cerita (jika tersedia)
            if (story.imageUrl != null && story.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      story.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surface,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori & Lokasi
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          story.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (story.location != null && story.location!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.location_on, size: 16, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            story.location!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Judul Cerita
                  Text(
                    story.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Informasi Penulis & Tanggal
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            story.authorName.isNotEmpty
                                ? story.authorName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.authorName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Ditulis pada ${_formatDate(story.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (story.updatedAt != null)
                          Text(
                            '(Diedit)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 14),

                  // Isi Cerita Horor
                  SelectableText(
                    story.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.8,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Tombol Tindakan untuk Penulis
                  if (isAuthor) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StoryFormScreen(storyToEdit: story),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(
                              story.isRejected ? 'Edit & Ajukan Ulang' : 'Edit Cerita',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteDialog(context),
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          label: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
