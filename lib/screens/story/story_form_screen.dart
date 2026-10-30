// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../utils/app_constants.dart';

// ===== FORMULIR TAMBAH & EDIT CERITA =====
class StoryFormScreen extends StatefulWidget {
  final StoryModel? storyToEdit;

  const StoryFormScreen({super.key, this.storyToEdit});

  @override
  State<StoryFormScreen> createState() => _StoryFormScreenState();
}

class _StoryFormScreenState extends State<StoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _locationController;

  String _selectedCategory = 'Pengalaman Pribadi';

  final List<String> _categoryOptions = [
    'Pengalaman Pribadi',
    'Legenda Urban',
    'Tempat Angker',
    'Misteri',
    'Mitos Daerah',
    'Lainnya',
  ];

  bool get isEditMode => widget.storyToEdit != null;

  @override
  void initState() {
    super.initState();
    final story = widget.storyToEdit;
    _titleController = TextEditingController(text: story?.title ?? '');
    _contentController = TextEditingController(text: story?.content ?? '');
    _locationController = TextEditingController(text: story?.location ?? '');

    if (story != null && _categoryOptions.contains(story.category)) {
      _selectedCategory = story.category;
    } else if (story != null) {
      _selectedCategory = 'Lainnya';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ===== VALIDASI FORMULIR =====
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Judul cerita tidak boleh kosong';
    }
    if (value.trim().length < 5) {
      return 'Judul minimal 5 karakter';
    }
    if (value.trim().length > 100) {
      return 'Judul maksimal 100 karakter';
    }
    return null;
  }

  String? _validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Isi cerita tidak boleh kosong';
    }
    if (value.trim().length < 20) {
      return 'Isi cerita terlalu singkat (minimal 20 karakter)';
    }
    return null;
  }

  // ===== MENYIMPAN CERITA =====
  Future<void> _handleSubmit() async {
    // 1. Validasi formulir input
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);

    final currentUser = auth.userModel;
    final firebaseUser = auth.firebaseUser;

    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi telah berakhir. Silakan login kembali.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authorId = firebaseUser.uid;
    final authorName =
        currentUser?.displayName ?? firebaseUser.displayName ?? 'Pengguna KHW';
    final existingStory = widget.storyToEdit;
    if (existingStory != null && !existingStory.isPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cerita yang sudah ditinjau admin tidak dapat diedit.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    bool success;

    if (isEditMode) {
      // ===== MEMPERBARUI CERITA =====
      final existingStory = widget.storyToEdit!;
      success = await storyProvider.updateStory(
        storyId: existingStory.id,
        authorId: authorId,
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
        location: _locationController.text,
      );
    } else {
      // ===== MENAMBAHKAN CERITA =====
      success = await storyProvider.createStory(
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
        location: _locationController.text,
        authorId: authorId,
        authorName: authorName,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            storyProvider.actionSuccessMessage ??
                (isEditMode
                ? 'Perubahan cerita berhasil disimpan.'
                    : 'Cerita berhasil dikirim! Menunggu moderasi.'),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            storyProvider.errorMessage ?? 'Gagal menyimpan cerita. Coba lagi.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final existingStory = widget.storyToEdit;
    if (existingStory != null && !existingStory.isPending) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Cerita Sudah Ditinjau'),
          backgroundColor: AppColors.surface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.warning,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cerita yang sudah disetujui atau ditolak admin tidak dapat diedit.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Cerita' : 'Tulis Cerita Horor',
        ),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Informasi Moderasi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cerita baru maupun yang diedit otomatis berstatus "pending" dan akan diperiksa oleh admin sebelum tayang.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. Judul Cerita
              const Text(
                'Judul Cerita Horor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                validator: _validateTitle,
                maxLength: 100,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Misal: Misteri Malam Jumat di Asrama Lama',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  counterStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.title,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Kategori Cerita
              const Text(
                'Kategori Cerita',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categoryOptions.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.category,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Lokasi Kejadian (Opsional)
              const Text(
                'Lokasi Kejadian (Opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                maxLength: 60,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Misal: Alas Roban, Jawa Tengah',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  counterStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Isi Cerita Horor
              const Text(
                'Isi Kisah Horor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentController,
                validator: _validateContent,
                maxLines: 12,
                minLines: 6,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Tuliskan pengalaman mistis Anda secara rinci...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Kirim atau Simpan
              SizedBox(
                width: double.infinity,
                child: Consumer<StoryProvider>(
                  builder: (context, storyProvider, _) {
                    final isLoading = storyProvider.isActionLoading;
                    return ElevatedButton.icon(
                      onPressed: isLoading ? null : _handleSubmit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              isEditMode
                                  ? Icons.send_rounded
                                  : Icons.publish_rounded,
                            ),
                      label: Text(
                        isLoading
                            ? 'Menyimpan cerita...'
                            : isEditMode
                            ? 'Simpan Perubahan'
                            : 'Kirim Cerita ke Admin',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
