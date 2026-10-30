// ===== IMPORT LIBRARY =====
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/story_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';

// ===== PROVIDER CERITA =====
class StoryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  // State data cerita
  List<StoryModel> _publicStories = [];
  List<StoryModel> _userStories = [];
  List<StoryModel> _moderationStories = [];
  List<StoryModel> _pendingModerationStories = [];
  StoryModel? _selectedStory;
  String? _userStoriesUid;

  // Filter kategori cerita publik
  String _selectedCategory = 'Semua';

  // Filter status cerita pengguna ('Semua', 'pending', 'published', 'rejected')
  String _selectedUserStatus = 'Semua';

  // State status pemuatan data
  bool _isLoading = false;
  bool _isLoadingUserStories = false;
  bool _isModerationLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _actionSuccessMessage;

  // Subscription stream Firestore
  StreamSubscription<List<StoryModel>>? _publicStoriesSubscription;
  StreamSubscription<List<StoryModel>>? _userStoriesSubscription;
  StreamSubscription<List<StoryModel>>? _moderationStoriesSubscription;
  StreamSubscription<List<StoryModel>>? _pendingModerationSubscription;

  StoryProvider({
    FirestoreService? firestoreService,
    StorageService? storageService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _storageService = storageService ?? StorageService() {
    initPublicStoriesStream();
  }

  // ===== GETTER STATE =====
  List<StoryModel> get publicStories => _publicStories;
  List<StoryModel> get userStories => _userStories;
  List<StoryModel> get moderationStories => _moderationStories;
  List<StoryModel> get pendingModerationStories => _pendingModerationStories;
  StoryModel? get selectedStory => _selectedStory;
  String get selectedCategory => _selectedCategory;
  String get selectedUserStatus => _selectedUserStatus;
  bool get isLoading => _isLoading;
  bool get isLoadingUserStories => _isLoadingUserStories;
  bool get isModerationLoading => _isModerationLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String? get actionSuccessMessage => _actionSuccessMessage;

  // Cerita publik yang disaring berdasarkan kategori terpilih
  List<StoryModel> get filteredPublicStories {
    if (_selectedCategory == 'Semua') {
      return _publicStories;
    }
    return _publicStories
        .where(
          (s) => s.category.toLowerCase() == _selectedCategory.toLowerCase(),
        )
        .toList();
  }

  // Cerita pengguna yang disaring berdasarkan status moderasi
  List<StoryModel> get filteredUserStories {
    if (_selectedUserStatus == 'Semua') {
      return _userStories;
    }
    return _userStories
        .where(
          (s) => s.status.toLowerCase() == _selectedUserStatus.toLowerCase(),
        )
        .toList();
  }

  // Jumlah cerita pengguna berdasarkan status
  int get userPendingCount =>
      _userStories.where((s) => s.status == AppConstants.statusPending).length;
  int get userPublishedCount => _userStories
      .where((s) => s.status == AppConstants.statusPublished)
      .length;
  int get userRejectedCount =>
      _userStories.where((s) => s.status == AppConstants.statusRejected).length;
  int get moderationPendingCount =>
      _moderationStories.where((s) => s.isPending).length;
  int get moderationPublishedCount =>
      _moderationStories.where((s) => s.isPublished).length;
  int get moderationRejectedCount =>
      _moderationStories.where((s) => s.isRejected).length;

  // ===== MEMBACA DATA CERITA =====

  // Menginisialisasi stream cerita publik (status = 'published')
  void initPublicStoriesStream() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _publicStoriesSubscription?.cancel();
    _publicStoriesSubscription = _firestoreService
        .getPublishedStoriesStream()
        .listen(
          (stories) {
            _publicStories = stories;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = 'Gagal memuat cerita publik: $error';
            notifyListeners();
          },
        );
  }

  // Menginisialisasi stream cerita milik pengguna yang sedang login
  void initUserStoriesStream(String uid) {
    if (uid.isEmpty) return;
    if (_userStoriesUid == uid && _userStoriesSubscription != null) return;

    _userStoriesUid = uid;
    _userStories = [];
    _isLoadingUserStories = true;
    _userStoriesSubscription?.cancel();
    notifyListeners();
    _userStoriesSubscription = _firestoreService
        .getUserStoriesStream(uid)
        .listen(
          (stories) {
            if (_userStoriesUid != uid) return;
            _userStories = stories;
            _isLoadingUserStories = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            if (_userStoriesUid != uid) return;
            _isLoadingUserStories = false;
            _errorMessage = 'Gagal memuat cerita Anda: $error';
            notifyListeners();
          },
        );
  }

  void initModerationStreams() {
    if (_moderationStoriesSubscription != null &&
        _pendingModerationSubscription != null) {
      return;
    }

    _isModerationLoading = true;
    _errorMessage = null;
    notifyListeners();

    _moderationStoriesSubscription = _firestoreService
        .getAllStoriesForModeration()
        .listen(
          (stories) {
            _moderationStories = stories;
            _isModerationLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _moderationStoriesSubscription?.cancel();
            _pendingModerationSubscription?.cancel();
            _moderationStoriesSubscription = null;
            _pendingModerationSubscription = null;
            _isModerationLoading = false;
            _errorMessage = 'Gagal memuat data moderasi: $error';
            notifyListeners();
          },
        );

    _pendingModerationSubscription = _firestoreService
        .getAllPendingStories()
        .listen(
          (stories) {
            _pendingModerationStories = stories;
            notifyListeners();
          },
          onError: (error) {
            _moderationStoriesSubscription?.cancel();
            _pendingModerationSubscription?.cancel();
            _moderationStoriesSubscription = null;
            _pendingModerationSubscription = null;
            _isModerationLoading = false;
            _errorMessage =
                'Gagal memuat cerita yang menunggu moderasi: $error';
            notifyListeners();
          },
        );
  }

  void retryModerationStreams() {
    _moderationStoriesSubscription?.cancel();
    _pendingModerationSubscription?.cancel();
    _moderationStoriesSubscription = null;
    _pendingModerationSubscription = null;
    initModerationStreams();
  }

  // Mengambil ulang data cerita publik secara manual (Refresh)
  Future<void> refreshPublicStories() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final stories = await _firestoreService.getPublishedStories();
      _publicStories = stories;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengambil ulang data cerita pengguna secara manual (Refresh)
  Future<void> refreshUserStories(String uid) async {
    if (uid.isEmpty) return;
    try {
      final stories = await _firestoreService.getUserStories(uid);
      _userStories = stories;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Memilih atau melihat detail satu cerita
  void selectStory(StoryModel story) {
    _selectedStory = story;
    notifyListeners();
  }

  Future<void> fetchStoryById(String storyId) async {
    try {
      _isLoading = true;
      notifyListeners();
      _selectedStory = await _firestoreService.getStoryById(storyId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengatur filter kategori cerita publik
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Mengatur filter status cerita milik pengguna
  void setUserStatusFilter(String status) {
    _selectedUserStatus = status;
    notifyListeners();
  }

  // ===== MENAMBAHKAN CERITA =====
  Future<bool> createStory({
    required String title,
    required String content,
    required String category,
    String? location,
    XFile? imageFile,
    required String authorId,
    required String authorName,
  }) async {
    _setActionLoading(true);
    _clearMessages();
    String? uploadedImagePath;

    try {
      // 1. Validasi foto jika ada
      if (imageFile != null) {
        final validationError = await _storageService.validateImageFile(
          imageFile,
        );
        if (validationError != null) {
          _errorMessage = validationError;
          _setActionLoading(false);
          return false;
        }
      }

      final storyId = _firestoreService.generateStoryId();
      Map<String, String>? uploadResult;
      var imageUploadFailed = false;
      if (imageFile != null) {
        try {
          uploadResult = await _storageService.uploadStoryImage(
            file: imageFile,
            uid: authorId,
            storyId: storyId,
          );
          uploadedImagePath = uploadResult['imagePath'];
        } catch (storageError) {
          debugPrint(
            'Peringatan: Gagal unggah foto saat tambah cerita: $storageError',
          );
          imageUploadFailed = true;
        }
      }

      await _firestoreService.createStory(
        storyId: storyId,
        title: title,
        content: content,
        category: category,
        location: location,
        imageUrl: uploadResult?['imageUrl'],
        imagePath: uploadResult?['imagePath'],
        authorId: authorId,
        authorName: authorName,
      );

      _actionSuccessMessage = imageUploadFailed
          ? 'Cerita tersimpan, namun foto gagal diunggah. Menunggu moderasi admin.'
          : 'Cerita berhasil dikirim! Menunggu pemeriksaan dari admin (pending).';
      _setActionLoading(false);
      return true;
    } catch (e) {
      if (uploadedImagePath != null) {
        await _storageService.deleteStoryImage(uploadedImagePath);
      }
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setActionLoading(false);
      return false;
    }
  }

  Future<bool> moderateStory({
    required String storyId,
    required String status,
    String? moderationNote,
    required String reviewedBy,
  }) async {
    _setActionLoading(true);
    _clearMessages();

    try {
      await _firestoreService.moderateStory(
        storyId: storyId,
        status: status,
        moderationNote: moderationNote,
        reviewedBy: reviewedBy,
      );
      _actionSuccessMessage = status == AppConstants.statusPublished
          ? 'Cerita berhasil disetujui dan diterbitkan.'
          : 'Cerita berhasil ditolak.';
      _setActionLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setActionLoading(false);
      return false;
    }
  }

  // ===== MEMPERBARUI CERITA =====
  // Mendukung pengajuan ulang cerita yang ditolak (rejected) menjadi pending
  Future<bool> updateStory({
    required String storyId,
    required String authorId,
    required String title,
    required String content,
    required String category,
    String? location,
    XFile? newImageFile,
    bool removeCurrentImage = false,
    String? existingImageUrl,
    String? existingImagePath,
  }) async {
    _setActionLoading(true);
    _clearMessages();

    try {
      String? finalImageUrl = existingImageUrl;
      String? finalImagePath = existingImagePath;

      // 1. Jika pengguna meminta menghapus foto lama tanpa mengganti baru
      if (removeCurrentImage && existingImagePath != null) {
        await _storageService.deleteStoryImage(existingImagePath);
        finalImageUrl = null;
        finalImagePath = null;
      }

      // 2. Jika ada foto baru yang dipilih
      if (newImageFile != null) {
        final validationError = await _storageService.validateImageFile(
          newImageFile,
        );
        if (validationError != null) {
          _errorMessage = validationError;
          _setActionLoading(false);
          return false;
        }

        // Hapus foto lama di storage jika ada
        if (existingImagePath != null && existingImagePath.isNotEmpty) {
          await _storageService.deleteStoryImage(existingImagePath);
        }

        // Unggah foto baru
        final uploadResult = await _storageService.uploadStoryImage(
          file: newImageFile,
          uid: authorId,
          storyId: storyId,
        );

        finalImageUrl = uploadResult['imageUrl'];
        finalImagePath = uploadResult['imagePath'];
      }

      // 3. Perbarui dokumen di Firestore (status akan di-reset ke pending secara otomatis)
      await _firestoreService.updateStory(
        storyId: storyId,
        authorId: authorId,
        title: title,
        content: content,
        category: category,
        location: location,
        imageUrl: finalImageUrl,
        imagePath: finalImagePath,
      );

      _actionSuccessMessage =
          'Cerita berhasil diperbarui dan diajukan ulang ke moderasi admin.';
      _setActionLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setActionLoading(false);
      return false;
    }
  }

  // ===== MENGHAPUS CERITA =====
  Future<bool> deleteStory({
    required String storyId,
    required String authorId,
    String? imagePath,
    bool isAdmin = false,
  }) async {
    _setActionLoading(true);
    _clearMessages();

    try {
      // 1. Hapus dokumen di Firestore terlebih dahulu
      await _firestoreService.deleteStory(
        storyId: storyId,
        authorId: authorId,
        isAdmin: isAdmin,
      );

      // 2. Hapus foto terkait di Firebase Storage secara aman
      if (imagePath != null && imagePath.isNotEmpty) {
        await _storageService.deleteStoryImage(imagePath);
      }

      _actionSuccessMessage = 'Cerita berhasil dihapus.';
      _setActionLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setActionLoading(false);
      return false;
    }
  }

  // ===== HELPER STATE & ERROR =====
  void _setActionLoading(bool value) {
    _isActionLoading = value;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _actionSuccessMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _actionSuccessMessage = null;
    notifyListeners();
  }

  // ===== DISPOSE =====
  @override
  void dispose() {
    _publicStoriesSubscription?.cancel();
    _userStoriesSubscription?.cancel();
    _moderationStoriesSubscription?.cancel();
    _pendingModerationSubscription?.cancel();
    super.dispose();
  }
}
