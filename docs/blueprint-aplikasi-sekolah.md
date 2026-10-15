# Blueprint Aplikasi Manajemen Sekolah
**Flutter (Android/iOS) + Laravel API**  
Versi rancangan: 1.0 · Tanggal: 15 Oktober 2026

## 1. Ringkasan keputusan

Rancangan ini mengasumsikan produk untuk satu atau lebih sekolah, dengan dukungan multi-sekolah melalui `school_id` pada data operasional. Akun dapat memiliki beberapa peran, tetapi hanya bekerja dalam sekolah yang sedang dipilih. Semua aturan akses diperiksa ulang oleh Laravel; menyembunyikan tombol di Flutter bukan mekanisme keamanan.

**Stack yang disarankan**
- **Mobile:** Flutter stable, Dart, Material 3, Riverpod untuk state/dependency, go_router untuk navigasi, Dio untuk HTTP, secure storage untuk token, SQLite/Drift atau Isar untuk cache lokal terpilih.
- **Backend:** Laravel API, PHP versi yang didukung rilis Laravel yang dipilih, PostgreSQL (disarankan) atau MySQL, Redis untuk cache/queue, object storage S3-compatible untuk berkas.
- **API:** REST JSON berawalan `/api/v1`, autentikasi token Sanctum, OpenAPI sebagai kontrak bersama.
- **Pekerjaan async:** Laravel queue untuk notifikasi, ekspor, rekonsiliasi pembayaran, dan pengiriman pengumuman massal.
- **Deploy:** Docker/container atau layanan PHP terkelola, TLS, managed database, Redis/queue worker, object storage, backup teruji, monitoring dan log terstruktur.

Sanctum cocok untuk token perangkat mobile; token personal dapat dicabut per perangkat. Jangan menyimpan token plaintext di database aplikasi atau log.

## 2. Ruang lingkup dan prioritas produk

### MVP (rilis pertama)
1. Login, logout, pemulihan akses, pemilihan sekolah/role aktif.
2. Dashboard sesuai role dan periode aktif.
3. Direktori siswa, kelas, tahun ajaran, penempatan siswa.
4. Absensi harian siswa; absensi guru dapat menyusul bila sekolah menghendaki.
5. Jadwal kelas dan pengumuman.
6. Tagihan SPP per siswa/periode, status pembayaran, bukti/riwayat transaksi.
7. Notifikasi dalam aplikasi dan push untuk peristiwa penting.
8. Laporan dasar, audit log untuk perubahan sensitif, impor CSV dengan pratinjau.

### Tahap berikutnya
- Nilai, tugas, rapor; perpustakaan; inventaris; konseling; ekstrakurikuler; izin/cuti; komunikasi wali; PPDB; pembayaran gateway; ekspor akuntansi; multi-bahasa; dashboard analitik.

Batasi MVP agar data siswa, tagihan, absensi, dan jadwal benar-benar konsisten. Hindari membuat modul yang belum memiliki pemilik proses dan definisi data.

## 3. Peran, akses, dan konteks

Modelkan **permission**, bukan pemeriksaan nama role di banyak tempat. Role adalah kumpulan permission dan dapat disesuaikan per sekolah.

| Peran bawaan | Cakupan utama |
|---|---|
| Admin sekolah | Pengaturan sekolah, akun/role, tahun ajaran, master data, seluruh operasional dan laporan |
| Kepala sekolah | Ringkasan sekolah, laporan, pengumuman, persetujuan tertentu; data sensitif sesuai izin |
| Wali kelas | Siswa pada kelas yang ditugaskan, absensi, ringkasan kelas, komunikasi wali |
| Guru kelas/mapel | Jadwal/kelas yang ditugaskan, absensi sesuai kebijakan, materi/nilai tahap lanjut |
| Murid | Data diri terbatas, jadwal, pengumuman, tagihan milik sendiri, absensi/nilai yang boleh dilihat |
| Orang tua/wali | Anak yang ditautkan secara eksplisit, tagihan dan informasi anak; tidak dapat melihat anak lain |

Satu orang tua bisa terkait beberapa siswa; satu siswa bisa memiliki beberapa wali dengan relasi dan hak berbeda. Admin platform (bila ada) dipisahkan dari admin sekolah dan tidak otomatis dapat melihat data akademik.

