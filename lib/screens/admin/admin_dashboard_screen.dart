// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import '../moderation/moderation_screen.dart';

// ===== DASHBOARD ADMIN / MODERASI =====
// Re-export dan integrasi ke ModerationScreen utama (Anggota 4 - Hanin Fadhilah)
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModerationScreen();
  }
}
