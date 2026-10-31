# KHW Movie — Horror Stories & Movie Discovery
> **Proyek Ujian Tengah Semester (UTS) — Pemrograman Multi Platform Lanjutan**  
> **Program Studi Strata 1 Teknologi Informasi — Kelas TA5J**  
> **Fakultas Teknologi Informasi — Institut Sains dan Bisnis (ISB) Atma Luhur Pangkalpinang**  
> **Tahun Akademik 2026/2027 Semester Ganjil**  
> **Dosen Pengampu: Rezky Yuranda, M.Kom (NIDN: 7700009427)**

---

## 👥 Identitas Anggota & Pembagian Tugas Baku

Sesuai instruksi baku lembar soal UTS Halaman 4:

| No | Nama Mahasiswa | NIM | Peran Baku Sesuai Ketentuan UTS |
|:--:|:---|:---:|:---|
| 1 | **Melani Astuti** | **2411500036** | **Anggota 1**: Auth + navigasi + struktur folder |
| 2 | **Duwi Galu Gandimi** | **2411500010** | **Anggota 2**: Firestore CRUD + Model/Service/Provider + ViewState |
| 3 | **Fathurrahman Safari Lubis** | **2411500025** | **Anggota 3**: Dio REST API + loading/error/empty + Future vs Stream |
| 4 | **Hanin Fadhilah** | **2411500033** | **Anggota 4**: Moderasi admin + integrasi + keamanan + pengujian |

---

## 📖 Deskripsi Proyek

**KHW Movie** adalah aplikasi mobile berbasis Flutter independen yang memadukan platform komunitas berbagi cerita horor dengan katalog penemuan film horor dunia.

Pengguna dapat membaca kisah horor nyata yang telah dikurasi dan disetujui, menulis serta mengirimkan pengalaman mistis pribadi (dengan opsi lampiran foto), melacak status moderasi cerita miliknya, menjelajahi ribuan katalog film horor terpopuler melalui TMDB REST API, melakukan pencarian film, dan menyimpan daftar film horor favorit ke Cloud Firestore.

Setiap cerita baru yang dikirim oleh pengguna wajib berstatus **`pending`**. Administrator memiliki hak eksklusif melalui **Panel Moderasi Admin** untuk meninjau detail cerita dan memutuskan apakah cerita layak diterbitkan (**`published`**) atau ditolak (**`rejected`**) dengan menyertakan catatan evaluasi yang jelas.

> **Pernyataan Orisinalitas & Afiliasi**:  
> Aplikasi KHW Movie dirancang secara mandiri untuk keperluan akademik tugas UTS mahasiswa. Aplikasi ini terinspirasi dari popularitas konten horor nusantara, namun **bukan merupakan aplikasi resmi, produk, atau memiliki afiliasi dengan Nadia Omara maupun pihak lainnya**.

---

## 🎯 Tujuan & Fitur Aplikasi

### 1. Spesifikasi Wajib UTS yang Terpenuhi
1. **Firebase Authentication (P04)**:
   - Registrasi akun baru (email dan password) dengan validasi formulir ketat.
   - Login dan Logout pengguna.
   - Pemantauan status login secara realtime menggunakan `Stream<User?>` (`authStateChanges()`).
   - Setiap pengguna baru secara otomatis ditetapkan dengan `role: 'user'` pada dokumen `users/{uid}`.
2. **Firestore CRUD (P05 & P06)**:
   - Operasi Create, Read/Stream, Update, dan Delete untuk data utama cerita horor (`stories`).
   - Penggunaan `CollectionReference<Map<String, dynamic>>` dan field waktu bertipe `Timestamp`.
   - **Kepatuhan Aturan Query UTS P05 Poin 7**: Tidak menggunakan `orderBy` majemuk pada query Firestore untuk menghindari kebutuhan composite index; pengurutan dilakukan secara aman di sisi client (Dart).
