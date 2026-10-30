// ===== IMPORT LIBRARY =====
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../utils/app_constants.dart';
import '../../widgets/image_picker_field.dart';

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
  XFile? _selectedImageFile;
  bool _removeExistingImage = false;

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
    final authorName = currentUser?.displayName ??
        firebaseUser.displayName ??
        'Pengguna KHW';

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
        newImageFile: _selectedImageFile,
        removeCurrentImage: _removeExistingImage,
        existingImageUrl: _removeExistingImage ? null : existingStory.imageUrl,
        existingImagePath: _removeExistingImage ? null : existingStory.imagePath,
      );
    } else {
      // ===== MENAMBAHKAN CERITA =====
      success = await storyProvider.createStory(
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
        location: _locationController.text,
        imageFile: _selectedImageFile,
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
                    ? 'Cerita berhasil diajukan ulang!'
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
    final storyProvider = Provider.of<StoryProvider>(context);
    final existingStory = widget.storyToEdit;
    final isRejected = existingStory?.isRejected ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditMode
              ? (isRejected ? 'Perbaiki & Ajukan Ulang' : 'Edit Cerita')
              : 'Tulis Cerita Horor',
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
              // Banner Alasan Penolakan (khusus cerita yang ditolak)
              if (isRejected && existingStory?.moderationNote != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Cerita Ditolak Oleh Admin',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Catatan admin: "${existingStory!.moderationNote}"',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Silakan sesuaikan isi cerita Anda sesuai catatan di atas, kemudian simpan untuk mengajukan kembali ke moderasi.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. Judul Cerita
              const Text(
                'Judul Cerita Horor',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                validator: _validateTitle,
                maxLength: 100,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Misal: Misteri Malam Jumat di Asrama Lama',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  counterStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.title, color: AppColors.textSecondary),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categoryOptions.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: const TextStyle(color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
                dropdownColor: AppColors.surface,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category, color: AppColors.textSecondary),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                maxLength: 60,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Misal: Alas Roban, Jawa Tengah',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  counterStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Foto Sampul Cerita (Firebase Storage)
              ImagePickerField(
                selectedFile: _selectedImageFile,
                existingImageUrl: _removeExistingImage ? null : existingStory?.imageUrl,
                onImageSelected: (file) {
                  setState(() {
                    _selectedImageFile = file;
                    _removeExistingImage = false;
                  });
                },
                onImageRemoved: () {
                  setState(() {
                    _selectedImageFile = null;
                    _removeExistingImage = true;
                  });
                },
              ),
              const SizedBox(height: 20),

              // 5. Isi Cerita Horor
              const Text(
                'Isi Kisah Horor',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentController,
                validator: _validateContent,
                maxLines: 12,
                minLines: 6,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Tuliskan pengalaman mistis Anda secara rinci...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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

              // Tombol Kirim / Ajukan Ulang
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: storyProvider.isActionLoading ? null : _handleSubmit,
                  icon: storyProvider.isActionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(isEditMode ? Icons.send_rounded : Icons.publish_rounded),
                  label: Text(
                    storyProvider.isActionLoading
                        ? 'Menyimpan & Mengunggah...'
                        : isEditMode
                            ? (isRejected ? 'Ajukan Ulang Cerita' : 'Simpan Perubahan')
                            : 'Kirim Cerita ke Admin',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
