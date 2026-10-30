// ===== IMPORT LIBRARY PENGUJIAN =====
import 'package:flutter_test/flutter_test.dart';
import 'package:khw_movie/models/user_model.dart';
import 'package:khw_movie/utils/app_constants.dart';
import 'package:khw_movie/utils/validators.dart';

void main() {
  group('Pengujian Unit - Validasi Formulir (Validators)', () {
    test('Validasi Nama Lengkap', () {
      expect(Validators.validateName(null), isNotNull);
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName('Me'), isNotNull); // kurang dari 3 karakter
      expect(Validators.validateName('Melani Astuti'), isNull); // valid
    });

    test('Validasi Format Email', () {
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('bukan-email'), isNotNull);
      expect(Validators.validateEmail('user@'), isNotNull);
      expect(Validators.validateEmail('melani@gmail.com'), isNull); // valid
    });

    test('Validasi Kata Sandi', () {
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull); // kurang dari 6 karakter
      expect(Validators.validatePassword('123456'), isNull); // valid 6 karakter
      expect(Validators.validatePassword('rahasia123'), isNull); // valid
    });

    test('Validasi Konfirmasi Kata Sandi', () {
      expect(Validators.validateConfirmPassword(null, 'password123'), isNotNull);
      expect(Validators.validateConfirmPassword('passBeda', 'passAsli'), isNotNull);
      expect(Validators.validateConfirmPassword('passSama', 'passSama'), isNull); // cocok
    });
  });

  group('Pengujian Unit - Model Pengguna (UserModel)', () {
    test('Serialisasi dan Deserialisasi UserModel dengan Role User', () {
      final now = DateTime(2026, 10, 30, 10, 0, 0);
      final user = UserModel(
        uid: 'user_uts_001',
        displayName: 'Melani Astuti',
        email: 'melani@khw.com',
        role: AppConstants.roleUser,
        createdAt: now,
      );

      expect(user.isAdmin, isFalse);
      expect(user.role, equals('user'));

      final map = user.toMap();
      expect(map['displayName'], equals('Melani Astuti'));
      expect(map['email'], equals('melani@khw.com'));
      expect(map['role'], equals('user'));

      final restored = UserModel.fromMap(map, 'user_uts_001');
      expect(restored.uid, equals('user_uts_001'));
      expect(restored.displayName, equals('Melani Astuti'));
      expect(restored.isAdmin, isFalse);
    });

    test('Pemeriksaan Role Admin pada UserModel', () {
      final adminUser = UserModel(
        uid: 'admin_uts_001',
        displayName: 'Admin Hanin',
        email: 'admin@khw.com',
        role: AppConstants.roleAdmin,
        createdAt: DateTime.now(),
      );

      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.role, equals('admin'));
    });
  });
}