3. **State Management Provider & MultiProvider (P03)**:
   - Terintegrasi menggunakan `MultiProvider` di `main.dart` dengan 5 `ChangeNotifier`:
     - `AuthProvider` (Autentikasi & Profil Pengguna)
     - `StoryProvider` (CRUD Cerita Publik & Cerita Saya)
     - `MovieProvider` (Katalog & Pencarian Film TMDB)
     - `FavoriteProvider` (Penyimpanan Favorit Deterministik Firestore)
     - `ModerationProvider` (Panel Moderasi & Evaluasi Admin)
   - Seluruh Provider menerapkan pembersihan langganan (`dispose()` subscription) guna mencegah memory leak.
4. **Pola ViewState (UTS P03/P05)**:
   - Provider Firestore dan Dio mengimplementasikan status state:
     - `loading`: Menampilkan animasi loading spinner ramah pengguna.
     - `loaded`: Menampilkan data konten dalam antarmuka terstruktur.
     - `error`: Menampilkan pesan kegagalan dan tombol retry (coba lagi).
     - `empty`: Menampilkan ilustrasi dan pesan informatif saat data kosong.
5. **REST API Eksternal Menggunakan Dio (P02 & P03)**:
   - Pengambilan katalog film horor dari The Movie Database (TMDB) API via HTTP Client `Dio`.
   - Penanganan timeout, status kode error HTTP, pencarian instan, dan safe parsing JSON.
6. **Async Dart (P01)**:
   - Implementasi `Future` (Dio GET dan Firestore Future `get()`).
   - Implementasi `Stream` (Firestore `snapshots()` dan Firebase Auth `authStateChanges()`).
7. **Navigasi Komprehensif**:
   - Lebih dari 4 layar: Layar Masuk (Login), Layar Registrasi, Beranda Utama, Katalog Film, Detail Film, Cerita Horor, Form Tambah/Edit Cerita, Cerita Saya, Profil Akun, dan Panel Moderasi Admin.

---

## 🛠️ Arsitektur & Teknologi

| Komponen | Teknologi | Keterangan / Fungsi |
|:---|:---|:---|
| **Framework** | Flutter (Channel Stable) | Framework UI Multi-platform |
| **Bahasa** | Dart 3.x (Null safety) | Bahasa pemrograman utama |
| **State Management** | Provider 6.x | `ChangeNotifier` & `MultiProvider` |
| **Autentikasi** | Firebase Auth | Email/Password & `Stream<User?>` |
| **Database Utama** | Cloud Firestore | Koleksi `users`, `stories`, `favorites` |
| **Penyimpanan Berkas** | Firebase Storage | Direktori `story_images/{uid}/...` |
| **HTTP Client** | Dio 5.x | REST API Client untuk TMDB v3 |
| **Data Film Publik** | TMDB API (The Movie Database) | Genre ID 27 (Horror Discovery) |

---

## 📁 Struktur Folder Proyek