**Aturan otorisasi**
- Otorisasi server-side melalui middleware autentikasi, policy/Gate, dan scope tenant pada query.
- Setiap record operasional harus difilter oleh `school_id` dan kemudian oleh cakupan kelas/siswa pengguna. Jangan percaya `school_id`, `student_id`, atau `role_id` dari body request tanpa validasi membership.
- Endpoint murid/orang tua mengambil identitas dari token dan relasi wali, bukan menerima ID anak bebas.
- Pisahkan izin baca, buat, ubah, hapus, ekspor, dan persetujuan.
- Perubahan finansial, penghapusan, promosi siswa, impor, dan perubahan role memerlukan audit log dengan aktor, waktu, objek, nilai sebelum/sesudah yang relevan.
- Gunakan prinsip least privilege, MFA untuk admin bila tersedia, pembatasan percobaan login, rotasi/revokasi token, dan verifikasi tambahan untuk tindakan sensitif.

## 4. Arsitektur

```
Flutter app
  ├─ Presentation: halaman, widget, router
  ├─ Application: use cases, state (Riverpod)
  ├─ Domain: entity, value object, repository contract
  └─ Data: DTO, API/local datasource, repository implementation
           │ HTTPS JSON /api/v1
           ▼
Laravel API
  ├─ Auth + permission + tenant/context middleware
  ├─ Controllers tipis → Form Requests → Actions/Services
  ├─ Policies → Eloquent models/repositories bila perlu
  ├─ PostgreSQL/MySQL
  ├─ Queue/Redis → notifikasi, export, webhook, jobs
  └─ Object storage → dokumen/bukti pembayaran
```

**Prinsip batas sistem**
- API adalah sumber kebenaran untuk saldo, role, hak akses, dan status pembayaran.
- Flutter meng-cache data yang aman untuk pengalaman offline; mutasi offline diberi status **menunggu sinkronisasi** dan tidak dianggap berhasil sampai server mengonfirmasi.
- Gunakan pagination, filter, sort yang di-whitelist, dan response konsisten. Jangan mengirim seluruh tabel siswa ke perangkat.
- Versikan kontrak API, dokumentasikan error dan enum. Gunakan idempotency key untuk operasi pembayaran/import yang dapat terulang.
- Push notification hanya memberi sinyal bahwa data berubah; aplikasi mengambil data terbaru lewat API.

### Contoh kontrak response
```json
{
  "data": { "id": "uuid", "name": "Contoh" },
  "meta": { "request_id": "..." }
}
```
Kesalahan validasi: HTTP 422 dengan `message` dan `errors` per field; 401 untuk belum login; 403 untuk tidak berhak; 404 untuk objek yang tidak tersedia dalam cakupan pengguna; 409 untuk konflik versi/status; 429 untuk rate limit.

## 5. Rancangan UI/UX

Gunakan gaya dashboard dengan **kartu layanan besar dan akses cepat** yang terasa akrab seperti aplikasi layanan sehari-hari, tetapi pertahankan identitas sekolah yang tenang dan mudah dibaca. Jangan menyalin merek atau aset Gojek.

### Navigasi inti mobile
Bottom navigation 4 tab:
1. **Beranda**
2. **Akademik**
3. **Keuangan**
4. **Akun**

Tampilkan tombol **Lainnya** atau grid layanan di Beranda untuk modul lain. Isi menu ditentukan role; pencarian tersedia pada daftar panjang.

### Dashboard
- Header: salam/nama, sekolah aktif, tahun ajaran/semester, avatar dan notifikasi.
- Kartu konteks: kelas untuk wali/guru; anak terpilih untuk orang tua; status ringkas untuk admin/kepala sekolah.
- Grid layanan 2×N: Siswa, Absensi, Jadwal, SPP, Pengumuman, Nilai (jika aktif), Laporan.
- Ringkasan personal: tagihan jatuh tempo, absensi hari ini, jadwal berikutnya, pengumuman terbaru.
- Aksi utama kontekstual, misalnya “Isi absensi kelas” untuk wali.
- Jangan tampilkan metrik yang tak dapat dipahami atau dihitung konsisten.

### Pola halaman penting
- **Login:** nomor telepon/email + kata sandi, opsi lupa kata sandi, indikator sekolah bila akun multi-sekolah; jangan ungkap apakah suatu email terdaftar.
- **Daftar siswa:** pencarian, filter kelas/status, kartu ringkas, detail ber-tab (profil, wali, riwayat kelas, absensi, tagihan). Lindungi NISN/identitas sensitif.
- **Absensi:** pilih kelas dan tanggal, daftar siswa dengan pilihan hadir/izin/sakit/alpa, aksi “Tandai semua hadir”, catatan opsional, simpan dengan ringkasan jumlah dan konfirmasi. Hindari salah tanggal melalui header tanggal eksplisit.
- **SPP:** daftar periode dan status, rincian invoice dengan komponen biaya, batas waktu, instruksi pembayaran dan riwayat; status lunas hanya dari transaksi terverifikasi atau pencatatan kasir yang teraudit.
- **Jadwal:** tampilan hari/minggu yang nyaman di ponsel, zona waktu sekolah, konflik jadwal jelas.
- **Pengumuman:** prioritas, tanggal berlaku, lampiran, audiens; tandai telah dibaca bila diperlukan.

