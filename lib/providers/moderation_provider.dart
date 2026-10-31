// ===== IMPORT LIBRARY =====
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';

// ===== ENUM POLA VIEW STATE (UTS P03/P05) =====
enum ModerationViewState { initial, loading, loaded, error, empty }

// ===== PROVIDER MODERASI ADMIN (ANGGOTA 4 - HANIN FADHILAH) =====
class ModerationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  // ===== STATE MODERASI =====
  List<StoryModel> _allStories = [];
  List<StoryModel> _pendingStories = [];
  List<StoryModel> _publishedStories = [];
  List<StoryModel> _rejectedStories = [];
  StoryModel? _selectedStory;

  // Status ViewState sesuai spesifikasi UTS P03/P05
  ModerationViewState _viewState = ModerationViewState.initial;

  // State proses aksi (Setujui / Tolak)
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _actionSuccessMessage;

  // Subscription stream Firestore untuk dispose subscription (UTS P03)
  StreamSubscription<List<StoryModel>>? _moderationStoriesSubscription;
  StreamSubscription<List<StoryModel>>? _pendingStoriesSubscription;

  ModerationProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService() {
    initModerationStreams();
  }

  // ===== GETTER STATE =====
  List<StoryModel> get allStories => _allStories;
  List<StoryModel> get pendingStories => _pendingStories;
  List<StoryModel> get publishedStories => _publishedStories;
  List<StoryModel> get rejectedStories => _rejectedStories;
  StoryModel? get selectedStory => _selectedStory;

  ModerationViewState get viewState => _viewState;
  bool get isLoading => _viewState == ModerationViewState.loading;
  bool get isLoaded => _viewState == ModerationViewState.loaded;
  bool get isError => _viewState == ModerationViewState.error;
  bool get isEmpty => _viewState == ModerationViewState.empty;
  bool get isActionLoading => _isActionLoading;

  String? get errorMessage => _errorMessage;
  String? get actionSuccessMessage => _actionSuccessMessage;

  // Statistik cerita untuk dashboard admin
  int get pendingCount => _pendingStories.length;
  int get publishedCount => _publishedStories.length;
  int get rejectedCount => _rejectedStories.length;
  int get totalCount => _allStories.length;

  // ===== MEMUAT CERITA PENDING & SEMUA CERITA =====
  // Mendengarkan perubahan Firestore secara realtime menggunakan Stream snapshots
  void initModerationStreams() {
    _viewState = ModerationViewState.loading;
    _errorMessage = null;
    notifyListeners();

    // Batalkan langganan sebelumnya jika ada
    _moderationStoriesSubscription?.cancel();
    _pendingStoriesSubscription?.cancel();

    // 1. Stream semua cerita untuk menghitung ringkasan statistik
    _moderationStoriesSubscription = _firestoreService
        .getAllStoriesForModeration()
        .listen(
      (stories) {
        _allStories = stories;
        _publishedStories = stories.where((s) => s.isPublished).toList();
        _rejectedStories = stories.where((s) => s.isRejected).toList();

        // Perbarui view state berdasarkan antrian pending
        if (_pendingStories.isEmpty) {
          _viewState = ModerationViewState.empty;
        } else {
          _viewState = ModerationViewState.loaded;
        }
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _viewState = ModerationViewState.error;
        _errorMessage = 'Gagal memuat data cerita moderasi: $error';
        notifyListeners();
      },
    );

    // 2. Stream khusus cerita berstatus pending untuk antrian verifikasi utama
    _pendingStoriesSubscription = _firestoreService
        .getAllPendingStories()
        .listen(
      (stories) {
        _pendingStories = stories;
        if (stories.isEmpty) {
          _viewState = ModerationViewState.empty;
        } else {
          _viewState = ModerationViewState.loaded;
        }
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _viewState = ModerationViewState.error;
        _errorMessage = 'Gagal memuat antrian cerita pending: $error';
        notifyListeners();
      },
    );
  }

  // Coba ulang memuat stream jika terjadi error koneksi
  void retry() {
    initModerationStreams();
  }

  // Memilih cerita untuk pratinjau detail sebelum moderasi
  void selectStory(StoryModel? story) {
    _selectedStory = story;
    notifyListeners();
  }

  // ===== MENYETUJUI CERITA =====
  // Mengubah status menjadi 'published', mencatat UID admin, dan waktu persetujuan
  Future<bool> approveStory({
    required String storyId,
    required String adminUid,
  }) async {
    if (adminUid.trim().isEmpty) {
      _errorMessage = 'Sesi admin tidak valid. Silakan login kembali.';
      notifyListeners();
      return false;
    }

    _setActionLoading(true);
    _clearMessages();

    try {
      await _firestoreService.moderateStory(
        storyId: storyId,
        status: AppConstants.statusPublished,
        moderationNote: null,
        reviewedBy: adminUid,
      );

      _actionSuccessMessage = 'Cerita berhasil disetujui dan diterbitkan untuk publik.';
      _setActionLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setActionLoading(false);
      return false;
    }
  }

  // ===== MENOLAK CERITA =====
  // Mengubah status menjadi 'rejected', mencatat alasan penolakan, UID admin, dan waktu
  Future<bool> rejectStory({
    required String storyId,
    required String adminUid,
    required String rejectionNote,
  }) async {
    final note = rejectionNote.trim();
    if (note.isEmpty) {
      _errorMessage = 'Catatan penolakan wajib diisi untuk memberikan alasan kepada penulis.';
      notifyListeners();
      return false;
    }

    if (adminUid.trim().isEmpty) {
      _errorMessage = 'Sesi admin tidak valid. Silakan login kembali.';
      notifyListeners();
      return false;
    }

    _setActionLoading(true);
    _clearMessages();

    try {
      await _firestoreService.moderateStory(
        storyId: storyId,
        status: AppConstants.statusRejected,
        moderationNote: note,
        reviewedBy: adminUid,
      );

      _actionSuccessMessage = 'Cerita telah ditolak dengan catatan evaluasi.';
      _setActionLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setActionLoading(false);
      return false;
    }
  }

  // ===== HELPER STATE & PESAN =====
  void _setActionLoading(bool value) {
    _isActionLoading = value;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _actionSuccessMessage = null;
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _actionSuccessMessage = null;
    notifyListeners();
  }

  // ===== DISPOSE SUBSCRIPTION =====
  @override
  void dispose() {
    // Membatalkan seluruh stream subscription Firestore agar tidak terjadi memory leak (UTS P03)
    _moderationStoriesSubscription?.cancel();
    _pendingStoriesSubscription?.cancel();
    _allStories.clear();
    _pendingStories.clear();
    _publishedStories.clear();
    _rejectedStories.clear();
    super.dispose();
  }
}
