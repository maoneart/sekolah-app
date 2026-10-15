<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Elementary School (SD)
        $schoolId = (string) Str::uuid();
        DB::table('schools')->insert([
            'id' => $schoolId,
            'code' => 'SDN1TLD',
            'name' => 'SD Negeri 1 Teladan',
            'timezone' => 'Asia/Jakarta',
            'settings' => json_encode([
                'attendance_mode' => 'qr_and_manual',
                'school_type' => 'SD',
                'grades' => [1, 2, 3, 4, 5, 6],
            ]),
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 2. Create Permissions
        $permissionList = [
            'manage_access' => 'Mengelola Hak Akses & Menu',
            'manage_students' => 'Mengelola Data Siswa SD',
            'manage_spp' => 'Mengelola Tagihan & Pembayaran SPP',
            'issue_cards' => 'Menerbitkan Kartu Barcode Pelajar',
            'manage_classes' => 'Mengelola Rombel & Kelas SD',
            'manage_subjects' => 'Mengelola Mata Pelajaran SD',
            'view_reports' => 'Melihat Rekap Laporan & Absensi',
            'manage_homeroom' => 'Mengelola Kelas Binaan & Jadwal',
            'assign_teachers' => 'Menugaskan Guru Mapel di Kelas',
            'scan_attendance' => 'Memindai QR Barcode Absensi',
            'view_schedule' => 'Melihat Jadwal Pelajaran',
            'view_own_card' => 'Melihat Kartu Barcode Siswa',
            'view_own_invoices' => 'Melihat Tagihan SPP',
            'publish_announcements' => 'Mempublikasikan Pengumuman',
        ];

        $permissionIds = [];
        foreach ($permissionList as $permName => $label) {
            $pId = (string) Str::uuid();
            $permissionIds[$permName] = $pId;
            DB::table('permissions')->insert([
                'id' => $pId,
                'name' => $permName,
                'guard_name' => 'sanctum',
                'category' => 'general',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 3. Create Roles
        $roles = [
            'super_admin' => 'Super Administrator',
            'admin_sekolah' => 'Admin Sekolah',
            'kepala_sekolah' => 'Kepala Sekolah',
            'wali_kelas' => 'Wali Kelas SD',
            'guru' => 'Guru Mata Pelajaran SD',
            'murid' => 'Murid (Siswa SD)',
            'orang_tua' => 'Orang Tua / Wali Murid',
        ];

        $roleIds = [];
        foreach ($roles as $key => $label) {
            $rId = (string) Str::uuid();
            $roleIds[$key] = $rId;
            DB::table('roles')->insert([
                'id' => $rId,
                'school_id' => $schoolId,
                'name' => $key,
                'guard_name' => 'sanctum',
                'description' => $label,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // Role-Permission mappings
        $rolePermissionMap = [
            'super_admin' => array_keys($permissionList),
            'admin_sekolah' => ['manage_students', 'manage_spp', 'issue_cards', 'manage_classes', 'manage_subjects', 'scan_attendance', 'publish_announcements'],
            'kepala_sekolah' => ['view_reports', 'publish_announcements', 'view_schedule'],
            'wali_kelas' => ['manage_homeroom', 'assign_teachers', 'scan_attendance', 'view_schedule', 'publish_announcements'],
            'guru' => ['scan_attendance', 'view_schedule'],
            'murid' => ['view_own_card', 'view_own_invoices', 'view_schedule'],
            'orang_tua' => ['view_own_card', 'view_own_invoices', 'view_schedule'],
        ];

        foreach ($rolePermissionMap as $rKey => $perms) {
            foreach ($perms as $pName) {
                if (isset($permissionIds[$pName])) {
                    DB::table('role_permissions')->insert([
                        'role_id' => $roleIds[$rKey],
                        'permission_id' => $permissionIds[$pName],
                    ]);
                }
            }
        }

        // 4. Create Users for Each Role
        // Helper to create user + membership + role
        $createUserWithRole = function (
            string $name,
            string $email,
            string $phone,
            string $roleKey,
            string $gender = 'L',
            string $birthDate = '1990-01-01',
            string $address = 'Jakarta'
        ) use ($schoolId, $roleIds) {
            $userId = (string) Str::uuid();
            $user = User::create([
                'id' => $userId,
                'name' => $name,
                'email' => $email,
                'phone' => $phone,
                'password' => Hash::make('password123'),
                'gender' => $gender,
                'birth_date' => $birthDate,
                'address' => $address,
                'status' => 'active',
            ]);

            $membershipId = (string) Str::uuid();
            DB::table('school_memberships')->insert([
                'id' => $membershipId,
                'school_id' => $schoolId,
                'user_id' => $userId,
                'status' => 'active',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('membership_roles')->insert([
                'id' => (string) Str::uuid(),
                'membership_id' => $membershipId,
                'role_id' => $roleIds[$roleKey],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return ['user' => $user, 'membership_id' => $membershipId];
        };

        // 1. Super Admin
        $superAdmin = $createUserWithRole(
            'Super Administrator',
            'superadmin@sekolah.sch.id',
            '081100000001',
            'super_admin',
            'L',
            '1985-03-20',
            'Jl. Garuda Mas No. 1, Gambir, Jakarta Pusat'
        );
        
        // 2. Admin Sekolah
        $adminSekolah = $createUserWithRole(
            'Budi Santoso (Admin)',
            'admin@sekolah.sch.id',
            '081234567890',
            'admin_sekolah',
            'L',
            '1990-08-14',
            'Jl. Kemanggisan Raya No. 45, Palmerah, Jakarta Barat'
        );

        // 3. Kepala Sekolah
        $kepalaSekolah = $createUserWithRole(
            'Drs. H. Mulyadi, M.Pd.',
            'kepsek@sekolah.sch.id',
            '081234567893',
            'kepala_sekolah',
            'L',
            '1972-11-05',
            'Jl. Cempaka Putih Timur No. 18, Jakarta Pusat'
        );

        // 4. Wali Kelas 1A
        $waliKelas1A = $createUserWithRole(
            'Siti Rahmawati, S.Pd. (Wali Kelas 1A)',
            'walikelas@sekolah.sch.id',
            '081234567891',
            'wali_kelas',
            'P',
            '1993-06-25',
            'Jl. Palmerah Barat No. 88, Palmerah, Jakarta Barat'
        );

        // 5. Guru Mapel (PJOK & Seni Budaya SD)
        $guruMapel = $createUserWithRole(
            'Rian Hidayat, S.Pd. (Guru PJOK)',
            'guru@sekolah.sch.id',
            '081234567894',
            'guru',
            'L',
            '1995-12-10',
            'Jl. Tanjung Duren Barat No. 22, Grogol, Jakarta Barat'
        );

        // 6. Murid (Siswa SD Kelas 1A)
        $murid1 = $createUserWithRole(
            'Ahmad Fauzan',
            'murid@sekolah.sch.id',
            '081234567895',
            'murid',
            'L',
            '2019-05-14',
            'Jl. Melati No. 15, RT 02/RW 04, Kebon Jeruk, Jakarta Barat'
        );

        // 7. Orang Tua (Hendra Pratama - Memiliki 2 anak di SD ini: Ahmad Fauzan & Siti Aisyah)
        $orangTua = $createUserWithRole(
            'Hendra Pratama (Wali Murid)',
            'wali@sekolah.sch.id',
            '081234567892',
            'orang_tua',
            'L',
            '1988-04-18',
            'Jl. Melati No. 15, RT 02/RW 04, Kebon Jeruk, Jakarta Barat'
        );

        // 5. Academic Year & Semester
        $ayId = (string) Str::uuid();
        DB::table('academic_years')->insert([
            'id' => $ayId,
            'school_id' => $schoolId,
            'name' => '2026/2027',
            'starts_on' => '2026-07-15',
            'ends_on' => '2027-06-30',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $semId = (string) Str::uuid();
        DB::table('semesters')->insert([
            'id' => $semId,
            'academic_year_id' => $ayId,
            'name' => 'Semester Ganjil',
            'starts_on' => '2026-07-15',
            'ends_on' => '2026-12-20',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 6. SD Classes (Kelas 1A s/d Kelas 6A)
        $class1AId = (string) Str::uuid();
        DB::table('classes')->insert([
            'id' => $class1AId,
            'school_id' => $schoolId,
            'academic_year_id' => $ayId,
            'homeroom_membership_id' => $waliKelas1A['membership_id'],
            'name' => 'Kelas 1A',
            'grade_level' => '1',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $class3AId = (string) Str::uuid();
        DB::table('classes')->insert([
            'id' => $class3AId,
            'school_id' => $schoolId,
            'academic_year_id' => $ayId,
            'homeroom_membership_id' => null,
            'name' => 'Kelas 3A',
            'grade_level' => '3',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $otherClasses = [
            ['name' => 'Kelas 1B', 'grade' => '1'],
            ['name' => 'Kelas 2A', 'grade' => '2'],
            ['name' => 'Kelas 4A', 'grade' => '4'],
            ['name' => 'Kelas 5A', 'grade' => '5'],
            ['name' => 'Kelas 6A', 'grade' => '6'],
        ];
        foreach ($otherClasses as $cls) {
            DB::table('classes')->insert([
                'id' => (string) Str::uuid(),
                'school_id' => $schoolId,
                'academic_year_id' => $ayId,
                'name' => $cls['name'],
                'grade_level' => $cls['grade'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 7. Mata Pelajaran SD (Subjects)
        $sdSubjects = [
            ['code' => 'PAI', 'name' => 'Pendidikan Agama Islam & Budi Pekerti'],
            ['code' => 'PPKN', 'name' => 'Pendidikan Pancasila'],
            ['code' => 'BINDO', 'name' => 'Bahasa Indonesia'],
            ['code' => 'MTK', 'name' => 'Matematika'],
            ['code' => 'IPAS', 'name' => 'Ilmu Pengetahuan Alam dan Sosial'],
            ['code' => 'PJOK', 'name' => 'Pendidikan Jasmani, Olahraga, dan Kesehatan'],
            ['code' => 'SBDP', 'name' => 'Seni Budaya dan Prakarya'],
            ['code' => 'BING', 'name' => 'Bahasa Inggris Dasar'],
        ];

        $subjectIds = [];
        foreach ($sdSubjects as $sb) {
            $sbId = (string) Str::uuid();
            $subjectIds[$sb['code']] = $sbId;
            DB::table('subjects')->insert([
                'id' => $sbId,
                'school_id' => $schoolId,
                'code' => $sb['code'],
                'name' => $sb['name'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 8. Teaching Assignments (Wali Kelas assigns Guru Mapel PJOK to Kelas 1A)
        DB::table('teaching_assignments')->insert([
            'id' => (string) Str::uuid(),
            'class_id' => $class1AId,
            'subject_id' => $subjectIds['PJOK'],
            'teacher_membership_id' => $guruMapel['membership_id'],
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('teaching_assignments')->insert([
            'id' => (string) Str::uuid(),
            'class_id' => $class1AId,
            'subject_id' => $subjectIds['BINDO'],
            'teacher_membership_id' => $waliKelas1A['membership_id'],
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 9. Students - 2 Children for Wali Murid Hendra Pratama
        // Anak 1: Ahmad Fauzan (Kelas 1A SD)
        $student1Id = (string) Str::uuid();
        DB::table('students')->insert([
            'id' => $student1Id,
            'school_id' => $schoolId,
            'admission_no' => '20261001',
            'nisn' => '0089123456',
            'name' => 'Ahmad Fauzan',
            'birth_date' => '2019-05-14',
            'gender' => 'L',
            'address' => 'Jl. Melati No. 15, RT 02/RW 04, Jakarta Barat',
            'admission_date' => '2026-07-15',
            'graduation_date' => null,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('class_enrollments')->insert([
            'id' => (string) Str::uuid(),
            'student_id' => $student1Id,
            'class_id' => $class1AId,
            'starts_on' => '2026-07-15',
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Anak 2: Siti Aisyah (Kelas 3A SD - Kakak dari Ahmad Fauzan)
        $student2Id = (string) Str::uuid();
        DB::table('students')->insert([
            'id' => $student2Id,
            'school_id' => $schoolId,
            'admission_no' => '20241015',
            'nisn' => '0089123457',
            'name' => 'Siti Aisyah',
            'birth_date' => '2017-09-22',
            'gender' => 'P',
            'address' => 'Jl. Melati No. 15, RT 02/RW 04, Jakarta Barat',
            'admission_date' => '2024-07-15',
            'graduation_date' => null,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('class_enrollments')->insert([
            'id' => (string) Str::uuid(),
            'student_id' => $student2Id,
            'class_id' => $class3AId,
            'starts_on' => '2026-07-15',
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 10. Guardian Record for Hendra Pratama
        $guardianId = (string) Str::uuid();
        DB::table('guardians')->insert([
            'id' => $guardianId,
            'school_id' => $schoolId,
            'user_id' => $orangTua['user']->id,
            'name' => 'Hendra Pratama',
            'phone' => '081234567892',
            'email' => 'wali@sekolah.sch.id',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Connect both children to this 1 guardian!
        DB::table('student_guardians')->insert([
            [
                'id' => (string) Str::uuid(),
                'student_id' => $student1Id,
                'guardian_id' => $guardianId,
                'relationship' => 'ayah',
                'is_primary' => true,
                'portal_access' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => (string) Str::uuid(),
                'student_id' => $student2Id,
                'guardian_id' => $guardianId,
                'relationship' => 'ayah',
                'is_primary' => true,
                'portal_access' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        // Also associate student1 with user murid1
        DB::table('school_memberships')
            ->where('id', $murid1['membership_id'])
            ->update(['created_at' => now()]);

        // 11. Student Cards (Kartu Pelajar Barcode/QR) for both students
        // Ahmad Fauzan's Card
        $token1Plain = 'KP_20261001_TELADAN';
        DB::table('student_cards')->insert([
            'id' => (string) Str::uuid(),
            'school_id' => $schoolId,
            'student_id' => $student1Id,
            'token_hash' => hash('sha256', $token1Plain),
            'card_number' => 'KP-SD-2026-0001',
            'issued_at' => now(),
            'issued_by' => $adminSekolah['user']->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Siti Aisyah's Card
        $token2Plain = 'KP_20241015_TELADAN';
        DB::table('student_cards')->insert([
            'id' => (string) Str::uuid(),
            'school_id' => $schoolId,
            'student_id' => $student2Id,
            'token_hash' => hash('sha256', $token2Plain),
            'card_number' => 'KP-SD-2024-0115',
            'issued_at' => now(),
            'issued_by' => $adminSekolah['user']->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 12. Finance - SPP Invoices for BOTH Children (User can see both notif/bills!)
        $feeTypeId = (string) Str::uuid();
        DB::table('fee_types')->insert([
            'id' => $feeTypeId,
            'school_id' => $schoolId,
            'code' => 'SPP',
            'name' => 'Sumbangan Pembinaan Pendidikan (SPP SD)',
            'default_amount' => 250000,
            'active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Tagihan SPP Okt 2026 untuk Anak 1 (Ahmad Fauzan - Kelas 1A)
        $inv1Id = (string) Str::uuid();
        DB::table('invoices')->insert([
            'id' => $inv1Id,
            'school_id' => $schoolId,
            'student_id' => $student1Id,
            'invoice_no' => 'INV/2026/10/0042',
            'period' => '2026-10',
            'due_on' => '2026-10-20',
            'total_amount' => 250000,
            'status' => 'unpaid',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('invoice_items')->insert([
            'id' => (string) Str::uuid(),
            'invoice_id' => $inv1Id,
            'fee_type_id' => $feeTypeId,
            'description' => 'SPP Bulan Oktober 2026 - Ahmad Fauzan (Kelas 1A)',
            'quantity' => 1,
            'unit_amount' => 250000,
            'line_amount' => 250000,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Tagihan SPP Okt 2026 untuk Anak 2 (Siti Aisyah - Kelas 3A)
        $inv2Id = (string) Str::uuid();
        DB::table('invoices')->insert([
            'id' => $inv2Id,
            'school_id' => $schoolId,
            'student_id' => $student2Id,
            'invoice_no' => 'INV/2026/10/0043',
            'period' => '2026-10',
            'due_on' => '2026-10-20',
            'total_amount' => 250000,
            'status' => 'unpaid',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('invoice_items')->insert([
            'id' => (string) Str::uuid(),
            'invoice_id' => $inv2Id,
            'fee_type_id' => $feeTypeId,
            'description' => 'SPP Bulan Oktober 2026 - Siti Aisyah (Kelas 3A)',
            'quantity' => 1,
            'unit_amount' => 250000,
            'line_amount' => 250000,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // September Paid Invoice for Ahmad Fauzan
        $invSepId = (string) Str::uuid();
        DB::table('invoices')->insert([
            'id' => $invSepId,
            'school_id' => $schoolId,
            'student_id' => $student1Id,
            'invoice_no' => 'INV/2026/09/0115',
            'period' => '2026-09',
            'due_on' => '2026-09-20',
            'total_amount' => 250000,
            'status' => 'paid',
            'created_at' => now()->subMonth(),
            'updated_at' => now()->subMonth(),
        ]);

        DB::table('invoice_items')->insert([
            'id' => (string) Str::uuid(),
            'invoice_id' => $invSepId,
            'fee_type_id' => $feeTypeId,
            'description' => 'SPP Bulan September 2026 - Ahmad Fauzan (Kelas 1A)',
            'quantity' => 1,
            'unit_amount' => 250000,
            'line_amount' => 250000,
            'created_at' => now()->subMonth(),
            'updated_at' => now()->subMonth(),
        ]);

        DB::table('payments')->insert([
            'id' => (string) Str::uuid(),
            'school_id' => $schoolId,
            'invoice_id' => $invSepId,
            'amount' => 250000,
            'method' => 'cash',
            'status' => 'completed',
            'reference' => 'KASIR-0091',
            'paid_at' => now()->subMonth(),
            'recorded_by' => $adminSekolah['user']->id,
            'created_at' => now()->subMonth(),
            'updated_at' => now()->subMonth(),
        ]);

        // 13. Announcement
        DB::table('announcements')->insert([
            'id' => (string) Str::uuid(),
            'school_id' => $schoolId,
            'title' => 'Peringatan Hari Anak Nasional & Jadwal PTS Semester Ganjil SD',
            'body' => 'Diberitahukan kepada seluruh Bapak/Ibu Wali Murid dan Siswa SD Negeri 1 Teladan bahwa Penilaian Tengah Semester (PTS) akan diselenggarakan pekan depan. Mohon bimbingan belajar di rumah.',
            'published_at' => now(),
            'created_by' => $kepalaSekolah['user']->id,
            'status' => 'published',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}