### Aksesibilitas dan keadaan UI
Kontras memadai, teks dapat diperbesar, label semantik untuk screen reader, area sentuh lega, bahasa Indonesia sederhana. Semua layar daftar memiliki loading, empty, error/retry, dan stale/offline state. Form memiliki validasi inline dan konfirmasi saat meninggalkan perubahan. Hindari warna sebagai satu-satunya pembeda status.

### Absensi dengan QR pada Kartu Pelajar

Gunakan istilah **Kartu Pelajar** atau **Kartu Identitas Pelajar** pada aplikasi dan dokumen sekolah. “KTA” dapat dipakai bila sekolah memang menyebutnya kartu anggota, tetapi istilah umum yang mudah dipahami adalah Kartu Pelajar. Hindari “AOA” karena bukan istilah kartu siswa yang lazim.

**Bentuk kartu:** kartu fisik (cetak) dengan foto, nama, kelas aktif, nama sekolah, nomor induk yang memang boleh dicetak menurut kebijakan sekolah, dan QR. Jangan menaruh alamat, tanggal lahir lengkap, nomor telepon wali, atau data pribadi sensitif pada QR. QR sebaiknya berisi token acak yang tidak bermakna (opaque identifier), bukan NISN, nomor induk yang berurutan, nama, atau data profil. Token dipetakan ke siswa hanya di server dan dapat dicabut/regenerasi jika kartu hilang. Untuk keamanan lebih, tampilkan juga masa berlaku/kondisi kartu dan identitas visual sekolah.

**Alur absensi di aplikasi guru/wali kelas**
1. Pengguna yang berizin membuka Akademik → Absensi → Scan Kartu Pelajar, memilih kelas/sesi dan tanggal yang aktif.
2. Aplikasi meminta izin kamera dan memindai QR; hasil scan menampilkan nama/foto/kelas siswa yang cocok agar guru dapat memastikan identitas, lalu mencatat hadir.
3. Backend memvalidasi token kartu aktif, membership sekolah pengguna, penugasan kelas, enrollment siswa pada kelas/tahun ajaran aktif, sesi absensi yang benar, dan belum ada catatan hadir untuk siswa pada sesi tersebut.
4. API mengembalikan hasil berhasil, duplikat, kartu tidak aktif, siswa di luar kelas, sesi tutup, atau gagal jaringan secara jelas. Scan berulang dibuat idempotent dan tidak membuat catatan ganda.
5. Guru dapat menandai izin/sakit/alpa secara manual sesuai hak; perubahan setelah sesi dikirim harus menyertakan alasan dan dicatat di audit log.
6. Bila jaringan putus, aplikasi boleh menyimpan antrean scan lokal bertanda **belum tersinkron** dengan waktu perangkat, lalu mengirim ulang memakai idempotency key saat online. Tampilkan status pending; jangan menyatakan absensi sudah sah sampai server menerima. Kebijakan waktu offline, konflik, dan validasi jam perangkat perlu diputuskan sekolah.

**Fallback operasional:** pencarian nama/nomor induk oleh petugas yang berizin bila kamera/QR gagal; setiap pencatatan manual menyimpan aktor, waktu, alasan, dan sumber input. Kartu hilang dilaporkan admin, token lama dinonaktifkan, lalu token baru diterbitkan dan kartu dicetak ulang. Sediakan proses koreksi bila siswa lupa kartu.

**Catatan keamanan:** gunakan QR bertanda tangan/opaque token berentropi tinggi, hindari QR statis yang membocorkan identifier siswa. QR statis dapat difoto atau disalin; karena itu scan hanya menyatakan kartu dipresentasikan dan tidak membuktikan pemegangnya adalah siswa. Guru perlu memeriksa foto/nama. Jika risiko pemalsuan tinggi, gunakan QR yang berubah berkala atau verifikasi tambahan yang disepakati sekolah. Jangan memasukkan token autentikasi akun atau rahasia backend ke kartu.

