// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../utils/app_constants.dart';

// ===== KARTU TAMPILAN CERITA =====
class StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;
  final bool showStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    this.showStatus = false,
    this.onEdit,
    this.onDelete,
  });

  // Format tanggal dalam bahasa Indonesia tanpa dependensi intl
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Warna dan teks badge status moderasi
  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusPublished:
        return AppColors.success;
      case AppConstants.statusRejected:
        return AppColors.error;
      case AppConstants.statusPending:
      default:
        return AppColors.warning;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case AppConstants.statusPublished:
        return 'DITERBITKAN';
      case AppConstants.statusRejected:
        return 'DITOLAK';
      case AppConstants.statusPending:
      default:
        return 'MENUNGGU';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.statusPublished:
        return Icons.check_circle_outline;
      case AppConstants.statusRejected:
        return Icons.cancel_outlined;
      case AppConstants.statusPending:
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(story.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: showStatus && story.isRejected
              ? AppColors.error.withValues(alpha: 0.6)
              : AppColors.divider,
        ),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar sampul cerita jika ada
            if (story.imageUrl != null && story.imageUrl!.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      story.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.background,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 40),
                          ),
                        );
                      },
                    ),
                  ),
                  // Kategori chip di atas gambar
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        story.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Badge status jika ditampilkan
                  if (showStatus)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getStatusIcon(story.status), size: 13, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              _getStatusLabel(story.status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

            // Konten kartu
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jika tidak ada gambar, tampilkan kategori & status di baris teratas
                  if (story.imageUrl == null || story.imageUrl!.isEmpty)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            story.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (showStatus)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getStatusIcon(story.status), size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  _getStatusLabel(story.status),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                  if (story.imageUrl == null || story.imageUrl!.isEmpty)
                    const SizedBox(height: 8),

                  // Judul cerita
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Ringkasan isi cerita
                  Text(
                    story.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  // Catatan moderasi jika cerita ditolak (rejected)
                  if (showStatus && story.isRejected && story.moderationNote != null && story.moderationNote!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Alasan penolakan: ${story.moderationNote}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 10),

                  // Baris informasi penulis, tanggal, lokasi, dan aksi (jika ada)
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          story.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(story.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      if (story.location != null && story.location!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accent),
                        const SizedBox(width: 2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80),
                          child: Text(
                            story.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.accent),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Baris tombol aksi Edit & Hapus untuk cerita milik pengguna
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onEdit != null)
                          TextButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, size: 16, color: AppColors.primaryLight),
                            label: Text(
                              story.isRejected ? 'Edit & Ajukan Ulang' : 'Edit',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            label: const Text(
                              'Hapus',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ],
                    ),
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