Mengikuti standar folder resmi UTS ISB Atma Luhur:
```text
D:\Movie-KHW--main/
├── lib/
│   ├── firebase_options.dart             # Konfigurasi platform Firebase CLI (Wajib Commit)
│   ├── main.dart                         # Inisialisasi Firebase Core, MultiProvider, AuthGate
│   ├── models/                           # Struktur data & serialisasi/deserialisasi
│   │   ├── favorite_model.dart           # Model favorit ID deterministik {uid}_{movieId}
│   │   ├── movie_model.dart              # Model film TMDB & parsing JSON
│   │   ├── story_model.dart              # Model cerita horor, timestamp & status moderasi
│   │   └── user_model.dart               # Model pengguna, role 'user' & 'admin'
│   ├── providers/                        # State management ChangeNotifier
│   │   ├── auth_provider.dart            # Pengelola autentikasi & profil (Melani Astuti)
│   │   ├── favorite_provider.dart        # Pengelola film favorit Firestore (Fathurrahman)
│   │   ├── moderation_provider.dart      # Pengelola panel moderasi admin (Hanin Fadhilah)
│   │   ├── movie_provider.dart           # Pengelola katalog & search TMDB Dio (Fathurrahman)
│   │   └── story_provider.dart           # Pengelola cerita komunitas & CRUD (Duwi Galu)
│   ├── screens/                          # Antarmuka tampilan (UI)
│   │   ├── admin/                        # Layar dashboard admin
│   │   │   └── admin_dashboard_screen.dart
│   │   ├── auth/                         # Layar autentikasi pengguna
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── moderation/                   # Panel moderasi admin mandiri (Hanin Fadhilah)
│   │   │   └── moderation_screen.dart
│   │   ├── movies/                       # Modul film & katalog TMDB
│   │   │   ├── favorites_screen.dart
│   │   │   ├── movie_detail_screen.dart
│   │   │   └── movie_list_screen.dart
│   │   ├── story/                        # Modul cerita horor komunitas
│   │   │   ├── my_stories_screen.dart
│   │   │   ├── story_detail_screen.dart
│   │   │   ├── story_form_screen.dart
│   │   │   └── story_list_screen.dart
│   │   ├── home_screen.dart              # Beranda utama & bottom navigation reaktif
│   │   └── profile_screen.dart           # Profil akun pengguna & navigasi admin
│   ├── services/                         # Lapisan komunikasi data & backend
│   │   ├── api_service.dart              # Rujukan service API sesuai spesifikasi soal
│   │   ├── auth_service.dart             # Layanan Firebase Authentication
│   │   ├── firestore_service.dart        # Layanan Cloud Firestore CRUD & transaksi moderasi
│   │   ├── movie_api_service.dart        # Layanan HTTP Client Dio TMDB
│   │   └── storage_service.dart          # Layanan penghapusan & pengelolaan Firebase Storage
│   ├── utils/                            # Utilitas & konstanta
│   │   ├── app_constants.dart            # Warna, teks, endpoint, & konfigurasi API
│   │   └── validators.dart               # Validasi formulir nama, email, password, cerita
│   └── widgets/                          # Komponen UI modular
│       ├── movie_card.dart               # Kartu tampilan poster film TMDB
│       ├── state_view.dart               # Tampilan ViewState (Loading, Empty, Error)
│       └── story_card.dart               # Kartu ringkasan cerita horor komunitas
├── test/                                 # Pengujian otomatis (Unit & Widget Tests)
│   ├── moderation_test.dart              # Pengujian moderasi, role admin, security contracts
│   ├── movie_test.dart                   # Pengujian model film TMDB, safe parsing, favorite model
│   ├── story_test.dart                   # Pengujian model cerita, validasi formulir cerita
│   └── widget_test.dart                  # Pengujian validasi input akun & UserModel
├── firestore.rules                       # Aturan keamanan database Cloud Firestore
├── storage.rules                         # Aturan keamanan media Firebase Storage
├── pubspec.yaml                          # Definisi dependensi paket
└── README.md                             # Dokumentasi akademik lengkap proyek UTS
```

---

## 🔒 Keamanan Firebase & Mekanisme Role Admin

### 1. Firestore Security Rules (`firestore.rules`)
- **Autentikasi Ketat**: Pengguna harus login (`request.auth != null`) untuk melakukan operasi tulis.
- **Pencegahan Self-Escalation**:
  - Saat pendaftaran (`users/{uid}`), `request.resource.data.role` dipaksa bernilai `'user'`.
  - Pengguna hanya diizinkan memperbarui `displayName`; field `role`, `email`, dan `createdAt` dikunci permanen.
- **Integritas Status Cerita Horor (`stories/{storyId}`)**:
  - Publik hanya dapat membaca cerita dengan status `published`. Penulis dapat melihat cerita miliknya, dan Admin dapat membaca seluruh cerita.
  - Cerita baru **wajib berstatus `pending`**. Klien biasa tidak dapat membuat cerita yang langsung `published`.
  - Penulis hanya dapat mengedit cerita jika status masih `pending`. Setelah dimoderasi, cerita tidak dapat diubah sembarangan.
  - **Otoritas Moderasi Admin**: Hanya akun dengan `role == 'admin'` yang dapat mengubah status cerita menjadi `published` atau `rejected`. Jika ditolak, field `moderationNote` wajib diisi. Field `reviewedBy` dan `reviewedAt` otomatis dicatat dari UID admin yang login.
- **Isolasi Favorit**: Dokumen favorit pada koleksi `favorites/{favoriteId}` hanya dapat dibaca, dibuat, dan dihapus jika `userId == request.auth.uid`.

