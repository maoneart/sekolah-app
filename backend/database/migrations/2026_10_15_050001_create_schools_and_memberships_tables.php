<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Schools
        Schema::create('schools', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('code', 50)->unique();
            $table->string('name');
            $table->string('timezone', 50)->default('Asia/Jakarta');
            $table->json('settings')->nullable();
            $table->string('status', 20)->default('active'); // active, suspended
            $table->timestamps();
        });

        // 2. School Memberships
        Schema::create('school_memberships', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('status', 20)->default('active'); // active, inactive
            $table->timestamps();

            $table->unique(['school_id', 'user_id']);
        });

        // 3. Roles
        Schema::create('roles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->nullable()->constrained('schools')->cascadeOnDelete();
            $table->string('name');
            $table->string('guard_name', 50)->default('sanctum');
            $table->string('description')->nullable();
            $table->timestamps();

            $table->unique(['school_id', 'name']);
        });

        // 4. Permissions
        Schema::create('permissions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name')->unique();
            $table->string('guard_name', 50)->default('sanctum');
            $table->string('category', 50)->nullable();
            $table->timestamps();
        });

        // 5. Role Permissions
        Schema::create('role_permissions', function (Blueprint $table) {
            $table->foreignUuid('role_id')->constrained('roles')->cascadeOnDelete();
            $table->foreignUuid('permission_id')->constrained('permissions')->cascadeOnDelete();

            $table->primary(['role_id', 'permission_id']);
        });

        // 6. Membership Roles
        Schema::create('membership_roles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('membership_id')->constrained('school_memberships')->cascadeOnDelete();
            $table->foreignUuid('role_id')->constrained('roles')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['membership_id', 'role_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('membership_roles');
        Schema::dropIfExists('role_permissions');
        Schema::dropIfExists('permissions');
        Schema::dropIfExists('roles');
        Schema::dropIfExists('school_memberships');
        Schema::dropIfExists('schools');
    }
};
