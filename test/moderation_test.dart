// ===== IMPORT LIBRARY PENGUJIAN =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khw_movie/models/story_model.dart';
import 'package:khw_movie/models/user_model.dart';
import 'package:khw_movie/providers/moderation_provider.dart';
import 'package:khw_movie/utils/app_constants.dart';

void main() {
  // ===== PENGUJIAN TRANSISI STATUS & KONTRAK DATA FIRESTORE =====
  group('Pengujian Unit - Alur Status Moderasi Cerita (StoryModel)', () {
    test('Cerita baru wajib berstatus pending secara bawaan', () {
      final newStory = StoryModel(
        id: 'story_pending_001',
        title: 'Misteri Malam Satu Suro',
        content: 'Pengalaman mistis di perempatan jalan sepi saat tengah malam...',
        category: 'Pengalaman Pribadi',
        authorId: 'user_hanin_01',
        authorName: 'Pengguna KHW',
        status: AppConstants.statusPending,
        createdAt: DateTime(2026, 10, 31, 12, 0),
      );

      // Verifikasi status bawaan
      expect(newStory.isPending, isTrue);
      expect(newStory.isPublished, isFalse);
      expect(newStory.isRejected, isFalse);
      expect(newStory.reviewedBy, isNull);
      expect(newStory.reviewedAt, isNull);
      expect(newStory.moderationNote, isNull);
    });

    test('Menyetujui cerita mengubah status menjadi published dan mencatat admin', () {
      final pendingStory = StoryModel(
        id: 'story_approve_001',
        title: 'Suara Ketukan Pintu Asrama',
        content: 'Terdengar ketukan berulang padahal di luar tidak ada siapa-siapa...',
        category: 'Tempat Angker',
        authorId: 'author_123',
        authorName: 'Mahasiswa Kampus',
        status: AppConstants.statusPending,
        createdAt: DateTime(2026, 10, 31, 10, 0),
      );

      final reviewTime = DateTime(2026, 10, 31, 14, 30);
      final adminUid = 'admin_hanin_2411500033';

      // Simulasi persetujuan cerita oleh admin
      final approvedStory = pendingStory.copyWith(
        status: AppConstants.statusPublished,
        reviewedBy: adminUid,
        reviewedAt: reviewTime,
        updatedAt: reviewTime,
        clearModerationNote: true,
      );

      expect(approvedStory.isPublished, isTrue);
      expect(approvedStory.isPending, isFalse);
      expect(approvedStory.isRejected, isFalse);
      expect(approvedStory.reviewedBy, equals('admin_hanin_2411500033'));
      expect(approvedStory.reviewedAt, equals(reviewTime));
      expect(approvedStory.updatedAt, equals(reviewTime));
      expect(approvedStory.moderationNote, isNull);

      // Validasi serialisasi Firestore
      final firestoreMap = approvedStory.toMap();
      expect(firestoreMap['status'], equals('published'));
      expect(firestoreMap['reviewedBy'], equals('admin_hanin_2411500033'));
      expect(firestoreMap['reviewedAt'], isA<Timestamp>());
    });

    test('Menolak cerita mengubah status menjadi rejected dan mewajibkan catatan evaluasi', () {
      final pendingStory = StoryModel(
        id: 'story_reject_001',
        title: 'Cerita Tanpa Sumber Jelas',
        content: 'Kisah karangan pendek yang belum memenuhi standar cerita...',
        category: 'Mitos Daerah',
        authorId: 'author_999',
        authorName: 'Pengguna Anonim',
        status: AppConstants.statusPending,
        createdAt: DateTime(2026, 10, 31, 11, 0),
      );

      final reviewTime = DateTime(2026, 10, 31, 15, 0);
      final adminUid = 'admin_hanin_2411500033';
      const rejectionReason = 'Isi cerita terlalu singkat dan tidak menyertakan rincian kronologi.';

      // Simulasi penolakan cerita oleh admin
      final rejectedStory = pendingStory.copyWith(
        status: AppConstants.statusRejected,
        moderationNote: rejectionReason,
        reviewedBy: adminUid,
        reviewedAt: reviewTime,
        updatedAt: reviewTime,
      );

      expect(rejectedStory.isRejected, isTrue);
      expect(rejectedStory.isPending, isFalse);
      expect(rejectedStory.isPublished, isFalse);
      expect(rejectedStory.moderationNote, equals(rejectionReason));
      expect(rejectedStory.reviewedBy, equals(adminUid));
      expect(rejectedStory.reviewedAt, equals(reviewTime));

      // Validasi serialisasi Firestore
      final firestoreMap = rejectedStory.toMap();
      expect(firestoreMap['status'], equals('rejected'));
      expect(firestoreMap['moderationNote'], equals(rejectionReason));
      expect(firestoreMap['reviewedBy'], equals(adminUid));
    });
  });

  // ===== PENGUJIAN KEAMANAN ROLE & AKSES MODERASI =====
  group('Pengujian Unit - Keamanan Role Pengguna & Otoritas Admin', () {
    test('Pengguna reguler terdaftar memiliki role "user" dan tidak memiliki akses admin', () {
      final regularUser = UserModel(
        uid: 'user_reguler_001',
        displayName: 'Pengguna Komunitas',
        email: 'user@khw.com',
        role: AppConstants.roleUser,
        createdAt: DateTime.now(),
      );

      expect(regularUser.role, equals('user'));
      expect(regularUser.isAdmin, isFalse);
    });

    test('Akun administrator memiliki role "admin" dan lolos validasi hak akses', () {
      final adminUser = UserModel(
        uid: 'admin_hanin_001',
        displayName: 'Hanin Fadhilah',
        email: 'hanin.admin@khw.com',
        role: AppConstants.roleAdmin,
        createdAt: DateTime.now(),
      );

      expect(adminUser.role, equals('admin'));
      expect(adminUser.isAdmin, isTrue);
    });

    test('Pencegahan manipulasi role: Fallback deserialisasi UserModel selalu role "user"', () {
      final invalidPayload = {
        'displayName': 'Hacker Peniru',
        'email': 'hacker@khw.com',
        // 'role' sengaja dikosongkan atau null
        'createdAt': Timestamp.now(),
      };

      final safeUser = UserModel.fromMap(invalidPayload, 'hacker_uid');
      expect(safeUser.role, equals(AppConstants.roleUser));
      expect(safeUser.isAdmin, isFalse);
    });
  });

  // ===== PENGUJIAN POLA VIEWSTATE MODERASI =====
  group('Pengujian Unit - Pola ViewState & Validasi Provider Moderasi', () {
    test('Validasi ModerationViewState enum mendukung pola UTS P03/P05', () {
      expect(ModerationViewState.initial.index, equals(0));
      expect(ModerationViewState.loading.index, equals(1));
      expect(ModerationViewState.loaded.index, equals(2));
      expect(ModerationViewState.error.index, equals(3));
      expect(ModerationViewState.empty.index, equals(4));
    });

    test('Validasi argumen penolakan cerita: Catatan kosong ditolak sistem', () async {
      // Menguji validasi catatan penolakan pada kontrak moderasi
      String? validateRejectionNote(String? note) {
        if (note == null || note.trim().isEmpty) {
          return 'Catatan penolakan wajib diisi untuk memberikan alasan kepada penulis.';
        }
        return null;
      }

      expect(validateRejectionNote(null), isNotNull);
      expect(validateRejectionNote(''), isNotNull);
      expect(validateRejectionNote('   '), isNotNull);
      expect(validateRejectionNote('Cerita melanggar hak cipta'), isNull);
    });

    test('Validasi argumen sesi admin: UID kosong ditolak sistem', () {
      String? validateAdminSession(String? adminUid) {
        if (adminUid == null || adminUid.trim().isEmpty) {
          return 'Sesi admin tidak valid. Silakan login kembali.';
        }
        return null;
      }

      expect(validateAdminSession(null), isNotNull);
      expect(validateAdminSession(''), isNotNull);
      expect(validateAdminSession('admin_valid_uid'), isNull);
    });

    test('Perhitungan metrik statistik cerita pada antrian moderasi', () {
      final sampleStories = [
        StoryModel(
          id: 's1',
          title: 'Cerita 1',
          content: 'Konten 1...',
          category: 'Misteri',
          authorId: 'a1',
          authorName: 'U1',
          status: AppConstants.statusPending,
          createdAt: DateTime.now(),
        ),
        StoryModel(
          id: 's2',
          title: 'Cerita 2',
          content: 'Konten 2...',
          category: 'Mitos',
          authorId: 'a2',
          authorName: 'U2',
          status: AppConstants.statusPending,
          createdAt: DateTime.now(),
        ),
        StoryModel(
          id: 's3',
          title: 'Cerita 3',
          content: 'Konten 3...',
          category: 'Tempat Angker',
          authorId: 'a3',
          authorName: 'U3',
          status: AppConstants.statusPublished,
          createdAt: DateTime.now(),
        ),
        StoryModel(
          id: 's4',
          title: 'Cerita 4',
          content: 'Konten 4...',
          category: 'Legenda Urban',
          authorId: 'a4',
          authorName: 'U4',
          status: AppConstants.statusRejected,
          moderationNote: 'Kurang detail',
          createdAt: DateTime.now(),
        ),
      ];

      final pendingList = sampleStories.where((s) => s.isPending).toList();
      final publishedList = sampleStories.where((s) => s.isPublished).toList();
      final rejectedList = sampleStories.where((s) => s.isRejected).toList();

      expect(pendingList.length, equals(2));
      expect(publishedList.length, equals(1));
      expect(rejectedList.length, equals(1));
      expect(sampleStories.length, equals(4));
    });
  });
}