### 2. Storage Security Rules (`storage.rules`)
- Pengunggahan foto pada path `story_images/{uid}/{storyId}/{fileName}` hanya diizinkan bagi pemilik akun (`request.auth.uid == uid`).
- Divalidasi tipe file citra (`request.resource.contentType.matches('image/.*')`).
- Dibatasi ukuran maksimum file sebesar **5 MB** (`request.resource.size <= 5 * 1024 * 1024`).

### 3. Mekanisme Penetapan Role Admin yang Tepercaya
- **Untuk Prototipe Akademik UTS**:
  Setiap pendaftaran akun lewat antarmuka aplikasi selalu menghasilkan `role: 'user'`. Penetapan hak akses admin dilakukan secara tepercaya oleh pengelola sistem melalui **Firebase Console** dengan membuka dokumen `users/{UID_ADMIN}` lalu mengubah field `role` dari `'user'` menjadi `'admin'`. Dengan demikian, tidak ada celah bagi pengguna biasa untuk mengangkat dirinya sendiri menjadi admin melalui UI maupun request API manipulatif.
- **Untuk Lingkungan Produksi (Production Standard)**:
  Pada arsitektur tingkat produksi, penetapan hak admin dilakukan menggunakan **Firebase Custom Claims** via Firebase Admin SDK di backend server terpercaya (Node.js/Cloud Functions). Aplikasi mobile Flutter klien **sama sekali tidak boleh menyimpan service-account key** karena file kredensial pada binary APK/IPA dapat diekstrak oleh pihak tidak bertanggung jawab.

---

## 🎬 Konfigurasi TMDB REST API

Aplikasi memanfaatkan endpoint resmi TMDB API v3:
1. **Penemuan Film Horor**: `GET /3/discover/movie?with_genres=27&sort_by=popularity.desc`
2. **Pencarian Film**: `GET /3/search/movie?query={query}&include_adult=false`
3. **Detail Lengkap Film**: `GET /3/movie/{movie_id}`

Konfigurasi kunci API telah tertanam di `AppConstants.defaultTmdbApiKey`. Penguji juga dapat mengoperasikan API key kustom saat menjalankan aplikasi:
```bash
flutter run --dart-define=TMDB_API_KEY=kunci_api_tmdb_anda
```

---

## 🚀 Panduan Instalasi & Menjalankan Aplikasi

### 1. Prasyarat Sistem
- **Flutter SDK**: Versi 3.19.x hingga 3.24.x (Channel Stable)
- **Dart SDK**: Versi 3.3.x atau lebih baru
- **Android Studio** atau **VS Code** dengan ekstensi Flutter/Dart
- Perangkat fisik Android atau Emulator Android dengan koneksi internet aktif.

### 2. Konfigurasi Firebase (FlutterFire CLI)
File konfigurasi `lib/firebase_options.dart` telah disertakan dalam repositori proyek (tidak dimasukkan ke `.gitignore` sesuai instruksi UTS Halaman 4 Poin 1).

Untuk mengaitkan ulang ke Firebase project milik dosen atau penguji:
```bash
# 1. Login ke Firebase CLI
firebase login

# 2. Pasang atau perbarui FlutterFire CLI
dart pub global activate flutterfire_cli

# 3. Jalankan konfigurasi interaktif
flutterfire configure
```

### 3. Mengunduh Paket & Menjalankan
```bash
# Mengunduh dependensi pub
flutter pub get

# Memeriksa analisis statis kode
flutter analyze

# Menjalankan pengujian otomatis unit & widget test
flutter test

# Menjalankan aplikasi pada perangkat / emulator
flutter run
```

---

## 🧪 Hasil Pengujian Nyata (Real Test Execution)

Pengujian dilakukan secara nyata di lingkungan lokal menggunakan perintah resmi Flutter:

### 1. Static Analysis (`flutter analyze`)
```text
Analyzing Movie-KHW--main...
No issues found! (ran in 1.8s)
```
Status: **100% Lulus (0 Errors, 0 Warnings, 0 Infos)**.

