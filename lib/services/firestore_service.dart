// ===== IMPORT LIBRARY =====
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import '../utils/app_constants.dart';

// ===== SERVICE FIRESTORE CERITA =====
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Koleksi stories
  CollectionReference<Map<String, dynamic>> get _storiesCollection =>
      _firestore.collection(AppConstants.storiesCollection);

  // ===== MEMBACA DATA CERITA =====

  // Stream daftar cerita yang telah terbit (published) untuk publik
  // Catatan UTS P05: Sorting dilakukan di sisi client (Dart) agar tidak memerlukan composite index Firestore
  Stream<List<StoryModel>> getPublishedStoriesStream() {
    return _storiesCollection
        .where('status', isEqualTo: AppConstants.statusPublished)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Mengambil daftar cerita publik sekali unduh (Future)
  Future<List<StoryModel>> getPublishedStories() async {
    try {
      final querySnapshot = await _storiesCollection
          .where('status', isEqualTo: AppConstants.statusPublished)
          .get();

      final list = querySnapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw Exception('Gagal memuat daftar cerita: $e');
    }
  }

  // Stream daftar cerita milik pengguna tertentu (berdasarkan authorId)
  Stream<List<StoryModel>> getUserStoriesStream(String uid) {
    return _storiesCollection.where('authorId', isEqualTo: uid).snapshots().map(
      (snapshot) {
        final list = snapshot.docs
            .map((doc) => StoryModel.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  // Mengambil daftar cerita milik pengguna (Future)
  Future<List<StoryModel>> getUserStories(String uid) async {
    try {
      final querySnapshot = await _storiesCollection
          .where('authorId', isEqualTo: uid)
          .get();

      final list = querySnapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw Exception('Gagal memuat cerita milik Anda: $e');
    }
  }

  // Mengambil satu cerita berdasarkan ID
  Future<StoryModel?> getStoryById(String storyId) async {
    try {
      final doc = await _storiesCollection.doc(storyId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return StoryModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Gagal memuat detail cerita: $e');
    }
  }

  // Stream detail satu cerita
  Stream<StoryModel?> getStoryStream(String storyId) {
    return _storiesCollection.doc(storyId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return StoryModel.fromFirestore(doc);
    });
  }

  // ===== MENAMBAHKAN CERITA =====
  // Menambahkan cerita baru. Status selalu dipaksa menjadi 'pending'
  String generateStoryId() => _storiesCollection.doc().id;

  Future<String> createStory({
    String? storyId,
    required String title,
    required String content,
    required String category,
    String? location,
    String? imageUrl,
    String? imagePath,
    required String authorId,
    required String authorName,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = storyId == null
          ? _storiesCollection.doc()
          : _storiesCollection.doc(storyId);

      final newStory = StoryModel(
        id: docRef.id,
        title: title.trim(),
        content: content.trim(),
        category: category.trim(),
        location: location?.trim().isNotEmpty == true ? location!.trim() : null,
        imageUrl: imageUrl,
        imagePath: imagePath,
        authorId: authorId,
        authorName: authorName.trim(),
        status: AppConstants.statusPending, // Aturan: cerita baru wajib pending
        moderationNote: null,
        createdAt: now,
        updatedAt: null,
        reviewedBy: null,
        reviewedAt: null,
      );

      await docRef.set(newStory.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Gagal menambahkan cerita baru: $e');
    }
  }

  // ===== MEMPERBARUI CERITA =====
  // Memperbarui cerita oleh penulisnya
  // Cerita yang diedit (termasuk rejected) otomatis berstatus 'pending' kembali untuk diajukan ulang
  Future<void> updateStory({
    required String storyId,
    required String authorId,
    required String title,
    required String content,
    required String category,
    String? location,
    String? imageUrl,
    String? imagePath,
  }) async {
    try {
      final doc = await _storiesCollection.doc(storyId).get();
      if (!doc.exists) {
        throw Exception('Cerita tidak ditemukan.');
      }

      final existingData = doc.data()!;
      // Validasi kepemilikan cerita
      if (existingData['authorId'] != authorId) {
        throw Exception(
          'Akses ditolak: Anda tidak memiliki izin untuk mengedit cerita ini.',
        );
      }

      final updateData = <String, dynamic>{
        'title': title.trim(),
        'content': content.trim(),
        'category': category.trim(),
        'location': location?.trim().isNotEmpty == true
            ? location!.trim()
            : null,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'status': AppConstants.statusPending, // Reset ke pending saat diedit
        'moderationNote':
            null, // Bersihkan catatan penolakan lama saat diajukan ulang
        'updatedAt': Timestamp.now(),
      };

      await _storiesCollection.doc(storyId).update(updateData);
    } catch (e) {
      throw Exception('Gagal memperbarui cerita: $e');
    }
  }

  // ===== MENGHAPUS CERITA =====
  // Menghapus cerita dari Firestore dengan verifikasi hak milik
  Future<void> deleteStory({
    required String storyId,
    required String authorId,
    bool isAdmin = false,
  }) async {
    try {
      final doc = await _storiesCollection.doc(storyId).get();
      if (!doc.exists) {
        return; // Dokumen sudah tidak ada
      }

      final existingData = doc.data()!;
      if (!isAdmin && existingData['authorId'] != authorId) {
        throw Exception(
          'Akses ditolak: Anda tidak memiliki izin untuk menghapus cerita ini.',
        );
      }

      await _storiesCollection.doc(storyId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus cerita: $e');
    }
  }

  // ===== INTEGRASI MODERASI ADMIN (ANGGOTA 4) =====
  // Mengambil semua cerita untuk moderasi (disediakan untuk Anggota 4)
  Stream<List<StoryModel>> getAllStoriesForModeration() {
    return _storiesCollection.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<StoryModel>> getAllPendingStories() {
    return _storiesCollection
        .where('status', isEqualTo: AppConstants.statusPending)
        .snapshots()
        .map((snapshot) {
          final stories = snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .toList();
          stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return stories;
        });
  }

  // Memperbarui status moderasi oleh admin
  Future<void> updateModerationStatus({
    required String storyId,
    required String status,
    String? moderationNote,
    required String reviewedBy,
  }) async {
    await moderateStory(
      storyId: storyId,
      status: status,
      moderationNote: moderationNote,
      reviewedBy: reviewedBy,
    );
  }

  Future<void> moderateStory({
    required String storyId,
    required String status,
    String? moderationNote,
    required String reviewedBy,
  }) async {
    if (status != AppConstants.statusPublished &&
        status != AppConstants.statusRejected) {
      throw ArgumentError.value(
        status,
        'status',
        'Status moderasi tidak valid.',
      );
    }
    if (status == AppConstants.statusRejected &&
        (moderationNote == null || moderationNote.trim().isEmpty)) {
      throw ArgumentError('Catatan wajib diisi untuk menolak cerita.');
    }

    try {
      final storyRef = _storiesCollection.doc(storyId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(storyRef);
        if (!snapshot.exists) {
          throw Exception('Cerita tidak ditemukan.');
        }
        if (snapshot.data()?['status'] != AppConstants.statusPending) {
          throw Exception('Cerita ini sudah ditinjau sebelumnya.');
        }

        final now = Timestamp.now();
        transaction.update(storyRef, {
          'status': status,
          'moderationNote': status == AppConstants.statusRejected
              ? moderationNote!.trim()
              : null,
          'reviewedBy': reviewedBy,
          'reviewedAt': now,
          'updatedAt': now,
        });
      });
    } catch (e) {
      throw Exception('Gagal memperbarui status moderasi: $e');
    }
  }
}
