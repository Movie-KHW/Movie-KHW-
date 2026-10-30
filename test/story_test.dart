// ===== IMPORT LIBRARY PENGUJIAN =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khw_movie/models/story_model.dart';
import 'package:khw_movie/services/storage_service.dart';
import 'package:khw_movie/utils/app_constants.dart';
import 'package:khw_movie/utils/validators.dart';

void main() {
  group('Pengujian Unit - Validasi Formulir Cerita (Validators - Anggota 2)', () {
    test('Validasi Judul Cerita Horor', () {
      expect(Validators.validateStoryTitle(null), isNotNull);
      expect(Validators.validateStoryTitle(''), isNotNull);
      expect(Validators.validateStoryTitle('Abc'), isNotNull); // Kurang dari 5 karakter
      expect(
        Validators.validateStoryTitle('Misteri Rumah Tua Kenteng'),
        isNull,
      ); // Valid
    });

    test('Validasi Isi Cerita Horor', () {
      expect(Validators.validateStoryContent(null), isNotNull);
      expect(Validators.validateStoryContent(''), isNotNull);
      expect(Validators.validateStoryContent('Pendek sekali'), isNotNull); // Kurang dari 20 karakter
      expect(
        Validators.validateStoryContent(
          'Pada suatu malam yang gelap di puncak bukit terpencil...',
        ),
        isNull,
      ); // Valid
    });
  });

  group('Pengujian Unit - Model Cerita (StoryModel - Anggota 2)', () {
    test('Serialisasi toMap dan Deserialisasi fromMap StoryModel', () {
      final now = DateTime(2026, 10, 30, 19, 0, 0);
      final story = StoryModel(
        id: 'story_uts_002',
        title: 'Misteri Alas Roban',
        content: 'Perjalanan malam melewati jalur Alas Roban yang penuh kabut mistis...',
        category: 'Tempat Angker',
        location: 'Batang, Jawa Tengah',
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/khw-movie.appspot.com/foto.jpg',
        imagePath: 'story_images/uid_123/story_uts_002/foto.jpg',
        authorId: 'user_002_duwi',
        authorName: 'Duwi Galu Gandimi',
        status: AppConstants.statusPending,
        moderationNote: null,
        createdAt: now,
        updatedAt: null,
        reviewedBy: null,
        reviewedAt: null,
      );

      // Verifikasi getter
      expect(story.isPending, isTrue);
      expect(story.isPublished, isFalse);
      expect(story.isRejected, isFalse);

      // Serialisasi
      final map = story.toMap();
      expect(map['title'], equals('Misteri Alas Roban'));
      expect(map['category'], equals('Tempat Angker'));
      expect(map['authorId'], equals('user_002_duwi'));
      expect(map['authorName'], equals('Duwi Galu Gandimi'));
      expect(map['status'], equals(AppConstants.statusPending));
      expect(map['createdAt'], isA<Timestamp>());

      // Deserialisasi
      final restored = StoryModel.fromMap(map, 'story_uts_002');
      expect(restored.id, equals('story_uts_002'));
      expect(restored.title, equals(story.title));
      expect(restored.category, equals(story.category));
      expect(restored.location, equals(story.location));
      expect(restored.imageUrl, equals(story.imageUrl));
      expect(restored.imagePath, equals(story.imagePath));
      expect(restored.isPending, isTrue);
    });

    test('Pemeriksaan Status Diterbitkan (Published) dan Ditolak (Rejected)', () {
      final publishedStory = StoryModel(
        id: 'story_published',
        title: 'Kisah Penunggu Danau',
        content: 'Isi cerita misteri penunggu danau yang sudah dipublikasikan...',
        category: 'Legenda Urban',
        authorId: 'author_01',
        authorName: 'Duwi',
        status: AppConstants.statusPublished,
        createdAt: DateTime.now(),
      );

      expect(publishedStory.isPublished, isTrue);
      expect(publishedStory.isPending, isFalse);
      expect(publishedStory.isRejected, isFalse);

      final rejectedStory = StoryModel(
        id: 'story_rejected',
        title: 'Cerita Hoaks',
        content: 'Isi cerita ini tidak lolos pedoman komunitas...',
        category: 'Lainnya',
        authorId: 'author_01',
        authorName: 'Duwi',
        status: AppConstants.statusRejected,
        moderationNote: 'Cerita mengandung konten yang melanggar pedoman.',
        createdAt: DateTime.now(),
      );

      expect(rejectedStory.isRejected, isTrue);
      expect(rejectedStory.isPublished, isFalse);
      expect(rejectedStory.moderationNote, isNotNull);
    });

    test('copyWith StoryModel untuk Pengajuan Ulang Cerita Ditolak', () {
      final rejected = StoryModel(
        id: 'story_001',
        title: 'Judul Lama',
        content: 'Konten lama',
        category: 'Misteri',
        authorId: 'uid_duwi',
        authorName: 'Duwi Galu',
        status: AppConstants.statusRejected,
        moderationNote: 'Mohon perbaiki isi',
        createdAt: DateTime(2026, 10, 1),
      );

      // Simulasi pengajuan ulang dengan membersihkan catatan penolakan
      final resubmitted = rejected.copyWith(
        title: 'Judul Baru yang Diperbaiki',
        status: AppConstants.statusPending,
        clearModerationNote: true,
        updatedAt: DateTime.now(),
      );

      expect(resubmitted.title, equals('Judul Baru yang Diperbaiki'));
      expect(resubmitted.status, equals(AppConstants.statusPending));
      expect(resubmitted.isPending, isTrue);
      expect(resubmitted.moderationNote, isNull);
      expect(resubmitted.updatedAt, isNotNull);
    });
  });

  group('Pengujian Unit - Aturan Validasi Storage (StorageService - Anggota 2)', () {
    test('Daftar Ekstensi File yang Diizinkan', () {
      expect(StorageService.allowedExtensions, contains('jpg'));
      expect(StorageService.allowedExtensions, contains('jpeg'));
      expect(StorageService.allowedExtensions, contains('png'));
      expect(StorageService.allowedExtensions, contains('webp'));
      expect(StorageService.allowedExtensions.contains('exe'), isFalse);
      expect(StorageService.allowedExtensions.contains('pdf'), isFalse);
    });

    test('Batas Maksimal Ukuran File 5 MB', () {
      expect(StorageService.maxFileSizeBytes, equals(5 * 1024 * 1024));
    });
  });
}
