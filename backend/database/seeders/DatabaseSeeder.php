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
        // 1. Create School
        $schoolId = (string) Str::uuid();
        DB::table('schools')->insert([
            'id' => $schoolId,
            'code' => 'SMKN1TLD',
            'name' => 'SMK Negeri 1 Teladan',
            'timezone' => 'Asia/Jakarta',
            'settings' => json_encode(['attendance_mode' => 'qr_and_manual']),
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 2. Create Roles
        $roles = [
            'admin_sekolah' => 'Admin Sekolah',
            'kepala_sekolah' => 'Kepala Sekolah',
            'wali_kelas' => 'Wali Kelas',
            'guru' => 'Guru Kelas/Mapel',
            'murid' => 'Murid',
            'orang_tua' => 'Orang Tua / Wali',
        ];

        $roleIds = [];
        foreach ($roles as $key => $label) {
            $rId = (string) Str::uuid();
            $roleIds[$key] = $rId;
            DB::table('roles')->insert([
                'id' => $rId,
                'school_id' => $schoolId,
                'name' => $key,
                'description' => $label,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 3. Create Users
        // Admin
        $adminId = (string) Str::uuid();
        User::create([
            'id' => $adminId,
            'name' => 'Administrator Sekolah',
            'email' => 'admin@sekolah.sch.id',
            'phone' => '081234567890',
            'password' => Hash::make('password123'),
            'status' => 'active',
        ]);

        $adminMembershipId = (string) Str::uuid();
        DB::table('school_memberships')->insert([
            'id' => $adminMembershipId,
            'school_id' => $schoolId,
            'user_id' => $adminId,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('membership_roles')->insert([
            'id' => (string) Str::uuid(),
            'membership_id' => $adminMembershipId,
            'role_id' => $roleIds['admin_sekolah'],
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Guru / Wali Kelas
        $teacherId = (string) Str::uuid();
        User::create([
            'id' => $teacherId,
            'name' => 'Budi Santoso, S.Kom.',
            'email' => 'guru@sekolah.sch.id',
            'phone' => '081234567891',
            'password' => Hash::make('password123'),
            'status' => 'active',
        ]);

        $teacherMembershipId = (string) Str::uuid();
        DB::table('school_memberships')->insert([
            'id' => $teacherMembershipId,
            'school_id' => $schoolId,
            'user_id' => $teacherId,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('membership_roles')->insert([
            'id' => (string) Str::uuid(),
            'membership_id' => $teacherMembershipId,
            'role_id' => $roleIds['wali_kelas'],
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Orang Tua / Siswa
        $parentUserId = (string) Str::uuid();
        User::create([
            'id' => $parentUserId,
            'name' => 'Hendra Pratama',
            'email' => 'wali@sekolah.sch.id',
            'phone' => '081234567892',
            'password' => Hash::make('password123'),
            'status' => 'active',
        ]);

        $parentMembershipId = (string) Str::uuid();
        DB::table('school_memberships')->insert([
            'id' => $parentMembershipId,
            'school_id' => $schoolId,
            'user_id' => $parentUserId,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('membership_roles')->insert([
            'id' => (string) Str::uuid(),
            'membership_id' => $parentMembershipId,
            'role_id' => $roleIds['orang_tua'],
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 4. Academic Year & Semester
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

        // 5. Classes
        $classId = (string) Str::uuid();
        DB::table('classes')->insert([
            'id' => $classId,
            'school_id' => $schoolId,
            'academic_year_id' => $ayId,
            'homeroom_membership_id' => $teacherMembershipId,
            'name' => 'X RPL 1',
            'grade_level' => '10',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 6. Students
        $studentId = (string) Str::uuid();
        DB::table('students')->insert([
            'id' => $studentId,
            'school_id' => $schoolId,
            'admission_no' => '20261001',
            'nisn' => '0089123456',
            'name' => 'Ahmad Fauzan',
            'birth_date' => '2010-05-14',
            'gender' => 'L',
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Enrollment
        DB::table('class_enrollments')->insert([
            'id' => (string) Str::uuid(),
            'student_id' => $studentId,
            'class_id' => $classId,
            'starts_on' => '2026-07-15',
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Guardian
        $guardianId = (string) Str::uuid();
        DB::table('guardians')->insert([
            'id' => $guardianId,
            'school_id' => $schoolId,
            'user_id' => $parentUserId,
            'name' => 'Hendra Pratama',
            'phone' => '081234567892',
            'email' => 'wali@sekolah.sch.id',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('student_guardians')->insert([
            'id' => (string) Str::uuid(),
            'student_id' => $studentId,
            'guardian_id' => $guardianId,
            'relationship' => 'ayah',
            'is_primary' => true,
            'portal_access' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 7. Student Card (Kartu Pelajar with QR token)
        // Plain token: KP_20261001_TELADAN
        $plainToken = 'KP_20261001_TELADAN';
        $tokenHash = hash('sha256', $plainToken);

        DB::table('student_cards')->insert([
            'id' => (string) Str::uuid(),
            'school_id' => $schoolId,
            'student_id' => $studentId,
            'token_hash' => $tokenHash,
            'card_number' => 'KP-2026-0001',
            'issued_at' => now(),
            'issued_by' => $adminId,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 8. Finance - SPP Fee and Invoices
        $feeTypeId = (string) Str::uuid();
        DB::table('fee_types')->insert([
            'id' => $feeTypeId,
            'school_id' => $schoolId,
            'code' => 'SPP',
            'name' => 'Sumbangan Pembinaan Pendidikan (SPP)',
            'default_amount' => 350000,
            'active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Unpaid Invoice for October 2026
        $invOctId = (string) Str::uuid();
        DB::table('invoices')->insert([
            'id' => $invOctId,
            'school_id' => $schoolId,
            'student_id' => $studentId,
            'invoice_no' => 'INV/2026/10/0042',
            'period' => '2026-10',
            'due_on' => '2026-10-20',
            'total_amount' => 350000,
            'status' => 'unpaid',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('invoice_items')->insert([
            'id' => (string) Str::uuid(),
            'invoice_id' => $invOctId,
            'fee_type_id' => $feeTypeId,
            'description' => 'SPP Bulan Oktober 2026',
            'quantity' => 1,
            'unit_amount' => 350000,
            'line_amount' => 350000,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Paid Invoice for September 2026
        $invSepId = (string) Str::uuid();
        DB::table('invoices')->insert([
            'id' => $invSepId,
            'school_id' => $schoolId,
            'student_id' => $studentId,
            'invoice_no' => 'INV/2026/09/0115',
            'period' => '2026-09',
            'due_on' => '2026-09-20',
            'total_amount' => 350000,
            'status' => 'paid',
            'created_at' => now()->subMonth(),
            'updated_at' => now()->subMonth(),
        ]);

        DB::table('invoice_items')->insert([
            'id' => (string) Str::uuid(),
            'invoice_id' => $invSepId,
            'fee_type_id' => $feeTypeId,
            'description' => 'SPP Bulan September 2026',
            'quantity' => 1,
            'unit_amount' => 350000,
            'line_amount' => 350000,
            'created_at' => now()->subMonth(),
            'updated_at' => now()->subMonth(),
        ]);

        DB::table('payments')->insert([
            'id' => (string) Str::uuid(),
            'school_id' => $schoolId,
            'invoice_id' => $invSepId,
            'amount' => 350000,
            'method' => 'cash',
            'status' => 'completed',
            'reference' => 'KASIR-0091',
            'paid_at' => now()->subMonth(),
            'recorded_by' => $adminId,
            'created_at' => now()->subMonth(),
            'updated_at' => now()->subMonth(),
        ]);

        // 9. Announcement
        DB::table('announcements')->insert([
            'id' => (string) Str::uuid(),
            'school_id' => $schoolId,
            'title' => 'Peringatan Hari Guru Nasional dan Jadwal Ujian Tengah Semester',
            'body' => 'Diberitahukan kepada seluruh warga sekolah bahwa kegiatan Penilaian Tengah Semester akan dimulai pekan depan. Siswa diharapkan mempersiapkan diri dengan baik.',
            'published_at' => now(),
            'created_by' => $adminId,
            'status' => 'published',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
