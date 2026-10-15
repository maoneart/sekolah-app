import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/design_system/app_colors.dart';

class StudentQrCardScreen extends ConsumerStatefulWidget {
  const StudentQrCardScreen({super.key});

  @override
  ConsumerState<StudentQrCardScreen> createState() => _StudentQrCardScreenState();
}

class _StudentQrCardScreenState extends ConsumerState<StudentQrCardScreen> {
  int _selectedChildIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    // Check if user is parent with multiple children or a student
    final children = user?.children ?? [];
    final bool isParent = children.isNotEmpty;

    // Determine current active card data
    Map<String, dynamic> activeStudent;
    if (isParent) {
      final safeIndex = _selectedChildIndex.clamp(0, children.length - 1);
      activeStudent = children[safeIndex];
    } else {
      activeStudent = user?.student ?? {
        'student_name': user?.name ?? 'Ahmad Fauzan',
        'nisn': '0089123456',
        'admission_no': '20261001',
        'class_name': 'Kelas 1A',
        'gender': 'Laki-laki',
        'birth_date': '14 Mei 2019',
        'address': 'Jl. Melati No. 15, RT 02/RW 04, Jakarta Barat',
        'school_name': 'SD Negeri 1 Teladan',
        'card_number': 'KP-SD-2026-0001',
        'qr_token': 'KP_20261001_TELADAN',
      };
    }

    final studentName = activeStudent['name'] ?? activeStudent['student_name'] ?? 'Siswa SD';
    final nisn = activeStudent['nisn'] ?? '0089123456';
    final nis = activeStudent['admission_no'] ?? '20261001';
    final className = activeStudent['class_name'] ?? 'Kelas 1A SD';
    final gender = activeStudent['gender'] ?? 'Laki-laki';
    final birthDate = activeStudent['birth_date'] ?? '14 Mei 2019';
    final address = activeStudent['address'] ?? 'Jl. Melati No. 15, Jakarta';
    final cardNumber = activeStudent['card_number'] ?? 'KP-SD-2026-0001';
    final qrToken = activeStudent['qr_token'] ?? 'KP_20261001_TELADAN';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Kartu Pelajar Siswa SD',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Cetak Kartu',
            onPressed: () => _showPrintDialog(context, studentName, cardNumber),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Membagikan kartu $studentName')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // If parent has 2 children, render Child Switcher Tabs!
            if (isParent && children.length > 1) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(children.length, (index) {
                    final isSelected = index == _selectedChildIndex;
                    final child = children[index];
                    final childName = child['name'] ?? 'Anak ${index + 1}';
                    final childClass = child['class_name'] ?? '';

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedChildIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                childName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                childClass,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // DIGITAL ID CARD (PVC Proportion & Rich Aesthetics)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                children: [
                  // Card Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.school, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KARTU TANDA PELAJAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                'SD NEGERI 1 TELADAN',
                                style: TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'NPSN: 20108921 · Akreditasi A',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusPresent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AKTIF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card Body: Details & QR Barcode
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student Avatar / Photo
                            Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white30, width: 1.5),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.person, size: 48, color: Colors.white),
                                      const SizedBox(height: 4),
                                      Text(
                                        className,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _InfoRow(label: 'NISN', value: nisn),
                                  _InfoRow(label: 'NIS', value: nis),
                                  _InfoRow(label: 'Kelas', value: className),
                                  _InfoRow(label: 'Jenis Kelamin', value: gender),
                                  _InfoRow(label: 'Tgl Lahir', value: birthDate),
                                  _InfoRow(label: 'Tgl Masuk', value: activeStudent['admission_date'] ?? '15 Juli 2026'),
                                  _InfoRow(label: 'Tgl Lulus', value: activeStudent['graduation_date'] ?? 'Belum Lulus (Aktif)'),
                                  _InfoRow(label: 'Alamat', value: address),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 16),

                        // QR Code Barcode Container
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: qrToken,
                                version: QrVersions.auto,
                                size: 160.0,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cardNumber,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tunjukkan Barcode QR ini ke petugas / guru saat masuk gerbang atau absensi kelas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Print / Download Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded),
                label: const Text(
                  'Cetak / Unduh Kartu Pelajar (PDF)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusPresent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showPrintDialog(context, studentName, cardNumber),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text(
                  'Cek Riwayat Scan Absensi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Presensi hari ini telah tercatat: Hadir pukul 07:12 WIB')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrintDialog(BuildContext context, String studentName, String cardNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cetak Kartu Siswa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Siap mencetak Kartu Pelajar untuk:'),
            const SizedBox(height: 8),
            Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Nomor Kartu: $cardNumber', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            const Text(
              'Format kartu standar CR-80 (85.6 mm x 54 mm) siap dikirimkan ke mesin pencetak kartu atau disimpan sebagai dokumen PDF.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Cetak Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.statusPresent,
                  content: Text('Perintah cetak kartu $studentName berhasil dikirim!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.white70, fontSize: 11)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
