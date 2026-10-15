import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/design_system/app_colors.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final gender = user?.gender;
    final isGenderSet = gender == 'L' || gender == 'P';
    final genderDisplay = gender == 'P'
        ? 'Perempuan (P)'
        : (gender == 'L' ? 'Laki-laki (L)' : 'Belum diisi / Perlu dilengkapi');

    final birthDate = user?.birthDate;
    final birthDateDisplay = birthDate ?? 'Belum diisi';
    final ageDisplay = user?.age != null ? ' (${user!.age} Tahun)' : '';
    final address = user?.address;
    final addressDisplay = address ?? 'Belum diisi';
    final phoneDisplay = user?.phone ?? 'Belum diisi';

    final isProfileIncomplete = !isGenderSet ||
        birthDate == null ||
        birthDate.isEmpty ||
        address == null ||
        address.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun & Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // INCOMPLETE DATA NOTICE (IF ADMIN INPUT WAS MISSING OR WRONG)
          if (isProfileIncomplete)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEEBA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Profil Perlu Dilengkapi / Dikoreksi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF856404)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Data jenis kelamin, tanggal lahir, atau alamat Anda belum lengkap atau ada kesalahan dari input admin. Ketuk tombol edit di bawah untuk memperbarui.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF856404)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // PROFILE HEADER CARD
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Pengguna',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? user?.phone ?? 'Belum ada kontak',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user?.roles.join(', ') ?? 'Warga Sekolah',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Edit / Lengkapi Profil Saya'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showEditProfileDialog(context, ref, user),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // PERSONAL DETAILS (GENDER, BIRTHDATE, AGE, ADDRESS)
          const Text(
            'Data Diri & Identitas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _ProfileDetailItem(
                    icon: user?.gender == 'P' ? Icons.female : (user?.gender == 'L' ? Icons.male : Icons.person_outline),
                    label: 'Jenis Kelamin',
                    value: genderDisplay,
                    iconColor: user?.gender == 'P' ? Colors.pink : (user?.gender == 'L' ? Colors.blue : Colors.orange),
                    isHighlight: !isGenderSet,
                  ),
                  const Divider(height: 18),
                  _ProfileDetailItem(
                    icon: Icons.cake_outlined,
                    label: 'Tanggal Lahir & Usia',
                    value: '$birthDateDisplay$ageDisplay',
                    iconColor: Colors.orange,
                    isHighlight: user?.birthDate == null,
                  ),
                  const Divider(height: 18),
                  _ProfileDetailItem(
                    icon: Icons.phone_outlined,
                    label: 'Nomor Telepon / WA',
                    value: phoneDisplay,
                    iconColor: Colors.green,
                  ),
                  const Divider(height: 18),
                  _ProfileDetailItem(
                    icon: Icons.home_outlined,
                    label: 'Alamat Tempat Tinggal',
                    value: addressDisplay,
                    iconColor: Colors.indigo,
                    isHighlight: user?.address == null || user?.address?.isEmpty == true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // SCHOOL CONTEXT
          const Text(
            'Informasi Sekolah',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.school_outlined, color: AppColors.primary),
              title: Text(user?.activeSchoolName ?? 'SD Negeri 1 Teladan', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Jenjang Sekolah Dasar (SD)'),
              trailing: const Icon(Icons.verified, color: AppColors.statusPresent, size: 20),
            ),
          ),
          const SizedBox(height: 20),

          // SECURITY & LOGOUT
          const Text(
            'Pengaturan & Sesi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_outlined),
                  title: const Text('Ganti Kata Sandi'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur ubah kata sandi dapat diakses.')),
                    );
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Aplikasi Manajemen SD'),
                  subtitle: Text('Versi 1.0.0 (SD Negeri 1 Teladan)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.statusAbsent,
              side: const BorderSide(color: AppColors.statusAbsent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 46),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi Keluar'),
                  content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusAbsent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, User? user) {
    final nameCtrl = TextEditingController(text: user?.name);
    final phoneCtrl = TextEditingController(text: user?.phone);
    final birthDateCtrl = TextEditingController(text: user?.birthDate ?? '');
    final addressCtrl = TextEditingController(text: user?.address);
    String selectedGender = user?.gender ?? 'L';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text('Lengkapi / Koreksi Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Jika terdapat kesalahan input dari pihak admin, Anda dapat mengubah dan melengkapi data Anda sendiri di sini.',
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                // GENDER SELECTOR TILES (LAKI-LAKI & PEREMPUAN)
                const Text(
                  'Jenis Kelamin:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Laki-laki
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setDialogState(() => selectedGender = 'L'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: selectedGender == 'L' ? Colors.blue.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedGender == 'L' ? Colors.blue : Colors.grey.shade300,
                              width: selectedGender == 'L' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.male, color: selectedGender == 'L' ? Colors.blue : Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Laki-laki',
                                style: TextStyle(
                                  fontWeight: selectedGender == 'L' ? FontWeight.bold : FontWeight.normal,
                                  color: selectedGender == 'L' ? Colors.blue.shade800 : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Perempuan
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setDialogState(() => selectedGender = 'P'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: selectedGender == 'P' ? Colors.pink.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedGender == 'P' ? Colors.pink : Colors.grey.shade300,
                              width: selectedGender == 'P' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.female, color: selectedGender == 'P' ? Colors.pink : Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Perempuan',
                                style: TextStyle(
                                  fontWeight: selectedGender == 'P' ? FontWeight.bold : FontWeight.normal,
                                  color: selectedGender == 'P' ? Colors.pink.shade800 : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // BIRTHDATE WITH DATE PICKER
                TextField(
                  controller: birthDateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                    hintText: 'Pilih tanggal lahir',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                      onPressed: () async {
                        DateTime initialDate = DateTime(2000, 1, 1);
                        if (birthDateCtrl.text.isNotEmpty) {
                          try {
                            initialDate = DateTime.parse(birthDateCtrl.text);
                          } catch (_) {}
                        }
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: initialDate,
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          final formatted = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                          setDialogState(() => birthDateCtrl.text = formatted);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon / WhatsApp',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Tempat Tinggal',
                    hintText: 'Contoh: Jl. Melati No. 15, Kebon Jeruk',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final api = ref.read(apiClientProvider);
                  await api.dio.put('/profile', data: {
                    'name': nameCtrl.text,
                    'gender': selectedGender,
                    'birth_date': birthDateCtrl.text.isNotEmpty ? birthDateCtrl.text : null,
                    'phone': phoneCtrl.text,
                    'address': addressCtrl.text,
                  });
                  // Refresh state
                  await ref.read(authStateProvider.notifier).checkInitialAuth();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.statusPresent,
                        content: Text('Profil dan identitas Anda berhasil diperbarui!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui: $e')),
                    );
                  }
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isHighlight;

  const _ProfileDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isHighlight ? Colors.deepOrange : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
