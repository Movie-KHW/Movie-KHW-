# KHW Movie — Horror Stories & Movie Discovery
> **Proyek UTS Pemrograman Multi Platform — Kelas TA5J**  
> **Fakultas Teknologi Informasi — Institut Sains dan Bisnis Atma Luhur Pangkalpinang**  
> **Dosen Pengampu: Rezky Yuranda, M.Kom**

---

## 👥 Identitas Kelompok & Pembagian Tugas

Sesuai ketentuan baku lembar soal UTS:

| No | Nama Mahasiswa | NIM | Peran / Tanggung Jawab Baku |
|:--:|:---|:---:|:---|
| 1 | Melani Astuti | 2411500036 | Auth + navigasi + struktur folder |
| 2 | Duwi Galu Gandimi | 2411500010 | Firestore CRUD + Model/Service/Provider + ViewState |
| 3 | Fathurrahman Safari Lubis | 2411500025 | Dio REST API + loading/error/empty + Future vs Stream |
| 4 | Hanin Fadhilah | 2411500033 | Moderasi admin + integrasi + keamanan + pengujian |

---

## 📖 Deskripsi Proyek

**KHW Movie** adalah aplikasi mobile berbasis Flutter bertema cerita horor komunitas dan penemuan film horor. Pengguna dapat membaca cerita yang telah diterbitkan, mengirim cerita untuk dimoderasi, melihat status moderasi cerita (`pending`, `published`, `rejected`), menjelajahi katalog film horor melalui TMDB API, mencari film, menyimpan film favorit, serta mengelola akun dan profil.

*Catatan: Proyek ini dikembangkan secara independen oleh mahasiswa untuk pemenuhan tugas akademik UTS dan bukan aplikasi resmi atau afiliasi Nadia Omara maupun pihak lainnya.*

---

## 🛠️ Teknologi yang Digunakan

- **Framework**: Flutter & Dart (Null safety)
- **State Management**: `Provider` & `ChangeNotifier` dengan arsitektur `MultiProvider`
- **Autentikasi**: Firebase Authentication (Email & Password)
- **Database**: Cloud Firestore
- **Penyimpanan Berkas**: Firebase Storage
- **Koneksi REST API**: Dio HTTP Client & TMDB API

---

## 🚀 Fitur Utama & Modul

1. **Modul Autentikasi & Fondasi (Melani Astuti - 2411500036)**:
   - Inisialisasi Flutter & Firebase Core.
   - Registrasi akun (otomatis mendapatkan `role: 'user'`).
   - Penanganan kegagalan penulisan profil dengan rollback otomatis pada Firebase Auth.
   - Login, logout, dan auth-state listener realtime menggunakan `Stream<User?>` (`authStateChanges`).
   - Model `UserModel` dan dokumen profil `users/{uid}`.
   - Layar Login, Registrasi, Profil Pengguna, dan Beranda Fondasi.
   - Validasi formulir input dan mapping error ramah pengguna.
   - Pintu masuk reaktif `AuthGate` dan Dark Horror Theme.

2. **Modul Cerita Horor & Storage (Duwi Galu Gandimi - 2411500010)**:
   - CRUD Cerita Horor ke Cloud Firestore.
   - Mengirim dan mengelola cerita teks tanpa proses unggah foto.
   - Status awal cerita wajib `pending`; cerita hanya dapat diedit atau dihapus sebelum ditinjau admin.

3. **Modul TMDB API & Favorit (Fathurrahman Safari Lubis - 2411500025)**:
   - Integrasi REST API TMDB menggunakan `Dio` dengan endpoint `/discover/movie?with_genres=27`, `/movie/{movie_id}`, dan `/search/movie`.
   - Pola ViewState (Loading, Loaded, Error, Empty) pada `MovieProvider`.
   - Model `MovieModel` dengan safe parsing JSON, penanganan poster, rating, dan tahun rilis.
   - Layar Katalog Film Horor, Pencarian Film, dan Layar Detail Film sinematik.
   - Fitur Film Favorit ke Cloud Firestore koleksi `favorites` dengan ID dokumen deterministik `{uid}_{movieId}`.
   - `FavoriteProvider` dengan realtime stream listener, penanganan toggle favorit, dan pencegahan memory leak (`dispose()`).
   - Penanganan komprehensif DioException (timeout, koneksi, status error 401/404/429/500).

4. **Modul Moderasi Admin & Integrasi (Hanin Fadhilah - 2411500033)**:
   - Panel moderasi admin (`pending` -> `published` / `rejected`).
   - Integrasi `MultiProvider` dan rute navigasi keseluruhan.
   - Firebase Security Rules (`firestore.rules` & `storage.rules`).

---

## ⚙️ Panduan Menjalankan Aplikasi

### 1. Prasyarat
- Flutter SDK (versi >= 3.19.0)
- Dart SDK (versi >= 3.3.0)
- Koneksi Internet aktif

### 2. Konfigurasi Firebase (FlutterFire CLI)
Untuk menghubungkan proyek ke Firebase yang sesungguhnya:
```bash
# 1. Pastikan Firebase CLI terpasang dan login
firebase login

# 2. Pasang FlutterFire CLI
dart pub global activate flutterfire_cli

# 3. Konfigurasikan proyek ke Firebase Console kelompok
flutterfire configure --project=<FIREBASE_PROJECT_ID>
```
*Catatan: Pastikan `DefaultFirebaseOptions.currentPlatform` di `lib/main.dart` telah dihubungkan.*

### 3. Konfigurasi TMDB API
Aplikasi sudah dikonfigurasi dengan kunci bawaan yang siap pakai untuk pengujian. Anda juga dapat menyertakan API Key TMDB milik sendiri saat menjalankan aplikasi:
```bash
flutter run --dart-define=TMDB_API_KEY=<API_KEY_ANDA>
```

### 4. Mengunduh Dependensi & Menjalankan Aplikasi
```bash
# Unduh paket dependensi
flutter pub get

# Jalankan pengujian unit
flutter test

# Jalankan analisis linter
flutter analyze

# Jalankan aplikasi pada emulator atau perangkat fisik Android
flutter run
```

---

## 🧪 Hasil Pengujian (Unit & Static Analysis)

- **Flutter Analyze**: `No issues found! (0 errors, 0 warnings)`
- **Flutter Test**: `All 22 unit tests passed!` (6 pengujian Auth & User, 7 pengujian Story & Storage, 9 pengujian TMDB Movie & Favorites).

---

## 📹 Video Presentasi Bedah Kode
*(Link video presentasi Google Drive / YouTube akan dicantumkan di sini sesuai batas pengumpulan H+7).*
