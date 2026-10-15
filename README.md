# Aplikasi Manajemen Sekolah
**Flutter (Android/iOS) + Laravel API (Sanctum)**

Repositori ini mengimplementasikan sistem manajemen sekolah modern dengan arsitektur terpisah antara **Backend API (Laravel)** dan **Aplikasi Mobile (Flutter)** sesuai dengan spesifikasi di [docs/blueprint-aplikasi-sekolah.md](docs/blueprint-aplikasi-sekolah.md).

---

## 📁 Struktur Repositori

```
Sekolah/
├── .github/workflows/
│   └── build-apk.yml            # CI/CD: Pengujian kode & build release APK otomatis
├── backend/                     # Laravel 11/12 API Backend
│   ├── app/
│   │   ├── Http/Controllers/Api/V1/ # REST API Controllers (Auth, Student, Attendance, Finance, Dashboard)
│   │   └── Models/             # Eloquent Models (UUID Primary Keys, HasApiTokens)
│   ├── database/
│   │   ├── migrations/         # Skema relasional multi-tenant (school_id)
│   │   └── seeders/            # DatabaseSeeder dengan data siap uji
│   ├── docs/
│   │   └── openapi.yaml        # Kontrak OpenAPI 3.0
│   └── routes/api.php          # Rute REST API /api/v1
├── docs/
│   └── blueprint-aplikasi-sekolah.md # Spesifikasi lengkap blueprint
├── mobile/                      # Flutter Stable (Android / iOS)
│   ├── lib/
│   │   ├── app/                # Theme, Router (GoRouter), Shell Scaffold 4-tab
│   │   ├── core/               # ApiClient (Dio), TokenStorage (Secure), Design System
│   │   └── features/           # Auth, Dashboard, Academic, Finance, Attendance (QR Scan)
│   └── pubspec.yaml            # Dependencies Flutter
└── README.md
```

---

## 🚀 Panduan Menjalankan Backend (Laravel)

### 1. Kebutuhan Sistem
- PHP 8.2 / 8.3+ (Ekstensi: `pdo_mysql`, `mbstring`, `openssl`, `curl`)
- MySQL 8.0+ atau MariaDB
- Composer 2.x

### 2. Instalasi & Konfigurasi
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
```

Pastikan koneksi database di `.env` sudah sesuai:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=sekolah_db
DB_USERNAME=root
DB_PASSWORD=
```

### 3. Migrasi & Data Uji (Seeding)
```bash
php artisan migrate:fresh --seed
```

### 4. Akun Uji Coba Bawaan
| Peran | Email / Login | Kata Sandi | Deskripsi |
|---|---|---|---|
| **Admin Sekolah** | `admin@sekolah.sch.id` | `password123` | Akses penuh operasional sekolah & penerbitan Kartu Pelajar |
| **Wali Kelas / Guru** | `guru@sekolah.sch.id` | `password123` | Absensi kelas & pemindai QR Kartu Pelajar |
| **Orang Tua / Siswa** | `wali@sekolah.sch.id` | `password123` | Akses tagihan SPP dan status kehadiran anak |

Token QR Kartu Pelajar uji coba siswa **Ahmad Fauzan**:  
`KP_20261001_TELADAN`

### 5. Menjalankan Server Lokal
```bash
php artisan serve --port=8000
```
API aktif pada: `http://127.0.0.1:8000/api/v1`

### 6. Menjalankan Automated Test
```bash
php artisan test
```

---

## 📱 Panduan Aplikasi Mobile (Flutter)

### 1. Fitur Utama MVP
- **Navigasi 4 Tab:** Beranda, Akademik, Keuangan (SPP), dan Akun.
- **Pindai QR Kartu Pelajar:** Pemindai kamera langsung dengan umpan balik visual instan dan pencegahan duplikasi (*idempotent*).
- **Keamanan Token:** Sanctum personal access token tersimpan aman via `flutter_secure_storage`.
- **State Management:** Riverpod 2.x terstruktur.

### 2. Menjalankan Lokal
```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```
*(Gunakan `http://10.0.2.2:8000/api/v1` untuk Android Emulator atau IP LAN untuk perangkat fisik).*

---

## 🤖 GitHub Actions & Build APK

Repositori dilengkapi alur kerja CI/CD di `.github/workflows/build-apk.yml`.  
Setiap kali ada *push* atau *pull request* ke branch `main`/`develop`, GitHub Actions akan:
1. Menjalankan static analysis (`flutter analyze`) dan unit test (`flutter test`).
2. Melakukan build release APK Android dengan `--dart-define=API_BASE_URL=...`.
3. Mengunggah hasil build sebagai **Artifact** yang dapat langsung diunduh dan dipasang pada perangkat Android untuk pengetesan.

---

## 🌐 Deploy Laravel ke Shared Hosting

1. Unggah seluruh isi folder `backend/` ke direktori privat hosting (di luar `public_html`).
2. Pindahkan isi `backend/public/` ke dalam `public_html/` (atau ubah document root domain ke `backend/public/`).
3. Sesuaikan file `.env` di server dengan kredensial database hosting dan `APP_DEBUG=false`.
4. Jalankan migrasi via SSH/Terminal hosting:
   ```bash
   php artisan migrate --force
   php artisan config:cache
   php artisan route:cache
   ```