**Endpoint yang disarankan**
- POST /api/v1/attendance/scans dengan card_token, session_id, idempotency_key; identitas aktor berasal dari token login.
- POST /api/v1/students/{student}/cards/issue dan POST /api/v1/student-cards/{card}/revoke untuk admin berizin; token mentah hanya diberikan saat penerbitan untuk dibuat QR/cetak, lalu backend menyimpan hash token.
- GET /api/v1/attendance/sessions/{session}/records untuk melihat hasil sesi sesuai cakupan akses.

**Tambahan skema data**
- student_cards: id, school_id, student_id, token_hash unik, issued_at, expires_at nullable, revoked_at nullable, issued_by, replaced_card_id nullable. Simpan hash token, bukan token QR plaintext.
- attendance_records dapat menambah source (qr/manual), device_id opsional, dan idempotency_key unik dalam cakupan yang sesuai. Catat petugas dan waktu server.
- Kebijakan satu kartu aktif per siswa dapat ditegakkan dengan validasi transaksi/indeks parsial bila database mendukung.

Tambahkan menu Kartu Pelajar pada profil siswa admin: terbitkan, pratinjau/unduh untuk cetak, nonaktifkan, dan cetak ulang. Pada MVP, QR dapat dicetak sebagai PDF dari backend atau panel admin; aplikasi mobile guru tetap menjadi pemindai.

## 6. Database relasional

Gunakan primary key UUID/ULID untuk entitas yang terekspos API, foreign key, indeks, timestamps, soft delete hanya bila kebijakan retensi mendukung. Simpan waktu dalam UTC; tanggal akademik/absensi adalah tipe DATE sesuai kalender sekolah. Uang gunakan integer rupiah (bukan float) dan mata uang eksplisit bila kelak multi-mata-uang. Terapkan constraint unik dan transaksi database.

### Entitas inti

| Tabel | Kolom penting / aturan |
|---|---|
| `schools` | id, code unik, name, timezone, settings JSON terbatas, status |
| `users` | id, name, email/phone unik sesuai kebijakan, password_hash, status, last_login_at |
| `school_memberships` | id, school_id, user_id, status; unik (school_id,user_id) |
| `roles`, `permissions`, `role_permissions` | role dan permission; role global atau school-scoped sesuai implementasi |
| `membership_roles` | membership_id, role_id; opsional scope kelas pada assignment terpisah |
| `academic_years` | school_id, name, starts_on, ends_on, is_active |
| `semesters` | academic_year_id, name, starts_on, ends_on |
| `students` | school_id, admission_no, nisn nullable, name, birth_date, gender, status; admission_no unik per sekolah |
| `guardians` | school_id, user_id nullable, name, phone, email |
| `student_guardians` | student_id, guardian_id, relationship, is_primary, portal_access; unik pasangan |
| `classes` | school_id, academic_year_id, name, grade_level |
| `class_enrollments` | student_id, class_id, starts_on, ends_on, status; cegah enrollment aktif ganda |
| `subjects` | school_id, code, name |
| `teaching_assignments` | class_id, subject_id nullable, teacher_membership_id |
| `attendance_sessions` | school_id, class_id, date, created_by, status; unik (class_id,date,session_type) |
| `attendance_records` | session_id, student_id, status, note, marked_by, marked_at; unik (session_id,student_id) |
| `timetables` | school_id, class_id, subject_id, teacher_membership_id, weekday, starts_at, ends_at, room, valid_from/to |
| `fee_types` | school_id, code, name, default_amount, active |
| `invoices` | school_id, student_id, period, invoice_no, due_on, total_amount, status; invoice_no unik per sekolah |
| `invoice_items` | invoice_id, fee_type_id, description, quantity, unit_amount, line_amount |
| `payments` | school_id, invoice_id, amount, method, status, reference, paid_at, recorded_by |
| `payment_events` | payment_id, source, event_id unik, payload_hash, received_at; hindari proses webhook ganda |
| `announcements` | school_id, title, body, published_at, expires_at, created_by, status |
| `announcement_audiences` | announcement_id, audience_type, class_id nullable |
| `announcement_reads` | announcement_id, user_id, read_at; unik pasangan |
| `device_tokens` | user_id, device_id, token terenkripsi/terproteksi, platform, last_seen_at |
| `audit_logs` | school_id, actor_user_id, action, subject_type/id, before/after JSON teredaksi, request_id, created_at |

