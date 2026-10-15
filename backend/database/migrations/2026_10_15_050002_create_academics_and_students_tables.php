<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Academic Years
        Schema::create('academic_years', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->string('name', 50); // e.g. 2026/2027
            $table->date('starts_on');
            $table->date('ends_on');
            $table->boolean('is_active')->default(false);
            $table->timestamps();
        });

        // 2. Semesters
        Schema::create('semesters', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('academic_year_id')->constrained('academic_years')->cascadeOnDelete();
            $table->string('name', 50); // Ganjil / Genap
            $table->date('starts_on');
            $table->date('ends_on');
            $table->boolean('is_active')->default(false);
            $table->timestamps();
        });

        // 3. Students
        Schema::create('students', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->string('admission_no', 50); // NIS
            $table->string('nisn', 50)->nullable();
            $table->string('name');
            $table->date('birth_date')->nullable();
            $table->enum('gender', ['L', 'P']);
            $table->text('address')->nullable();
            $table->date('admission_date')->nullable(); // Tanggal Masuk
            $table->date('graduation_date')->nullable(); // Tanggal Lulus
            $table->string('status', 20)->default('active'); // active, graduated, transferred, dropped
            $table->timestamps();

            $table->unique(['school_id', 'admission_no']);
        });

        // 4. Guardians (Orang tua / wali)
        Schema::create('guardians', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignUuid('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('name');
            $table->string('phone', 30)->nullable();
            $table->string('email')->nullable();
            $table->timestamps();
        });

        // 5. Student Guardians pivot
        Schema::create('student_guardians', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('student_id')->constrained('students')->cascadeOnDelete();
            $table->foreignUuid('guardian_id')->constrained('guardians')->cascadeOnDelete();
            $table->string('relationship', 30); // ayah, ibu, wali
            $table->boolean('is_primary')->default(true);
            $table->boolean('portal_access')->default(true);
            $table->timestamps();

            $table->unique(['student_id', 'guardian_id']);
        });

        // 6. Classes
        Schema::create('classes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignUuid('academic_year_id')->constrained('academic_years')->cascadeOnDelete();
            $table->foreignUuid('homeroom_membership_id')->nullable()->constrained('school_memberships')->nullOnDelete();
            $table->string('name', 50); // e.g. X RPL 1
            $table->string('grade_level', 20); // 10, 11, 12
            $table->timestamps();
        });

        // 7. Class Enrollments
        Schema::create('class_enrollments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('student_id')->constrained('students')->cascadeOnDelete();
            $table->foreignUuid('class_id')->constrained('classes')->cascadeOnDelete();
            $table->date('starts_on');
            $table->date('ends_on')->nullable();
            $table->string('status', 20)->default('active'); // active, completed, moved
            $table->timestamps();
        });

        // 8. Subjects (Mata Pelajaran)
        Schema::create('subjects', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->string('code', 30);
            $table->string('name');
            $table->timestamps();

            $table->unique(['school_id', 'code']);
        });

        // 9. Teaching Assignments
        Schema::create('teaching_assignments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('class_id')->constrained('classes')->cascadeOnDelete();
            $table->foreignUuid('subject_id')->nullable()->constrained('subjects')->cascadeOnDelete();
            $table->foreignUuid('teacher_membership_id')->constrained('school_memberships')->cascadeOnDelete();
            $table->timestamps();
        });

        // 10. Student Cards (Kartu Pelajar with QR Token Hash)
        Schema::create('student_cards', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignUuid('student_id')->constrained('students')->cascadeOnDelete();
            $table->string('token_hash', 64)->unique(); // SHA256 of opaque card QR token
            $table->string('card_number', 50)->nullable();
            $table->timestamp('issued_at');
            $table->timestamp('expires_at')->nullable();
            $table->timestamp('revoked_at')->nullable();
            $table->foreignUuid('issued_by')->nullable()->constrained('users')->nullOnDelete();
            $table->uuid('replaced_card_id')->nullable();
            $table->timestamps();

            $table->index(['school_id', 'student_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_cards');
        Schema::dropIfExists('teaching_assignments');
        Schema::dropIfExists('subjects');
        Schema::dropIfExists('class_enrollments');
        Schema::dropIfExists('classes');
        Schema::dropIfExists('student_guardians');
        Schema::dropIfExists('guardians');
        Schema::dropIfExists('students');
        Schema::dropIfExists('semesters');
        Schema::dropIfExists('academic_years');
    }
};
