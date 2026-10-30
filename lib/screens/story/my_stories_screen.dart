// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/state_view.dart';
import '../../widgets/story_card.dart';
import 'story_detail_screen.dart';
import 'story_form_screen.dart';

// ===== DAFTAR CERITA SAYA =====
class MyStoriesScreen extends StatefulWidget {
  const MyStoriesScreen({super.key});

  @override
  State<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<MyStoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.firebaseUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        Provider.of<StoryProvider>(
          context,
          listen: false,
        ).initUserStoriesStream(uid);
      }
    });
  }

  // ===== DIALOG KONFIRMASI HAPUS =====
  void _showDeleteDialog(BuildContext context, StoryModel story) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Hapus Cerita?',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus cerita "${story.title}"? Tindakan ini tidak dapat dibatalkan.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
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
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
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
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    provider.errorMessage ??
                                        'Gagal menghapus cerita.',
                                  ),
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

  // ===== MEMBANGUN FILTER STATUS =====
  Widget _buildStatusFilterChips(StoryProvider provider) {
    final filters = [
      {
        'label': 'Semua',
        'value': 'Semua',
        'count': provider.userStories.length,
      },
      {
        'label': 'Menunggu',
        'value': AppConstants.statusPending,
        'count': provider.userPendingCount,
      },
      {
        'label': 'Diterbitkan',
        'value': AppConstants.statusPublished,
        'count': provider.userPublishedCount,
      },
      {
        'label': 'Ditolak',
        'value': AppConstants.statusRejected,
        'count': provider.userRejectedCount,
      },
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final val = item['value'] as String;
          final count = item['count'] as int;
          final isSelected =
              provider.selectedUserStatus.toLowerCase() == val.toLowerCase();

          return ChoiceChip(
            label: Text('${item['label']} ($count)'),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                provider.setUserStatusFilter(val);
              }
            },
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primaryLight : AppColors.divider,
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final stories = storyProvider.filteredUserStories;
    final uid = authProvider.firebaseUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cerita Saya'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            tooltip: 'Tulis Cerita Baru',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoryFormScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Status Moderasi
          _buildStatusFilterChips(storyProvider),
          const Divider(color: AppColors.divider, height: 1),

          // Daftar Cerita Milik Pengguna
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryLight,
              backgroundColor: AppColors.surface,
              onRefresh: () => storyProvider.refreshUserStories(uid),
              child: Builder(
                builder: (context) {
                  // 1. Loading State
                  if (storyProvider.isLoadingUserStories &&
                      storyProvider.userStories.isEmpty) {
                    return const LoadingStateView(
                      message: 'Memuat cerita Anda...',
                    );
                  }

                  // 2. Empty State
                  if (stories.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.auto_stories,
                      title: storyProvider.selectedUserStatus == 'Semua'
                          ? 'Belum Ada Cerita'
                          : 'Tidak Ada Cerita Pada Status Ini',
                      message: storyProvider.selectedUserStatus == 'Semua'
                          ? 'Anda belum pernah mengirim cerita horor. Bagikan kisah mistis pertama Anda sekarang!'
                          : 'Tidak ada cerita dengan status "${storyProvider.selectedUserStatus}".',
                      buttonText: 'Tulis Cerita Baru',
                      onButtonPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StoryFormScreen(),
                          ),
                        );
                      },
                    );
                  }

                  // 3. Loaded State: Daftar Cerita
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      return StoryCard(
                        story: story,
                        showStatus: true,
                        onTap: () {
                          storyProvider.selectStory(story);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoryDetailScreen(story: story),
                            ),
                          );
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StoryFormScreen(storyToEdit: story),
                            ),
                          );
                        },
                        onDelete: () => _showDeleteDialog(context, story),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // Tombol Tambah Cerita
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        tooltip: 'Tulis Cerita Horor',
        child: const Icon(Icons.edit_note, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StoryFormScreen()),
          );
        },
      ),
    );
  }
}