### Relasi dan integritas penting
- `school_id` masuk ke tabel domain sekolah; validasi konsistensinya saat membuat relasi (composite FK jika skema memungkinkan, atau validasi service + constraint).
- Jangan hard delete pembayaran, invoice lunas, catatan absensi, atau audit. Gunakan pembatalan/void dengan alasan, aktor, waktu.
- Invoice menyimpan snapshot nama/nominal item saat diterbitkan agar perubahan master biaya tidak mengubah tagihan lama.
- Saldo dihitung dari invoice dan pembayaran yang sah, bukan kolom saldo yang dapat diedit bebas. Jika menyimpan cache saldo, rekonsiliasi dan audit wajib.
- Hindari menyimpan data kartu. Gunakan hosted checkout/token dari payment gateway; verifikasi tanda tangan webhook dan idempotensi.
- Indeks minimal: semua FK; `(school_id, admission_no)`; `(class_id,date)`; `(student_id,period)`; `(school_id,status,due_on)`; `(user_id,created_at)` untuk notifikasi.

## 7. Struktur project

### Flutter
```
mobile/
  lib/
    app/                 # app bootstrap, router, theme, localization
    core/
      api/               # Dio, auth interceptor, error mapping
      auth/              # secure token, session, permission-aware routing
      database/           # local database & migrations
      design_system/     # colors, typography, components
      platform/           # push, file picker, permissions
      utils/
    features/
      auth/{data,domain,presentation}/
      dashboard/{data,domain,presentation}/
      students/{data,domain,presentation}/
      attendance/{data,domain,presentation}/
      finance/{data,domain,presentation}/
      timetable/{data,domain,presentation}/
      announcements/{data,domain,presentation}/
      account/{data,domain,presentation}/
    l10n/
    main.dart
  test/
  integration_test/
  android/
  ios/
```
Setiap fitur memuat model/domain seperlunya, repository, use case yang punya aturan, provider/state, halaman dan widget. Jangan membuat lapisan abstraksi kosong untuk semua widget. DTO API dipisah dari entity domain bila mapping/validasi bermanfaat.

### Laravel
```
backend/
  app/
    Actions/             # alur bisnis lintas model
    Enums/
    Http/
      Controllers/Api/V1/
      Middleware/
      Requests/Api/V1/
      Resources/Api/V1/
    Jobs/
    Listeners/
    Models/
    Policies/
    Notifications/
    Services/            # gateway pembayaran, storage, push
  database/
    migrations/
    seeders/
    factories/
  routes/api.php
  tests/Feature/Api/V1/
  tests/Unit/
  docs/openapi.yaml
```
Controller mengatur HTTP, Form Request memvalidasi input, Policy mengecek izin, Action/service menjalankan transaksi bisnis, Resource mengatur bentuk response. Jangan menaruh aturan bisnis penting di controller atau hanya di aplikasi mobile.

## 8. API awal

- `POST /api/v1/auth/login`, `POST /auth/logout`, `POST /auth/forgot-password`, `GET /me`
- `GET /schools`, `POST /active-school` (memeriksa membership dan menerbitkan konteks server)
- `GET /dashboard`
- `GET/POST /students`, `GET/PATCH /students/{student}`
- `GET /classes`, `GET /classes/{class}/students`
- `GET /attendance?class_id=&date=`, `PUT /attendance/sessions/{session}`
- `GET /timetable?class_id=&from=&to=`
- `GET /invoices?student_id=&status=&period=`, `GET /invoices/{invoice}`
- `POST /invoices/{invoice}/payments` atau `POST /payment-intents`; callback gateway terpisah dan ditandatangani
- `GET/POST /announcements`, `POST /announcements/{id}/read`
- `GET /reports/attendance`, `GET /reports/finance` (akses ekspor terbatas)

Semua daftar menggunakan `page/per_page` dengan batas maksimum, filter divalidasi, dan sorting whitelist. Gunakan optimistic concurrency/version atau pemeriksaan status untuk absensi dan pembayaran yang dapat diedit bersamaan.

## 9. Keamanan, privasi, dan operasi

- HTTPS wajib; konfigurasi CORS terbatas; secret hanya di secret manager/environment deployment.
- Password di-hash memakai mekanisme Laravel terkini (Argon2id/bcrypt yang dikonfigurasi), MFA untuk admin direkomendasikan; reset password bertoken singkat dan sekali pakai.
- Rate limit login, OTP, pencarian sensitif, ekspor, dan endpoint publik; deteksi brute force tanpa membocorkan keberadaan akun.
- Validasi tipe/ukuran berkas, scan malware bila fasilitas tersedia, simpan privat dan sajikan lewat URL bertanda tangan singkat.
- Enkripsi backup dan media sensitif, minimalkan PII di log, atur retensi serta akses staf. Jangan log token, password, isi dokumen, atau nomor identitas lengkap.
- Audit akses dan ekspor data sensitif. Sediakan prosedur koreksi/penghapusan sesuai kebijakan sekolah serta hukum yang berlaku.
- Backup database harian/incremental, uji pemulihan berkala, RPO/RTO disepakati. Metrik: error API, latency, queue lag, kegagalan push, webhook tertunda, backup terakhir.
- Pisahkan environment dev/staging/production, gunakan akun dan kredensial terpisah. Jalankan migrasi terencana dan backward-compatible.
- Konfirmasi kebijakan perlindungan data anak, persetujuan orang tua, masa simpan, dan lokasi pemrosesan sebelum produksi; sesuaikan implementasi dengan kewajiban hukum Indonesia yang berlaku.

