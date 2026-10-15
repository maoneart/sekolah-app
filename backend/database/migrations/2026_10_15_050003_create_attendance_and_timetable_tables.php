<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Attendance Sessions
        Schema::create('attendance_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignUuid('class_id')->constrained('classes')->cascadeOnDelete();
            $table->date('date');
            $table->string('session_type', 30)->default('daily'); // daily, morning, subject
            $table->foreignUuid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status', 20)->default('open'); // open, closed, finalized
            $table->timestamps();

            $table->unique(['class_id', 'date', 'session_type']);
            $table->index(['school_id', 'date']);
        });

        // 2. Attendance Records
        Schema::create('attendance_records', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('session_id')->constrained('attendance_sessions')->cascadeOnDelete();
            $table->foreignUuid('student_id')->constrained('students')->cascadeOnDelete();
            $table->enum('status', ['hadir', 'izin', 'sakit', 'alpa']);
            $table->string('source', 20)->default('qr'); // qr, manual
            $table->string('note')->nullable();
            $table->foreignUuid('marked_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('marked_at')->useCurrent();
            $table->string('device_id')->nullable();
            $table->string('idempotency_key')->nullable()->unique();
            $table->timestamps();

            $table->unique(['session_id', 'student_id']);
        });

        // 3. Timetables (Jadwal Pelajaran)
        Schema::create('timetables', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignUuid('class_id')->constrained('classes')->cascadeOnDelete();
            $table->foreignUuid('subject_id')->constrained('subjects')->cascadeOnDelete();
            $table->foreignUuid('teacher_membership_id')->nullable()->constrained('school_memberships')->nullOnDelete();
            $table->tinyInteger('weekday'); // 1 = Senin, 7 = Minggu
            $table->time('starts_at');
            $table->time('ends_at');
            $table->string('room', 50)->nullable();
            $table->date('valid_from')->nullable();
            $table->date('valid_to')->nullable();
            $table->timestamps();

            $table->index(['school_id', 'class_id', 'weekday']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('timetables');
        Schema::dropIfExists('attendance_records');
        Schema::dropIfExists('attendance_sessions');
    }
};
