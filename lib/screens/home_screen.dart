// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_constants.dart';
import 'moderation/moderation_screen.dart';
import 'movies/movie_list_screen.dart';
import 'profile_screen.dart';
import 'story/story_list_screen.dart';

// ===== TAMPILAN BERANDA UTAMA =====
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Indeks tab aktif pada navigasi bawah (BottomNavigationBar)
  int _currentIndex = 0;

  // ===== TAMPILAN DASHBOARD BERANDA =====
  Widget _buildHomeDashboard(AuthProvider authProvider) {
    final user = authProvider.userModel;
    final displayName = user?.displayName ?? 'Pengguna KHW';
    final isAdmin = user?.isAdmin ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Sambutan Pengguna
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang,',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? AppColors.primary
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAdmin ? 'ROLE: ADMIN' : 'ROLE: USER',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.account_circle,
                    size: 40,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 3; // Pindah ke tab profil
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ringkasan Navigasi Fitur KHW Movie
          const Text(
            'Eksplorasi Fitur KHW Movie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Menu Cepat: Cerita Horor Komunitas
          _buildFeatureCard(
            title: 'Cerita Horor Komunitas',
            subtitle: 'Baca kisah mistis nyata & kirim cerita horormu.',
            icon: Icons.auto_stories,
            accentColor: AppColors.primaryLight,
            onTap: () => setState(() => _currentIndex = 1),
          ),
          const SizedBox(height: 12),

          // Menu Cepat: Katalog Film TMDB
          _buildFeatureCard(
            title: 'Katalog & Pencarian Film',
            subtitle: 'Temukan film horor terbaik dunia via TMDB API.',
            icon: Icons.movie,
            accentColor: AppColors.accent,
            onTap: () => setState(() => _currentIndex = 2),
          ),
          const SizedBox(height: 12),

          // Menu Cepat: Profil Pengguna
          _buildFeatureCard(
            title: 'Profil & Akun Pengguna',
            subtitle: 'Kelola identitas, role akun, dan sesi login.',
            icon: Icons.person_pin,
            accentColor: Colors.blueAccent,
            onTap: () => setState(() => _currentIndex = 3),
          ),
        ],
      ),
    );
  }

  // Widget Kartu Navigasi Fitur
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    final pages = isAdmin
        ? const [
            ModerationScreen(),
            StoryListScreen(),
            MovieListScreen(),
            ProfileScreen(),
          ]
        : [
            _buildHomeDashboard(authProvider),
            const StoryListScreen(),
            const MovieListScreen(),
            const ProfileScreen(),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.nightlight_round,
              color: AppColors.primaryLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _currentIndex == 0
                  ? (isAdmin ? 'Moderasi Admin' : AppConstants.appName)
                  : _currentIndex == 1
                  ? 'Cerita Horor'
                  : _currentIndex == 2
                  ? 'Katalog Film'
                  : 'Profil Akun',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.home_outlined,
            ),
            activeIcon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.home),
            label: isAdmin ? 'Moderasi' : 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories_outlined),
            activeIcon: Icon(Icons.auto_stories),
            label: 'Cerita',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.movie_outlined),
            activeIcon: Icon(Icons.movie),
            label: 'Film',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
