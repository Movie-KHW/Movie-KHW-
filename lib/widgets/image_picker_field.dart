// ===== IMPORT LIBRARY =====
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';

// ===== WIDGET PEMILIHAN FOTO CERITA =====
class ImagePickerField extends StatelessWidget {
  final XFile? selectedFile;
  final String? existingImageUrl;
  final Function(XFile file) onImageSelected;
  final VoidCallback onImageRemoved;
  final StorageService? storageService;

  const ImagePickerField({
    super.key,
    required this.selectedFile,
    this.existingImageUrl,
    required this.onImageSelected,
    required this.onImageRemoved,
    this.storageService,
  });

  // ===== MEMILIH SUMBER FOTO (MODAL BOTTOM SHEET) =====
  void _showSourceSelectionSheet(BuildContext context) {
    final service = storageService ?? StorageService();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Foto Cerita',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Maksimal 5 MB • Format JPG, PNG, atau WEBP',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primaryLight),
                  title: const Text('Pilih dari Galeri', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    try {
                      final picked = await service.pickImageFromGallery();
                      if (picked != null) {
                        final error = await service.validateImageFile(picked);
                        if (error != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                          return;
                        }
                        onImageSelected(picked);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.accent),
                  title: const Text('Ambil dari Kamera', style: TextStyle(color: AppColors.textPrimary)),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    try {
                      final picked = await service.pickImageFromCamera();
                      if (picked != null) {
                        final error = await service.validateImageFile(picked);
                        if (error != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                          return;
                        }
                        onImageSelected(picked);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== MEMBANGUN TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    final bool hasImage = selectedFile != null ||
        (existingImageUrl != null && existingImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Foto Sampul Cerita (Opsional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (hasImage)
              TextButton.icon(
                onPressed: onImageRemoved,
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                label: const Text(
                  'Hapus Foto',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Wadah preview foto atau tombol pemilih
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasImage ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.divider,
              width: 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // Tampilkan file lokal baru jika ada, atau URL lama
                    if (selectedFile != null)
                      kIsWeb
                          ? Image.network(
                              selectedFile!.path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(selectedFile!.path),
                              fit: BoxFit.cover,
                            )
                    else if (existingImageUrl != null && existingImageUrl!.isNotEmpty)
                      Image.network(
                        existingImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, size: 40, color: AppColors.textMuted),
                        ),
                      ),

                    // Overlay gradien untuk tombol ganti foto
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSourceSelectionSheet(context),
                        icon: const Icon(Icons.photo_camera, size: 16),
                        label: const Text('Ganti Foto', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.75),
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: () => _showSourceSelectionSheet(context),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 44,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sentuh untuk memilih foto',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Format JPG, PNG, WEBP (Maksimal 5 MB)',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
