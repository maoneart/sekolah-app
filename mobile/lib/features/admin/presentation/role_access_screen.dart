import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_colors.dart';

class RoleAccessScreen extends ConsumerStatefulWidget {
  const RoleAccessScreen({super.key});

  @override
  ConsumerState<RoleAccessScreen> createState() => _RoleAccessScreenState();
}

class _RoleAccessScreenState extends ConsumerState<RoleAccessScreen> {
  final Map<String, List<String>> _rolePermissions = {
    'Super Administrator': [
      'Kelola Matriks Hak Akses & Role',
      'Kelola Master Data Sekolah SD',
      'Kelola Data Siswa & Rombel',
      'Kelola SPP & Laporan Keuangan',
      'Monitoring Seluruh Absensi & Kelas',
    ],
    'Admin Sekolah': [
      'Input & Kelola Data Siswa SD',
      'Input & Kelola Daftar Kelas SD',
      'Terbitkan & Cetak Kartu Barcode Siswa',
      'Buat Tagihan & Catat SPP',
      'Scan Presensi QR Siswa',
    ],
    'Kepala Sekolah': [
      'Sampaikan Pengumuman Terarah (Bisa Pilih Role)',
      'Pantau Rekap Absensi Siswa & Guru SD',
      'Pantau Laporan Keuangan SPP',
      'Monitoring Aktivitas Seluruh Kelas',
    ],
    'Wali Kelas SD': [
      'Kelola Kelas Binaan (Kelas 1A)',
      'Input Jadwal Pelajaran & Guru Mapel',
      'Scan Presensi Harian Siswa Kelas',
      'Lihat Siswa & Rapor Kelas',
    ],
    'Guru Mapel SD': [
      'Lihat Jadwal Mengajar Sesuai Mapel',
      'Scan Presensi Pada Jam Mengajar',
      'Beri Nilai & Evaluasi Mapel',
    ],
    'Orang Tua (Wali Murid)': [
      'Lihat Kartu Barcode Anak (Bisa Switch 2 Siswa)',
      'Cetak Kartu Siswa (PDF / CR-80)',
      'Lihat Notifikasi & Tagihan SPP 2 Anak',
      'Pantau Kehadiran Harian Anak',
    ],
    'Murid (Siswa SD)': [
      'Tampilkan Barcode Kartu Siswa Untuk Di-Scan',
      'Cetak Kartu Siswa',
      'Lihat Jadwal Belajar Kelas',
      'Lihat Riwayat Tagihan SPP',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Aturan Hak Akses & Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Super Administrator memiliki kontrol penuh untuk menentukan menu dan wewenang yang dapat dibuka oleh masing-masing peran di SD.',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._rolePermissions.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.badge, color: AppColors.primary),
                ),
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('${entry.value.length} Izin Akses Aktif', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entry.value.map((perm) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: AppColors.statusPresent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(perm, style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
