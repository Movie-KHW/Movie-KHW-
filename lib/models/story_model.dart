// ===== IMPORT LIBRARY =====
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_constants.dart';

// ===== MODEL CERITA =====
class StoryModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String? location;
  final String? imageUrl;
  final String? imagePath;
  final String authorId;
  final String authorName;
  final String status; // 'pending', 'published', 'rejected'
  final String? moderationNote;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  const StoryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.location,
    this.imageUrl,
    this.imagePath,
    required this.authorId,
    required this.authorName,
    required this.status,
    this.moderationNote,
    required this.createdAt,
    this.updatedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  // Getter status cerita
  bool get isPending => status == AppConstants.statusPending;
  bool get isPublished => status == AppConstants.statusPublished;
  bool get isRejected => status == AppConstants.statusRejected;

  // ===== MEMBACA DATA CERITA =====
  factory StoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StoryModel.fromMap(data, doc.id);
  }

  factory StoryModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value, DateTime fallback) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return StoryModel(
      id: id,
      title: map['title'] as String? ?? 'Tanpa Judul',
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'Pengalaman Pribadi',
      location: map['location'] as String?,
      imageUrl: map['imageUrl'] as String?,
      imagePath: map['imagePath'] as String?,
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Anonim',
      status: map['status'] as String? ?? AppConstants.statusPending,
      moderationNote: map['moderationNote'] as String?,
      createdAt: parseDateTime(map['createdAt'], DateTime.now()),
      updatedAt: parseNullableDateTime(map['updatedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: parseNullableDateTime(map['reviewedAt']),
    );
  }

  // ===== MENGONVERSI DATA KE MAP FIRESTORE =====
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'location': location,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'authorId': authorId,
      'authorName': authorName,
      'status': status,
      'moderationNote': moderationNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }

  // ===== MEMPERBARUI CERITA =====
  StoryModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? location,
    String? imageUrl,
    String? imagePath,
    String? authorId,
    String? authorName,
    String? status,
    String? moderationNote,
    bool clearModerationNote = false,
    bool clearLocation = false,
    bool clearImage = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      location: clearLocation ? null : (location ?? this.location),
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      moderationNote: clearModerationNote ? null : (moderationNote ?? this.moderationNote),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  @override
  String toString() {
    return 'StoryModel(id: $id, title: $title, category: $category, status: $status, authorName: $authorName)';
  }
}
