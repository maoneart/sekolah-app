import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/design_system/app_colors.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedChildIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final userName = user?.name ?? 'Pengguna';
    final schoolName = user?.activeSchoolName ?? 'SD Negeri 1 Teladan';
    const academicPeriod = '2026/2027 · Semester Ganjil (SD)';

    final roles = user?.roles ?? [];
    final isSuperAdmin = roles.contains('super_admin');
    final isAdmin = roles.contains('admin_sekolah');
    final isKepsek = roles.contains('kepala_sekolah');
    final isWaliKelas = roles.contains('wali_kelas');
    final isGuru = roles.contains('guru');
    final isMurid = roles.contains('murid');
    final isOrangTua = roles.contains('orang_tua');

    final dashConfig = user?.dashboardConfig ?? {};
    final roleLabel = dashConfig['role_label'] ?? (roles.isNotEmpty ? roles.first : 'Warga Sekolah');
    final roleBadge = dashConfig['badge'] ?? 'SD Negeri 1 Teladan';

    final menus = user?.menus ?? [];
    final children = user?.children ?? [];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schoolName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              academicPeriod,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifikasi tersaring sesuai peran Anda.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authStateProvider.notifier).checkInitialAuth();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GREETING & ROLE-SPECIFIC BANNER
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $userName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      roleLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '· $roleBadge',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ADAPTIVE QUICK ACTION BUTTON ACCORDING TO ROLE
                    if (isMurid) ...[
                      _buildQuickActionButton(
                        icon: Icons.qr_code_2,
                        label: 'Tampilkan Barcode Kartu Siswa (Untuk Di-Scan)',
                        onTap: () => context.push('/my-card'),
                      ),
                    ] else if (isOrangTua) ...[
                      _buildQuickActionButton(
                        icon: Icons.qr_code_2,
                        label: 'Tampilkan Kartu QR & Notifikasi SPP 2 Anak',
                        onTap: () => context.push('/my-card'),
                      ),
                    ] else if (isKepsek) ...[
                      _buildQuickActionButton(
                        icon: Icons.campaign_rounded,
                        label: 'Sampaikan Pengumuman Baru (Pilih Role Tujuan)',
                        onTap: () => _showCreateAnnouncementDialog(context),
                      ),
                    ] else if (isSuperAdmin) ...[
                      _buildQuickActionButton(
                        icon: Icons.admin_panel_settings,
                        label: 'Kelola Aturan Hak Akses & Role Matrix',
                        onTap: () => context.push('/admin/roles'),
                      ),
                    ] else ...[
                      _buildQuickActionButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Pindai QR Kartu Pelajar Siswa SD',
                        onTap: () => context.push('/scan-qr'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ROLE-SPECIFIC WIDGETS

              // 1. MURID (SISWA SD): Live Barcode & Digital Card Preview
              if (isMurid) ...[
                const Text(
                  'Kartu Tanda Siswa SD (Siap Scan)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                _buildStudentBarcodeCard(context, user?.student ?? {
                  'name': user?.name ?? 'Ahmad Fauzan',
                  'admission_no': '20261001',
                  'nisn': '0089123456',
                  'class_name': 'Kelas 1A SD',
                  'address': 'Jl. Melati No. 15, Jakarta Barat',
                  'card_number': 'KP-SD-2026-0001',
                  'qr_token': 'KP_20261001_TELADAN',
                }),
                const SizedBox(height: 20),
              ],

              // 2. ORANG TUA: Dual-Child Cards / Multi-Child SPP & Barcode View
              if (isOrangTua && children.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Anak Terdaftar di SD Ini (2 Siswa)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${children.length} Siswa Terhubung',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...List.generate(children.length, (index) {
                  final ch = children[index];
                  final childName = ch['name'] ?? 'Siswa';
                  final childClass = ch['class_name'] ?? 'Kelas SD';
                  final childToken = ch['qr_token'] ?? 'KP_20261001_TELADAN';
                  final unpaidCount = ch['unpaid_invoices_count'] ?? 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: QrImageView(
                            data: childToken,
                            version: QrVersions.auto,
                            size: 55,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(childName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(childClass, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: unpaidCount > 0 ? AppColors.statusPending.withOpacity(0.15) : AppColors.statusPresent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  unpaidCount > 0 ? 'Tagihan SPP Okt: Rp 250.000 Belum Bayar' : 'SPP Lunas',
                                  style: TextStyle(
                                    color: unpaidCount > 0 ? const Color(0xFFB45309) : AppColors.statusPresent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
                          onPressed: () => context.push('/my-card'),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],

              // 3. ADMIN SEKOLAH: Action Cards (Input Siswa & Input Kelas)
              if (isAdmin) ...[
                const Text(
                  'Aksi Cepat Admin Tata Usaha SD',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildAdminActionButton(
                        title: 'Input Siswa Baru',
                        subtitle: 'Tambah data & buat barcode',
                        icon: Icons.person_add_alt_1,
                        color: const Color(0xFF3B82F6),
                        onTap: () => _showAddStudentDialog(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAdminActionButton(
                        title: 'Input Kelas Baru',
                        subtitle: 'Tambah rombel 1-6',
                        icon: Icons.add_home_work_outlined,
                        color: const Color(0xFF8B5CF6),
                        onTap: () => _showAddClassDialog(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // DYNAMIC SERVICE GRID ACCORDING TO ROLE
              Text(
                'Layanan Utama (${menus.length} Menu Sesuai Peran)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menus.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final menu = menus[index];
                  final label = menu['label'] ?? '';
                  final iconName = menu['icon'] ?? '';
                  final route = menu['route'] ?? '/dashboard';
                  final colorHex = menu['color'] ?? '#3B82F6';
                  final color = _parseColor(colorHex);

                  return _ServiceItem(
                    icon: _resolveIcon(iconName),
                    label: label,
                    color: color,
                    onTap: () => _handleMenuNavigation(context, route, menu['id']),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ROLE-TAILORED SUMMARY CARDS
              const Text(
                'Ringkasan Informasi Anda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildRoleSummarySection(context, user, isMurid, isOrangTua, isWaliKelas, isGuru, isKepsek, isAdmin, isSuperAdmin),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentBarcodeCard(BuildContext context, Map<String, dynamic> student) {
    final studentName = student['name'] ?? student['student_name'] ?? 'Ahmad Fauzan';
    final nisn = student['nisn'] ?? '0089123456';
    final className = student['class_name'] ?? 'Kelas 1A';
    final token = student['qr_token'] ?? 'KP_20261001_TELADAN';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: token,
              version: QrVersions.auto,
              size: 80,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text('NISN: $nisn · $className', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => context.push('/my-card'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.statusPresent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.print, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Buka & Cetak Kartu', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSummarySection(
    BuildContext context,
    User? user,
    bool isMurid,
    bool isOrangTua,
    bool isWaliKelas,
    bool isGuru,
    bool isKepsek,
    bool isAdmin,
    bool isSuperAdmin,
  ) {
    if (isMurid) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryRow('Status Siswa', 'Aktif di SD Negeri 1 Teladan', AppColors.statusPresent),
              const Divider(height: 20),
              _buildSummaryRow('Tagihan SPP Okt 2026', 'Rp 250.000 (Belum Lunas)', AppColors.statusPending),
              const Divider(height: 20),
              _buildSummaryRow('Jadwal Hari Ini', 'Bahasa Indonesia & PJOK', AppColors.primaryLight),
            ],
          ),
        ),
      );
    }

    if (isOrangTua) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryRow('Anak 1 (Ahmad Fauzan - 1A)', 'SPP Rp 250.000 Belum Bayar', AppColors.statusPending),
              const Divider(height: 20),
              _buildSummaryRow('Anak 2 (Siti Aisyah - 3A)', 'SPP Rp 250.000 Belum Bayar', AppColors.statusPending),
              const Divider(height: 20),
              _buildSummaryRow('Notifikasi Pembayaran', '2 Tagihan Perlu Diselesaikan', Colors.red),
            ],
          ),
        ),
      );
    }

    if (isWaliKelas) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryRow('Kelas Binaan', 'Kelas 1A SD (28 Siswa)', AppColors.primary),
              const Divider(height: 20),
              _buildSummaryRow('Presensi Kelas Hari Ini', '100% Hadir Lengkap', AppColors.statusPresent),
              const Divider(height: 20),
              _buildSummaryRow('Guru Mapel Ditugaskan', 'PJOK: Rian Hidayat, S.Pd.', AppColors.statusPermit),
            ],
          ),
        ),
      );
    }

    if (isGuru) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryRow('Mata Pelajaran', 'PJOK (Olahraga) SD', AppColors.primary),
              const Divider(height: 20),
              _buildSummaryRow('Jadwal Mengajar Hari Ini', '07:30 - 09:00 (Kelas 1A)', AppColors.statusPresent),
              const Divider(height: 20),
              _buildSummaryRow('Penugasan Dari', 'Siti Rahmawati, S.Pd. (Wali Kelas)', AppColors.statusPermit),
            ],
          ),
        ),
      );
    }

    if (isKepsek) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryRow('Tingkat Kehadiran Sekolah', '98% Hadir (Sangat Baik)', AppColors.statusPresent),
              const Divider(height: 20),
              _buildSummaryRow('Realisasi SPP Bulan Ini', 'Rp 250.000 Masuk Kas', AppColors.statusPending),
              const Divider(height: 20),
              _buildSummaryRow('Fitur Pengumuman', 'Dapat Kirim Terarah ke Peran Tertentu', AppColors.primary),
            ],
          ),
        ),
      );
    }

    // Admin & Super Admin Default
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('Total Siswa SD', '2 Siswa Terdaftar', AppColors.primary),
            const Divider(height: 20),
            _buildSummaryRow('Tagihan SPP Terbit', '2 Tagihan Okt 2026 (Rp 500.000)', AppColors.statusPending),
            const Divider(height: 20),
            _buildSummaryRow('Sistem Hak Akses', '7 Peran Terkonfigurasi Penuh', AppColors.statusPresent),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  void _handleMenuNavigation(BuildContext context, String route, dynamic id) {
    if (route == '/my-card') {
      context.push('/my-card');
    } else if (route == '/admin/roles') {
      context.push('/admin/roles');
    } else if (route == '/scan-qr') {
      context.push('/scan-qr');
    } else if (route == '/finance') {
      context.go('/finance');
    } else if (route == '/academic') {
      context.go('/academic');
    } else if (id == 'announcements') {
      _showAnnouncementsSheet(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membuka menu: $id')),
      );
    }
  }

  void _showAddStudentDialog(BuildContext context) {
    final nisCtrl = TextEditingController();
    final nisnCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Siswa SD Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap Siswa')),
              TextField(controller: nisCtrl, decoration: const InputDecoration(labelText: 'Nomor Induk Siswa (NIS)')),
              TextField(controller: nisnCtrl, decoration: const InputDecoration(labelText: 'NISN')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat Rumah')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || nisCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan NIS wajib diisi.')));
                return;
              }
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiClientProvider);
                await api.dio.post('/students', data: {
                  'name': nameCtrl.text,
                  'admission_no': nisCtrl.text,
                  'nisn': nisnCtrl.text,
                  'address': addressCtrl.text,
                  'gender': 'L',
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppColors.statusPresent, content: Text('Siswa baru berhasil diinput & kartu barcode otomatis dibuat!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal menyimpan: $e')),
                );
              }
            },
            child: const Text('Simpan Siswa'),
          ),
        ],
      ),
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedGrade = '1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Input Kelas SD Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Kelas (contoh: Kelas 2B)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: const InputDecoration(labelText: 'Tingkat Kelas'),
                items: ['1', '2', '3', '4', '5', '6'].map((g) => DropdownMenuItem(value: g, child: Text('Kelas $g'))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedGrade = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final api = ref.read(apiClientProvider);
                  await api.dio.post('/classes', data: {
                    'name': nameCtrl.text,
                    'grade_level': selectedGrade,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppColors.statusPresent, content: Text('Kelas baru berhasil ditambahkan!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menambahkan: $e')),
                  );
                }
              },
              child: const Text('Simpan Kelas'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final List<String> selectedRoles = ['all'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Sampaikan Pengumuman Terarah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Pengumuman')),
                TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Isi Pengumuman')),
                const SizedBox(height: 14),
                const Text('Pilih Peran Tujuan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: selectedRoles.contains('all'),
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedRoles.clear();
                            selectedRoles.add('all');
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Admin'),
                      selected: selectedRoles.contains('admin_sekolah'),
                      onSelected: (val) {
                        setDialogState(() {
                          selectedRoles.remove('all');
                          val ? selectedRoles.add('admin_sekolah') : selectedRoles.remove('admin_sekolah');
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Wali Kelas'),
                      selected: selectedRoles.contains('wali_kelas'),
                      onSelected: (val) {
                        setDialogState(() {
                          selectedRoles.remove('all');
                          val ? selectedRoles.add('wali_kelas') : selectedRoles.remove('wali_kelas');
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Guru Mapel'),
                      selected: selectedRoles.contains('guru'),
                      onSelected: (val) {
                        setDialogState(() {
                          selectedRoles.remove('all');
                          val ? selectedRoles.add('guru') : selectedRoles.remove('guru');
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Wali Murid'),
                      selected: selectedRoles.contains('orang_tua'),
                      onSelected: (val) {
                        setDialogState(() {
                          selectedRoles.remove('all');
                          val ? selectedRoles.add('orang_tua') : selectedRoles.remove('orang_tua');
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Murid'),
                      selected: selectedRoles.contains('murid'),
                      onSelected: (val) {
                        setDialogState(() {
                          selectedRoles.remove('all');
                          val ? selectedRoles.add('murid') : selectedRoles.remove('murid');
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final api = ref.read(apiClientProvider);
                  await api.dio.post('/announcements', data: {
                    'title': titleCtrl.text,
                    'body': bodyCtrl.text,
                    'target_roles': selectedRoles.isEmpty ? ['all'] : selectedRoles,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppColors.statusPresent, content: Text('Pengumuman berhasil disampaikan ke peran terpilih!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengirim: $e')),
                  );
                }
              },
              child: const Text('Kirim Pengumuman'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: const [
            Text('Pengumuman Untuk Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.campaign, color: AppColors.primary),
                title: Text('Peringatan Hari Anak Nasional & PTS SD', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Diberitahukan kepada seluruh warga SD Negeri 1 Teladan bahwa kegiatan PTS akan diselenggarakan pekan depan.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _resolveIcon(String name) {
    switch (name) {
      case 'qr_code_2':
        return Icons.qr_code_2_rounded;
      case 'qr_code_scanner':
        return Icons.qr_code_scanner_rounded;
      case 'people_alt':
        return Icons.people_alt_outlined;
      case 'payments':
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'calendar_month':
      case 'calendar_today':
        return Icons.calendar_month_outlined;
      case 'schedule':
        return Icons.schedule_outlined;
      case 'badge':
        return Icons.badge_outlined;
      case 'analytics':
      case 'fact_check':
        return Icons.analytics_outlined;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'class':
        return Icons.class_outlined;
      case 'campaign':
        return Icons.campaign_outlined;
      default:
        return Icons.apps_rounded;
    }
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('0xFF$clean'));
    }
    return AppColors.primary;
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
