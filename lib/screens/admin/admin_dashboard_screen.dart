import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../utils/app_constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StoryProvider>().initModerationStreams();
      }
    });
  }

  Future<String?> _askForRejectionNote() async {
    final controller = TextEditingController();
    String? validationError;
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Tolak Cerita',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            onChanged: (_) {
              if (validationError != null) {
                setDialogState(() => validationError = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Catatan untuk penulis',
              hintText: 'Jelaskan bagian yang perlu diperbaiki',
              errorText: validationError,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  setDialogState(
                    () => validationError = 'Catatan penolakan wajib diisi.',
                  );
                } else {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('Tolak Cerita'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return note;
  }

  Future<void> _moderateStory(
    StoryModel story, {
    required String status,
    String? note,
  }) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null || uid.isEmpty) {
      _showMessage(
        'Sesi admin tidak ditemukan. Silakan login kembali.',
        isError: true,
      );
      return;
    }

    final success = await context.read<StoryProvider>().moderateStory(
      storyId: story.id,
      status: status,
      moderationNote: note,
      reviewedBy: uid,
    );
    if (!mounted) return;

    final provider = context.read<StoryProvider>();
    _showMessage(
      success
          ? (provider.actionSuccessMessage ?? 'Moderasi berhasil.')
          : (provider.errorMessage ?? 'Moderasi gagal. Silakan coba lagi.'),
      isError: !success,
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
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

  Widget _buildPendingStoryCard(
    BuildContext context,
    StoryModel story,
    bool isActionLoading,
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
          ),
        ),
        subtitle: Text(
          '${story.authorName} • ${story.category}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (story.imageUrl != null && story.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                story.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      'Foto tidak dapat dimuat',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              story.content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          if (story.location != null && story.location!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lokasi: ${story.location}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isActionLoading
                      ? null
                      : () async {
                          final note = await _askForRejectionNote();
                          if (note != null && mounted) {
                            await _moderateStory(
                              story,
                              status: AppConstants.statusRejected,
                              note: note,
                            );
                          }
                        },
                  icon: const Icon(Icons.close),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isActionLoading
                      ? null
                      : () => _moderateStory(
                          story,
                          status: AppConstants.statusPublished,
                        ),
                  icon: const Icon(Icons.check),
                  label: const Text('Setujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryProvider>(
      builder: (context, provider, _) {
        final pendingStories = provider.pendingModerationStories;

        return Scaffold(
          backgroundColor: AppColors.background,
          body:
              provider.isModerationLoading && provider.moderationStories.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryLight,
                  ),
                )
              : provider.errorMessage != null &&
                    provider.moderationStories.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: provider.retryModerationStreams,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Dashboard Moderasi',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Text(
                        'Tinjau cerita kiriman pengguna sebelum diterbitkan.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildStatCard(
                            'Menunggu',
                            provider.moderationPendingCount,
                            AppColors.warning,
                            Icons.hourglass_top,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'Terbit',
                            provider.moderationPublishedCount,
                            AppColors.success,
                            Icons.check_circle_outline,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'Ditolak',
                            provider.moderationRejectedCount,
                            AppColors.error,
                            Icons.cancel_outlined,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Antrian Cerita (${pendingStories.length})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (pendingStories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 36,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.task_alt,
                              color: AppColors.success,
                              size: 44,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tidak ada cerita yang menunggu verifikasi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else
                      ...pendingStories.map(
                        (story) => _buildPendingStoryCard(
                          context,
                          story,
                          provider.isActionLoading,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