## 10. Tahapan implementasi

1. **Discovery (1–2 minggu):** wawancara admin, bendahara, guru, kepala sekolah, orang tua; petakan alur absensi/SPP; definisikan istilah, kebijakan koreksi dan tahun ajaran; tetapkan MVP dan acceptance criteria.
2. **Fondasi (1–2 minggu):** repo, CI, dev/staging, desain sistem, OpenAPI, skema awal, auth, tenant context, role-permission, audit.
3. **Master data (1–2 minggu):** sekolah, kelas, tahun ajaran, siswa, wali, impor CSV dengan validasi/pratinjau/rollback.
4. **Akademik MVP (2–3 minggu):** assignment guru, jadwal, absensi, pengumuman, notifikasi.
5. **Keuangan MVP (2–3 minggu):** fee, pembuatan invoice, pembayaran tunai/manual teraudit; setelah rekonsiliasi matang baru gateway.
6. **Mobile polish (1–2 minggu):** offline read cache terpilih, accessibility, analytics privasi, error/empty states, onboarding.
7. **Pilot & hardening (2–3 minggu):** satu sekolah/kelas, migrasi data percobaan, UAT, perbaikan, pentest/review akses, load dan backup-restore rehearsal.
8. **Rilis bertahap:** internal → pilot → persentase pengguna kecil → seluruh sekolah; pantau crash/error, sediakan rollback backend dan prosedur dukungan.

Durasi hanya estimasi tim; bergantung jumlah engineer, kesiapan proses, integrasi pembayaran dan kualitas data awal.

## 11. Pengujian dan kriteria penerimaan

### Backend
- Unit test untuk kalkulasi tagihan, status invoice, aturan periode, pembatasan enrollment.
- Feature/API test untuk autentikasi, validasi, filter tenant, Policy semua role, dan relasi orang tua-anak.
- Uji eksplisit akses silang sekolah, ID siswa yang ditebak, ekspor tanpa izin, token dicabut, request berulang, webhook duplikat/berurutan tidak sesuai.
- Uji migrasi dan seed pada database kosong serta data upgrade yang representatif.

### Flutter
- Unit test provider/use case/repository mapping dan validasi form.
- Widget test untuk dashboard per role, empty/error/loading, perubahan ukuran teks, dan form absensi.
- Integration test login → pilih konteks → catat absensi → lihat jadwal/invoice; gunakan backend staging atau mock yang kontraknya konsisten.
- Uji perangkat Android/iOS, jaringan lambat/offline, token kedaluwarsa, zona waktu, rotasi/lifecycle, notifikasi, upload lampiran.

### Penerimaan MVP
- Tidak ada pengguna yang bisa membaca data tenant lain atau siswa yang tidak terkait.
- Absensi unik per siswa per sesi; koreksi tercatat.
- Nominal invoice stabil setelah diterbitkan; pembayaran tidak bisa terduplikasi oleh retry/webhook.
- Dashboard hanya menampilkan data dalam cakupan role aktif.
- Alur inti selesai dengan aksesibilitas dasar dan pesan kegagalan yang dapat ditindaklanjuti.

## 12. Deployment backend

1. Siapkan domain/API, DNS, TLS, firewall dan jaringan privat untuk database.
2. Buat environment production; rahasia via secret manager; konfigurasi `APP_ENV=production`, `APP_DEBUG=false`, URL tepercaya, mail, storage, database, queue, cache.
3. Jalankan image/build yang sama dengan staging; pasang dependencies terkunci dan optimasi cache konfigurasi/route sesuai proses Laravel.
4. Jalankan migrasi terkontrol (`php artisan migrate --force`), seed hanya data referensi aman, jangan seed akun default berpassword umum.
5. Jalankan PHP-FPM/runtime dan web server, queue worker via supervisor/orchestrator, scheduler Laravel setiap menit, serta health/readiness check.
6. Pastikan penyimpanan upload privat, backup otomatis terenkripsi, pemantauan, log dan alert sudah aktif sebelum data produksi masuk.
7. Uji login, tenant isolation, upload, job queue, email/push, webhook di sandbox, restore backup, dan rollback sebelum go-live.
8. Setelah rilis, monitor error/latency/queue dan sediakan kanal support serta prosedur insiden.

