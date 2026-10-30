// ===== IMPORT LIBRARY =====
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ===== SERVICE FIREBASE STORAGE =====
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  // Menghapus foto lama dari Cloud Storage berdasarkan path yang tersimpan.
  Future<void> deleteStoryImage(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return;
    }

    try {
      await _storage.ref().child(imagePath).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }
      debugPrint('Gagal menghapus foto lama dari Storage: ${e.message}');
    } catch (e) {
      debugPrint('Kesalahan menghapus foto Storage: $e');
    }
  }
}