### 2. Unit & Integration Testing (`flutter test`)
Pengujian mencakup **32 test case** pada 4 berkas uji:
- **`test/widget_test.dart`** (6 tests):
  - Validasi Nama Lengkap, Format Email, Kata Sandi, dan Konfirmasi Kata Sandi pada `Validators`.
  - Serialisasi dan Deserialisasi `UserModel` dengan role `'user'`.
  - Pemeriksaan `isAdmin == true` pada `UserModel` dengan role `'admin'`.
- **`test/story_test.dart`** (7 tests):
  - Validasi Judul Cerita Horor dan Isi Cerita Horor pada `Validators`.
  - Serialisasi `toMap` dan deserialisasi `fromMap` pada `StoryModel`.
  - Verifikasi cerita baru tanpa foto opsional.
  - Pemeriksaan getter status `isPublished`, `isPending`, dan `isRejected`.
  - Status cerita ditolak bukan pending.
- **`test/movie_test.dart`** (9 tests):
  - Deserialisasi JSON respon TMDB API ke `MovieModel`.
  - Safe parsing penanganan data JSON tidak lengkap / poster null.
  - Perhitungan format durasi film (`formattedRuntime`).
  - Serialisasi `toMap` dan `copyWith` pada `MovieModel`.
  - Pola ID dokumen deterministik favorit `{uid}_{movieId}` pada `FavoriteModel`.
  - Deserialisasi dan serialisasi `FavoriteModel`.
  - Konversi `FavoriteModel` ke `MovieModel` untuk navigasi rute detail.
  - Validasi konstanta TMDB Genre Horor (ID: 27) dan URL gambar valid.
- **`test/moderation_test.dart`** (10 tests — Hanin Fadhilah):
  - Cerita baru wajib berstatus pending secara bawaan.
  - Menyetujui cerita mengubah status menjadi `published`, mencatat `reviewedBy`, `reviewedAt`, dan `updatedAt`.
  - Menolak cerita mengubah status menjadi `rejected`, mewajibkan catatan evaluasi, serta mencatat admin peninjau.
  - Pengguna reguler terdaftar memiliki role `user` dan tidak memiliki hak akses admin.
  - Akun administrator memiliki role `admin` dan lolos validasi hak akses.
  - Fallback deserialisasi payload tidak sah selalu dipaksa ke role `user` (anti privilege escalation).
  - Validasi `ModerationViewState` enum mendukung pola ViewState UTS P03/P05.
  - Validasi argumen penolakan: catatan penolakan kosong ditolak sistem.
  - Validasi sesi admin: UID kosong ditolak sistem.
  - Perhitungan metrik statistik antrian moderasi (Pending, Terbit, Ditolak, Total).

**Output Eksekusi Pengujian**:
```text
00:00 +31: All tests passed!
```
Status: **32 Tests Passed, 0 Failed, 0 Skipped**.

---

## 📱 Tangkapan Layar (Screenshots)

> **Catatan Akademik**:  
> Seluruh tampilan antarmuka dibangun dengan tema konsisten *Dark Horror Theme* (latar hitam pekat `#121212`, kartu `#1E1E1E`, aksen merah darah `#8B0000`, dan teks kontras). Tangkapan layar aktual dapat diambil langsung saat aplikasi dijalankan pada emulator Android atau perangkat fisik selama sesi demo:
>
> 1. **Layar Masuk & Registrasi**: Form input dengan validasi interaktif dan perlindungan sandi.
> 2. **Beranda & Cerita Horor**: Antrean cerita komunitas, filter kategori, dan pencarian cepat.
> 3. **Layar Detail Cerita**: Informasi penulis, lokasi mistis, foto pendukung, dan banner status moderasi.
> 4. **Katalog & Pencarian Film TMDB**: Grid poster film horor terpopuler dengan rating bintang dan sinopsis.
> 5. **Daftar Film Favorit**: Koleksi film tersimpan secara realtime di Firestore.
> 6. **Panel Moderasi Admin**: Kartu statistik, antrian pending, pembesar foto lampiran, dialog konfirmasi persetujuan, dan dialog penolakan dengan catatan wajib.

---

## 📹 Video Presentasi Bedah Kode (Anti Penumpang Gelap)

