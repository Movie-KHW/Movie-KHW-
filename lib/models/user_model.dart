// ===== IMPORT LIBRARY =====
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_constants.dart';

// ===== MODEL PENGGUNA =====
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  // Getter pembantu untuk memeriksa apakah pengguna berstatus admin
  bool get isAdmin => role == AppConstants.roleAdmin;

  // ===== MEMBACA DATA DARI FIRESTORE (DESERIALISASI) =====
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    // Menangani konversi createdAt baik dari Firestore Timestamp maupun tipe lain
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return UserModel(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Pengguna KHW',
      email: map['email'] as String? ?? '',
      // Pastikan fallback selalu 'user' agar tidak terjadi eskalasi role secara tidak sengaja
      role: map['role'] as String? ?? AppConstants.roleUser,
      createdAt: parsedCreatedAt,
    );
  }

  // ===== MENGONVERSI DATA KE FIRESTORE (SERIALISASI) =====
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ===== MENGGANDAKAN OBJEK DENGAN PERUBAHAN (COPYWITH) =====
  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, displayName: $displayName, email: $email, role: $role, createdAt: $createdAt)';
  }
}
