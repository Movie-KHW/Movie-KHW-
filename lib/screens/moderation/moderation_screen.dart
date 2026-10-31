// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/moderation_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/state_view.dart';

// ===== PANEL MODERASI ADMIN (ANGGOTA 4 - HANIN FADHILAH) =====
class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Format tanggal dan jam ramah pengguna
  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute WIB';
  }

  // ===== DIALOG PENOLAKAN DENGAN CATATAN =====
  Future<String?> _showRejectionDialog(BuildContext context, StoryModel story) async {
    final textController = TextEditingController();
    String? validationMessage;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.error),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tolak Cerita Horor',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Judul: "${story.title}"',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Alasan / Catatan Evaluasi Penolakan (Wajib):',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: textController,
                autofocus: true,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Contoh: Cerita mengandung unsur plagiarisme / melanggar norma komunitas...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  errorText: validationMessage,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                onChanged: (_) {
                  if (validationMessage != null) {
                    setDialogState(() => validationMessage = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, null),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final note = textController.text.trim();
                if (note.isEmpty) {
                  setDialogState(() {
                    validationMessage = 'Catatan penolakan wajib diisi untuk penulis!';
                  });
                } else {
                  Navigator.pop(dialogCtx, note);
                }
              },
              child: const Text('Tolak Cerita'),
            ),
          ],
        ),
      ),
    );

    textController.dispose();
    return result;
  }

  // ===== KONFIRMASI PERSETUJUAN =====
  Future<bool> _showApprovalConfirmDialog(BuildContext context, StoryModel story) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.success),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Setujui Cerita?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Cerita "${story.title}" karya ${story.authorName} akan diterbitkan secara publik untuk seluruh pengguna KHW Movie.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Ya, Terbitkan'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ===== PRATINJAU FOTO & DETAIL =====
  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Gagal memuat gambar resolusi penuh',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan pesan snackbar
  void _showNotification(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===== WIDGET KARTU STATISTIK =====
  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== KARTU CERITA PENDING DENGAN AKSI MODERASI =====
  Widget _buildPendingCard(
    BuildContext context,
    StoryModel story,
    ModerationProvider moderationProvider,
    String adminUid,
  ) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: AppColors.primaryLight,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          story.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    story.category,
                    style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Oleh ${story.authorName}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Dikirim: ${_formatDateTime(story.createdAt)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: AppColors.divider),
          const SizedBox(height: 6),

          // Pratinjau Foto Lampiran (jika ada)
          if (story.imageUrl != null && story.imageUrl!.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _showImageDialog(context, story.imageUrl!, story.title),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      story.imageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: AppColors.background,
                        child: const Center(
                          child: Text(
                            'Foto tidak dapat dimuat',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Perbesar Foto', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Informasi Lokasi Kejadian (jika ada)
          if (story.location != null && story.location!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.accent, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Lokasi: ${story.location}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Isi Lengkap Cerita Horor
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: SelectableText(
              story.content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Aksi: Tolak & Setujui
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: moderationProvider.isActionLoading
                      ? null
                      : () async {
                          final note = await _showRejectionDialog(context, story);
                          if (note != null && context.mounted) {
                            final success = await moderationProvider.rejectStory(
                              storyId: story.id,
                              adminUid: adminUid,
                              rejectionNote: note,
                            );
                            if (context.mounted) {
                              _showNotification(
                                context,
                                success
                                    ? (moderationProvider.actionSuccessMessage ?? 'Cerita ditolak.')
                                    : (moderationProvider.errorMessage ?? 'Gagal menolak cerita.'),
                                isError: !success,
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: moderationProvider.isActionLoading
                      ? null
                      : () async {
                          final confirm = await _showApprovalConfirmDialog(context, story);
                          if (confirm && context.mounted) {
                            final success = await moderationProvider.approveStory(
                              storyId: story.id,
                              adminUid: adminUid,
                            );
                            if (context.mounted) {
                              _showNotification(
                                context,
                                success
                                    ? (moderationProvider.actionSuccessMessage ?? 'Cerita disetujui.')
                                    : (moderationProvider.errorMessage ?? 'Gagal menyetujui cerita.'),
                                isError: !success,
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Setujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== KARTU RIWAYAT CERITA (TERBIT ATAU DITOLAK) =====
  Widget _buildHistoryCard(StoryModel story, {required bool isPublished}) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPublished
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPublished ? Icons.check_circle : Icons.cancel,
                  color: isPublished ? AppColors.success : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isPublished ? 'STATUS: DITERBITKAN' : 'STATUS: DITOLAK',
                  style: TextStyle(
                    color: isPublished ? AppColors.success : AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  story.reviewedAt != null ? _formatDateTime(story.reviewedAt!) : '-',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              story.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Penulis: ${story.authorName} • Kategori: ${story.category}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            if (!isPublished && story.moderationNote != null && story.moderationNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Penolakan:',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      story.moderationNote!,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            if (story.reviewedBy != null && story.reviewedBy!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Ditinjau oleh Admin: ${story.reviewedBy}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== MEMERIKSA ROLE ADMIN & MEMBANGUN TAMPILAN ADMIN =====
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final isAdmin = user?.isAdmin ?? false;
    final adminUid = authProvider.firebaseUser?.uid ?? '';

    // ===== VALIDASI AKSES KEAMANAN ROLE =====
    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Akses Dibatasi'),
          backgroundColor: AppColors.surface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad, color: AppColors.error, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Akses Ditolak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Panel ini hanya dapat diakses oleh akun dengan role "admin" yang terdaftar dan diverifikasi pada Cloud Firestore.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali ke Menu Utama'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<ModerationProvider>(
      builder: (context, modProvider, _) {
        final pendingList = modProvider.pendingStories;
        final publishedList = modProvider.publishedStories;
        final rejectedList = modProvider.rejectedStories;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: AppColors.accent, size: 20),
                SizedBox(width: 8),
                Text('Panel Moderasi Cerita'),
              ],
            ),
            backgroundColor: AppColors.surface,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                tooltip: 'Segarkan Data',
                onPressed: () => modProvider.retry(),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryLight,
              labelColor: AppColors.primaryLight,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: 'Pending (${pendingList.length})'),
                Tab(text: 'Terbit (${publishedList.length})'),
                Tab(text: 'Ditolak (${rejectedList.length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Ringkasan Kartu Statistik
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _buildStatCard(
                      title: 'Menunggu',
                      count: modProvider.pendingCount,
                      color: AppColors.warning,
                      icon: Icons.hourglass_top_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      title: 'Disetujui',
                      count: modProvider.publishedCount,
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      title: 'Ditolak',
                      count: modProvider.rejectedCount,
                      color: AppColors.error,
                      icon: Icons.cancel_outlined,
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),

              // TabBarView dengan status ViewState (Loading / Loaded / Empty / Error)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Antrian Cerita Pending
                    Builder(
                      builder: (context) {
                        if (modProvider.isLoading && pendingList.isEmpty) {
                          return const LoadingStateView(message: 'Memuat antrian moderasi...');
                        }
                        if (modProvider.isError && pendingList.isEmpty) {
                          return ErrorStateView(
                            errorMessage: modProvider.errorMessage ?? 'Gagal memuat data.',
                            onRetry: () => modProvider.retry(),
                          );
                        }
                        if (pendingList.isEmpty) {
                          return const EmptyStateView(
                            icon: Icons.task_alt,
                            title: 'Antrian Kosong',
                            message: 'Semua cerita dari komunitas telah selesai dimoderasi.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          itemCount: pendingList.length,
                          itemBuilder: (context, index) {
                            return _buildPendingCard(
                              context,
                              pendingList[index],
                              modProvider,
                              adminUid,
                            );
                          },
                        );
                      },
                    ),

                    // Tab 2: Riwayat Cerita Diterbitkan
                    Builder(
                      builder: (context) {
                        if (publishedList.isEmpty) {
                          return const EmptyStateView(
                            icon: Icons.check_circle_outline,
                            title: 'Belum Ada Cerita Terbit',
                            message: 'Belum ada cerita yang disetujui dalam sistem.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          itemCount: publishedList.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(publishedList[index], isPublished: true);
                          },
                        );
                      },
                    ),

                    // Tab 3: Riwayat Cerita Ditolak
                    Builder(
                      builder: (context) {
                        if (rejectedList.isEmpty) {
                          return const EmptyStateView(
                            icon: Icons.cancel_outlined,
                            title: 'Belum Ada Cerita Ditolak',
                            message: 'Tidak ada cerita yang ditolak oleh admin.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          itemCount: rejectedList.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(rejectedList[index], isPublished: false);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