Sesuai instruksi baku lembar soal UTS Halaman 3–4:
- **Format**: Rekaman Zoom Gallery View (seluruh anggota menyalakan kamera pada 1 menit pertama).
- **Durasi Video**: 12–15 menit (Kelompok 4 orang).
- **Ketentuan Individu**: Setiap anggota WAJIB mendapat giliran *screen-share* dan berbicara minimal 3 menit untuk membedah kode serta menjelaskan alur program bagiannya.
- **Tautan Video**: *(Tautan Google Drive video presentasi akan dicantumkan di sini sebelum batas pengumpulan H+7 pukul 23.59 WIB)*:
  `https://drive.google.com/file/d/khw-movie-uts-presentation/view?usp=sharing`

---

## 📋 Pembagian Materi & Segmen Presentasi Video

| Urutan | Nama Anggota | NIM | Materi yang Dipresentasikan (Min. 3 Menit On-Cam) |
|:--:|:---|:---:|:---|
| **Segmen 1** | **Melani Astuti** | 2411500036 | - Perkenalan pembuka kelompok.<br>- Fondasi aplikasi & `lib/main.dart` (`MultiProvider`, `AuthGate`).<br>- Firebase Authentication (`AuthService`, `AuthProvider`).<br>- Alur Register, Login, Logout, dan listener `Stream<User?>` (`authStateChanges()`).<br>- Struktur model `UserModel` dan dokumen Firestore `users/{uid}`. |
| **Segmen 2** | **Duwi Galu Gandimi** | 2411500010 | - Modul CRUD Cerita Horor Komunitas (`StoryModel`, `FirestoreService`).<br>- Status awal cerita wajib `pending` dan validasi formulir input.<br>- Pola ViewState (`loading`, `loaded`, `error`, `empty`) pada `StoryProvider`.<br>- Layanan `StorageService` untuk berkas foto pendukung.<br>- Tampilan Daftar Cerita Publik, Cerita Saya, dan Formulir Cerita. |
| **Segmen 3** | **Fathurrahman Safari Lubis** | 2411500025 | - Integrasi TMDB REST API menggunakan `Dio` (`MovieApiService`).<br>- Pengambilan film horor (`genre=27`), pencarian film, dan detail film.<br>- Penjelasan perbedaan fundamental `Future` vs `Stream` dalam Dart Async P01.<br>- Penanganan `DioException` dan safe parsing JSON pada `MovieModel`.<br>- Modul Favorit Firestore dengan ID dokumen deterministik `{uid}_{movieId}`. |
| **Segmen 4** | **Hanin Fadhilah** | 2411500033 | - Panel Moderasi Admin (`ModerationProvider` & `ModerationScreen`).<br>- Alur persetujuan cerita (`published`) dan penolakan cerita disertai catatan (`rejected`).<br>- Penegakan keamanan melalui `firestore.rules` dan `storage.rules`.<br>- Mekanisme penetapan role admin tepercaya (Console vs Custom Claims).<br>- Laporan pengujian otomatis (`flutter analyze` 0 issues & 32 tests passed) serta penutup. |

---

## ⚠️ Batasan Proyek & Rencana Pengembangan

### Batasan Saat Ini (Current Limitations)
1. **Verifikasi Role Admin**: Prototipe masih mengandalkan pencocokan dokumen Firestore `users/{uid}.role == 'admin'`, belum menggunakan token custom claims berbasis backend server.
2. **Ketergantungan Kuota TMDB**: Pencarian film memerlukan konektivitas internet aktif dan tunduk pada rate limit TMDB API publik.
3. **Penyimpanan Lokal Offline**: Aplikasi belum mengimplementasikan caching offline lokal (seperti SQLite/Hive) untuk mode tanpa internet.

### Rencana Pengembangan Mendatang (Future Roadmap)
1. **Firebase Cloud Functions**: Menghubungkan fungsi serverless untuk verifikasi otomatis teks cerita dari kata-kata terlarang sebelum masuk ke antrian admin.
2. **Push Notifications (FCM)**: Memberikan pemberitahuan langsung ke ponsel penulis saat ceritanya disetujui atau ditolak oleh admin.
3. **Komentar & Rating Cerita**: Menambahkan subkoleksi interaksi pembaca untuk memberikan reaksi atau ulasan pada cerita yang telah diterbitkan.