## 13. Build aplikasi

### Android APK untuk uji langsung
Persiapan: Flutter SDK stable dan Android SDK terpasang, package/application ID final, signing key disimpan aman di luar repository, API base URL environment terkonfigurasi, serta izin Android minimal. Untuk debug/internal QA:
```bash
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.sch.id/api/v1
```
APK universal biasanya berada di `build/app/outputs/flutter-apk/app-release.apk`. Untuk distribusi Google Play, gunakan AAB:
```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.sch.id/api/v1
```
Hasil biasanya di `build/app/outputs/bundle/release/app-release.aab`. Atur version/build number, signing release, ikon, label, kebijakan privasi, dan target SDK sesuai persyaratan toko saat rilis. Jangan commit keystore atau password signing; simpan dalam CI secret/secure storage dan siapkan proses rotasi/backup.

### iOS IPA
Build iOS memerlukan **macOS dengan Xcode**, Apple Developer account, Bundle ID, signing certificate/provisioning profile, dan konfigurasi notification capability bila memakai push. Windows saja tidak dapat menghasilkan IPA iOS yang ditandatangani; gunakan Mac lokal atau CI Mac yang dikelola.
```bash
flutter doctor
flutter pub get
flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.sch.id/api/v1
```
IPA/archive tersedia di bawah `build/ios/ipa/` (tergantung konfigurasi Xcode). Atur signing melalui Xcode/CI, uji di TestFlight, lengkapi privacy manifest/label privasi dan review guideline Apple sesuai kondisi rilis. Uji endpoint production dengan konfigurasi aman; jangan menanam secret server di app karena dapat diekstrak.

### Checklist sebelum distribusi
- App ID, versi, ikon, splash, nama sekolah/produk dan lingkungan API benar.
- Akun admin awal dibuat melalui proses aman; MFA dan pemulihan diuji.
- Tidak ada token/secret uji di build; komunikasi HTTPS dan file privat.
- Crash reporting tidak memuat PII; privacy policy dan kontak dukungan tersedia.
- APK/AAB diuji di perangkat nyata; iOS diuji lewat TestFlight.
- Backup/restore, monitoring, alert dan rollback diuji.

## 14. Keputusan yang perlu disepakati sebelum coding

1. Jenis sekolah dan aturan akademik: semester, kelas paralel, sesi absensi, kalender/libur.
2. Apakah aplikasi awal hanya satu sekolah atau SaaS multi-sekolah; siapa admin platform.
3. Login dengan email, nomor telepon, NISN, atau kombinasi; kebijakan akun anak.
4. Alur SPP: tunai/transfer/gateway, denda/diskon, cicilan, tunggakan dan rekonsiliasi.
5. Apakah absensi perlu persetujuan/koreksi; siapa boleh mengubah setelah submit.
6. Data awal yang tersedia, migrasi, format ekspor dan retensi.
7. Provider push, email/SMS/WhatsApp dan anggaran layanan.
8. Kepemilikan domain, hosting, akun Google Play dan Apple Developer.
9. Target rilis, ukuran tim, perangkat minimum, dukungan offline dan kebijakan privasi anak.

Dokumen ini merupakan blueprint awal. Sebelum implementasi final, validasikan aturan sekolah, kontrak API, kebijakan keuangan, keamanan, privasi, dan persyaratan toko aplikasi dengan pemangku kepentingan.

## 15. Alur kerja Antigravity, GitHub Actions, dan shared hosting

Blueprint ini dapat dipakai sebagai spesifikasi proyek di Antigravity. Minta Antigravity mengimplementasikan pekerjaan secara bertahap dan mengikuti keputusan dalam dokumen, bukan menghasilkan seluruh sistem sekaligus tanpa pengujian.

### Pembagian tanggung jawab
- **Antigravity:** membantu membuat dan mengubah source code Flutter dan Laravel, dokumentasi, serta konfigurasi deployment. Perubahan harus ditinjau sebelum digabung ke branch utama.
- **GitHub repository:** menyimpan source code dan riwayat perubahan. Database produksi tidak disimpan di GitHub.
- **GitHub Actions:** menjalankan pemeriksaan dan build Flutter Android dari source code. Workflow dapat menghasilkan APK sebagai artifact untuk diunduh; bila nanti merilis melalui Google Play, siapkan build AAB dan proses distribusinya.
- **Shared hosting:** menjalankan Laravel API melalui HTTPS dan menyediakan/mengakses database produksi melalui fasilitas hosting. Backup database disiapkan di hosting atau layanan backup terpisah.

