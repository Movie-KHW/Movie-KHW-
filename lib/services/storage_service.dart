// ===== IMPORT LIBRARY =====
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// ===== SERVICE FIREBASE STORAGE =====
class StorageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  // Ukuran maksimum foto yang diperbolehkan (5 MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  // Ekstensi file yang didukung
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  StorageService({FirebaseStorage? storage, ImagePicker? picker})
    : _storage = storage ?? FirebaseStorage.instance,
      _picker = picker ?? ImagePicker();

  // ===== MEMILIH FOTO DARI GALERI =====
  Future<XFile?> pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 70,
      );
      return pickedFile;
    } catch (e) {
      throw Exception('Gagal memilih foto dari galeri: $e');
    }
  }

  // ===== MEMILIH FOTO DARI KAMERA =====
  Future<XFile?> pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 70,
      );
      return pickedFile;
    } catch (e) {
      throw Exception('Gagal mengambil foto dari kamera: $e');
    }
  }

  // ===== VALIDASI UKURAN DAN FORMAT FOTO =====
  Future<String?> validateImageFile(XFile file) async {
    // 1. Validasi ekstensi format file
    final name = file.name.toLowerCase();
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1) {
      return 'Format file tidak dikenali. Gunakan file JPG, PNG, atau WEBP.';
    }
    final extension = name.substring(dotIndex + 1);
    if (!allowedExtensions.contains(extension)) {
      return 'Format file tidak didukung (.$extension). Hanya file JPG, JPEG, PNG, dan WEBP yang diizinkan.';
    }

    // 2. Validasi ukuran file
    try {
      final bytes = await file.length();
      if (bytes > maxFileSizeBytes) {
        final sizeMb = (bytes / (1024 * 1024)).toStringAsFixed(2);
        return 'Ukuran foto terlalu besar ($sizeMb MB). Maksimal yang diperbolehkan adalah 5 MB.';
      }
    } catch (e) {
      debugPrint('Gagal memeriksa ukuran file: $e');
    }

    return null;
  }

  // ===== MENGUNGGAH FOTO =====
  // Pola penyimpanan: story_images/{uid}/{storyId}/foto.jpg
  Future<Map<String, String>> uploadStoryImage({
    required XFile file,
    required String uid,
    required String storyId,
  }) async {
    try {
      // Dapatkan ekstensi file
      final name = file.name.toLowerCase();
      final dotIndex = name.lastIndexOf('.');
      final extension = (dotIndex != -1) ? name.substring(dotIndex + 1) : 'jpg';

      // Jalur penyimpanan sesuai ketentuan: story_images/{uid}/{storyId}/foto.{ext}
      final storagePath = 'story_images/$uid/$storyId/foto.$extension';
      final ref = _storage.ref().child(storagePath);

      final metadata = SettableMetadata(
        contentType: 'image/$extension',
        customMetadata: {
          'uploadedBy': uid,
          'storyId': storyId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file dengan penanganan multi-platform (web vs native)
      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        uploadTask = ref.putData(bytes, metadata);
      } else {
        final ioFile = File(file.path);
        uploadTask = ref.putFile(ioFile, metadata);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return {'imageUrl': downloadUrl, 'imagePath': storagePath};
    } on FirebaseException catch (e) {
      throw Exception(
        'Gagal mengunggah foto ke Cloud Storage: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan saat upload foto: $e');
    }
  }

  // ===== MENGHAPUS FOTO =====
  // Menghapus foto dari Cloud Storage berdasarkan path yang tersimpan
  Future<void> deleteStoryImage(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return;
    }

    try {
      final ref = _storage.ref().child(imagePath);
      await ref.delete();
    } on FirebaseException catch (e) {
      // Jika file memang sudah tidak ada (object-not-found), abaikan tanpa melempar error
      if (e.code == 'object-not-found') {
        debugPrint(
          'Foto di storage tidak ditemukan (sudah terhapus): $imagePath',
        );
        return;
      }
      debugPrint(
        'Peringatan: Gagal menghapus foto lama dari Storage: ${e.message}',
      );
    } catch (e) {
      debugPrint('Kesalahan menghapus foto storage: $e');
    }
  }
}
