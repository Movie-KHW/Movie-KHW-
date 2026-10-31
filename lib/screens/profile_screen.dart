// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import 'moderation/moderation_screen.dart';

// ===== TAMPILAN PROFIL PENGGUNA =====
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ===== DIALOG KONFIRMASI KELUAR =====
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.logout, color: AppColors.primaryLight),
              SizedBox(width: 8),
              Text(
                'Konfirmasi Keluar',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun KHW Movie?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Tutup dialog
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                // AuthGate akan otomatis mengarahkan ke LoginScreen
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  // Format tanggal sederhana tanpa dependensi eksternal intl
  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final firebaseUser = authProvider.firebaseUser;

    final displayName =
        user?.displayName ?? firebaseUser?.displayName ?? 'Pengguna KHW';
    final email = user?.email ?? firebaseUser?.email ?? '-';
    final role = user?.role ?? AppConstants.roleUser;
    final isAdmin = user?.isAdmin ?? false;
    final createdAtStr = user != null ? _formatDate(user.createdAt) : '-';

    // Inisial nama pengguna untuk avatar
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Segarkan Profil',
            onPressed: () async {
              await authProvider.reloadUserProfile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil berhasil diperbarui.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Avatar & Nama
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Badge Role (User / Admin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AppColors.primaryDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAdmin
                            ? AppColors.primaryLight
                            : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAdmin ? Icons.admin_panel_settings : Icons.person,
                          size: 16,
                          color: isAdmin
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Role: ${role.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: isAdmin
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Informasi Detail Akun
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.fingerprint,
                      color: AppColors.primaryLight,
                    ),
                    title: const Text(
                      'User ID (UID)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      firebaseUser?.uid ?? '-',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: AppColors.primaryLight,
                    ),
                    title: const Text(
                      'Bergabung Sejak',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      createdAtStr,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primaryLight,
                    ),
                    title: const Text(
                      'Status Autentikasi',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: const Text(
                      'Terverifikasi via Firebase Auth',
                      style: TextStyle(color: AppColors.success, fontSize: 14),
                    ),
                  ),
                  if (isAdmin) ...[
                    const Divider(color: AppColors.divider, height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.admin_panel_settings,
                        color: AppColors.accent,
                      ),
                      title: const Text(
                        'Panel Moderasi Cerita',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Kelola dan tinjau cerita pending dari komunitas',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ModerationScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout),
                label: const Text('KELUAR DARI AKUN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
