// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/state_view.dart';
import '../../widgets/story_card.dart';
import 'my_stories_screen.dart';
import 'story_detail_screen.dart';
import 'story_form_screen.dart';

// ===== DAFTAR CERITA PUBLIK =====
class StoryListScreen extends StatefulWidget {
  const StoryListScreen({super.key});

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Daftar kategori cerita horor
  final List<String> _categories = [
    'Semua',
    'Pengalaman Pribadi',
    'Legenda Urban',
    'Tempat Angker',
    'Misteri',
    'Mitos Daerah',
    'Lainnya',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===== MEMBANGUN FILTER KATEGORI =====
  Widget _buildCategoryFilters(StoryProvider provider) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = provider.selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                provider.setCategory(cat);
              }
            },
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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

  // ===== MEMBANGUN KOTAK PENCARIAN =====
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari cerita atau lokasi mistis...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
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
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim().toLowerCase();
          });
        },
      ),
    );
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Filter berdasarkan kategori yang dipilih
    var stories = storyProvider.filteredPublicStories;

    // Filter tambahan berdasarkan kata kunci pencarian
    if (_searchQuery.isNotEmpty) {
      stories = stories.where((s) {
        final title = s.title.toLowerCase();
        final content = s.content.toLowerCase();
        final location = s.location?.toLowerCase() ?? '';
        final author = s.authorName.toLowerCase();
        return title.contains(_searchQuery) ||
            content.contains(_searchQuery) ||
            location.contains(_searchQuery) ||
            author.contains(_searchQuery);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Banner Navigasi ke Cerita Saya
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kisah Horor Komunitas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Cerita mistis nyata dari para pengguna',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        // Tombol Cepat Cerita Saya
                        OutlinedButton.icon(
                          onPressed: () {
                            final uid = authProvider.firebaseUser?.uid ?? '';
                            storyProvider.initUserStoriesStream(uid);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyStoriesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bookmark_outline, size: 16),
                          label: const Text('Cerita Saya', style: TextStyle(fontSize: 12)),
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
                  ),

                  // Kotak Pencarian
                  _buildSearchBar(),

                  // Filter Kategori
                  const SizedBox(height: 4),
                  _buildCategoryFilters(storyProvider),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          color: AppColors.primaryLight,
          backgroundColor: AppColors.surface,
          onRefresh: () => storyProvider.refreshPublicStories(),
          child: Builder(
            builder: (context) {
              // 1. Loading State
              if (storyProvider.isLoading && storyProvider.publicStories.isEmpty) {
                return const LoadingStateView(message: 'Memuat kisah horor...');
              }

              // 2. Error State
              if (storyProvider.errorMessage != null && storyProvider.publicStories.isEmpty) {
                return ErrorStateView(
                  errorMessage: storyProvider.errorMessage!,
                  onRetry: () => storyProvider.refreshPublicStories(),
                );
              }

              // 3. Empty State
              if (stories.isEmpty) {
                return EmptyStateView(
                  icon: Icons.nightlight_outlined,
                  title: _searchQuery.isNotEmpty
                      ? 'Cerita Tidak Ditemukan'
                      : 'Belum Ada Cerita Terbit',
                  message: _searchQuery.isNotEmpty
                      ? 'Tidak ada kisah horor yang cocok dengan kata kunci "$_searchQuery".'
                      : 'Belum ada kisah horor yang dipublikasikan dalam kategori ini. Jadilah yang pertama membagikan cerita!',
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

              // 4. Loaded State: Daftar Cerita Publik
              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 80),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return StoryCard(
                    story: story,
                    showStatus: false,
                    onTap: () {
                      storyProvider.selectStory(story);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoryDetailScreen(story: story),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
      // Floating Action Button untuk membuat cerita baru
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'Tulis Cerita',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StoryFormScreen(),
            ),
          );
        },
      ),
    );
  }
}