### Tahapan implementasi yang disarankan di Antigravity
1. Tambahkan blueprint ini ke repository sebagai dokumen spesifikasi, misalnya `docs/blueprint-aplikasi-sekolah.md`.
2. Minta Antigravity meninjau struktur repository dan membuat fondasi Flutter serta Laravel, konfigurasi lokal, contoh environment tanpa secret, dan instruksi menjalankan masing-masing proyek.
3. Implementasikan modul satu demi satu: autentikasi dan role; sekolah/kelas/siswa dan wali; penerbitan Kartu Pelajar QR dan scan absensi; jadwal/pengumuman; lalu invoice dan pembayaran.
4. Setelah tiap modul selesai, jalankan pemeriksaan dan pengujian yang relevan, periksa perubahan, baru gabungkan ke branch yang digunakan GitHub Actions.
5. Bangun dan uji APK internal menggunakan API staging; deploy backend ke staging hosting terlebih dahulu sebelum production.

### GitHub Actions untuk APK
Workflow Android umumnya berjalan pada runner Ubuntu dan menyiapkan Flutter SDK/JDK yang diperlukan, mengambil dependencies, menjalankan analyze dan test, lalu membangun release APK. Simpan hasil APK sebagai workflow artifact dengan masa retensi yang sesuai. Untuk distribusi Play Store, workflow dapat membangun AAB.

Konfigurasikan signing release dengan GitHub Secrets/secure files dan batasi akses ke workflow/branch yang dipercaya. Jangan commit keystore, password signing, access token, file environment production, atau kredensial database ke repository. URL API bukan secret, tetapi gunakan URL staging dan production yang tepat melalui konfigurasi build. Jangan menanam kredensial admin atau secret server ke dalam aplikasi mobile.

### Deploy Laravel ke shared hosting
Sebelum memilih dan mengonfigurasi hosting, verifikasi dukungan versi PHP dan ekstensi yang dibutuhkan versi Laravel yang dipakai, Composer/deployment workflow, document root yang dapat diarahkan ke folder `public`, HTTPS, konfigurasi environment, ukuran/timeout request, koneksi database, scheduler, queue worker, dan akses log. Fitur shared hosting berbeda-beda; bila queue worker permanen atau scheduler tidak didukung, pilih alternatif hosting atau proses terjadwal yang disediakan host.

- Arahkan domain/subdomain API ke Laravel melalui HTTPS. Web root harus melayani folder `public`, bukan root repository yang berisi file sensitif.
- Simpan konfigurasi production dalam environment/fitur secret hosting; atur debug nonaktif, kunci aplikasi yang aman, database, mail, storage, dan URL tepercaya.
- Database dibuat melalui panel hosting. Jalankan migrations melalui mekanisme deployment yang tersedia dan aman; jangan mengandalkan menjalankan perintah destruktif secara otomatis pada setiap request.
- Pastikan folder storage/cache memiliki izin yang tepat. Simpan upload secara privat; jangan menaruh berkas sensitif pada folder publik.
- Siapkan queue dan scheduler yang dibutuhkan notifikasi/ekspor. Bila host memiliki batasan, dokumentasikan pekerjaan yang belum dapat berjalan.
- Aktifkan backup database berkala dan uji pemulihan. Batasi akses panel, gunakan password kuat dan MFA bila tersedia.
- Deploy bertahap ke staging, uji health endpoint, login, otorisasi lintas sekolah, scan QR, database, dan log; setelah lolos barulah arahkan aplikasi ke API production.

### Alur rilis dan cara mendapatkan APK
1. Perubahan kode digabung ke branch rilis yang menjalankan workflow.
2. GitHub Actions membangun APK release dan mempublikasikannya sebagai artifact pada run tersebut.
3. Unduh artifact APK dari halaman run GitHub Actions, lalu pasang untuk uji internal pada perangkat Android.
4. Pastikan API production tersedia melalui HTTPS dan APK dikonfigurasi menunjuk ke base URL production.
5. Setelah uji dan signing siap, bagikan APK secara aman atau buat AAB untuk Google Play.

APK baru tersedia setelah source code, workflow, konfigurasi signing, dan build berhasil. Workflow build APK tidak otomatis membuat atau meng-host Laravel API; deployment API dan database adalah proses terpisah. iOS juga memerlukan runner macOS/Xcode serta signing Apple Developer, bukan runner Android/Linux biasa.
