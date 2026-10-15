import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_colors.dart';

class AcademicScreen extends ConsumerWidget {
  const AcademicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Akademik'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Daftar Kelas'),
              Tab(text: 'Jadwal'),
              Tab(text: 'Absensi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Classes tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ClassCard(
                  name: 'X RPL 1',
                  homeroomTeacher: 'Budi Santoso, S.Kom.',
                  studentCount: 36,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _ClassCard(
                  name: 'X RPL 2',
                  homeroomTeacher: 'Siti Aminah, M.Pd.',
                  studentCount: 35,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _ClassCard(
                  name: 'XI TKJ 1',
                  homeroomTeacher: 'Ahmad Fauzi, S.T.',
                  studentCount: 34,
                  onTap: () {},
                ),
              ],
            ),
            // Timetable tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ScheduleItem(
                  time: '07:30 - 09:00',
                  subject: 'Pemrograman Web & Perangkat Bergerak',
                  room: 'Lab Komputer 3',
                  teacher: 'Budi Santoso, S.Kom.',
                ),
                const SizedBox(height: 12),
                _ScheduleItem(
                  time: '09:15 - 10:45',
                  subject: 'Basis Data',
                  room: 'Lab Komputer 2',
                  teacher: 'Dewi Lestari, M.Kom.',
                ),
              ],
            ),
            // Attendance Summary tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sesi Absensi Hari Ini',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '15 Oktober 2026',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _AttendanceBadge(label: 'Hadir', count: '34', color: AppColors.statusPresent),
                            _AttendanceBadge(label: 'Izin', count: '1', color: AppColors.statusPermit),
                            _AttendanceBadge(label: 'Sakit', count: '1', color: AppColors.statusSick),
                            _AttendanceBadge(label: 'Alpa', count: '0', color: AppColors.statusAbsent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String name;
  final String homeroomTeacher;
  final int studentCount;
  final VoidCallback onTap;

  const _ClassCard({
    required this.name,
    required this.homeroomTeacher,
    required this.studentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.class_outlined, color: AppColors.primary),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Wali Kelas: $homeroomTeacher\n$studentCount Siswa'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final String time;
  final String subject;
  final String room;
  final String teacher;

  const _ScheduleItem({
    required this.time,
    required this.subject,
    required this.room,
    required this.teacher,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    room,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subject,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              teacher,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _AttendanceBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
