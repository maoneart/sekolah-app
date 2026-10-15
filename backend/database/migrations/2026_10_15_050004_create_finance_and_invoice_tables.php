<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Fee Types (Jenis Biaya / Master SPP)
        Schema::create('fee_types', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->string('code', 50);
            $table->string('name');
            $table->unsignedBigInteger('default_amount')->default(0); // integer rupiah
            $table->boolean('active')->default(true);
            $table->timestamps();

            $table->unique(['school_id', 'code']);
        });

        // 2. Invoices (Tagihan Siswa)
        Schema::create('invoices', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignUuid('student_id')->constrained('students')->cascadeOnDelete();
            $table->string('invoice_no', 50);
            $table->string('period', 20); // e.g. 2026-10
            $table->date('due_on');
            $table->unsignedBigInteger('total_amount')->default(0); // snapshot total
            $table->string('status', 20)->default('unpaid'); // unpaid, paid, partially_paid, void
            $table->timestamps();

            $table->unique(['school_id', 'invoice_no']);
            $table->index(['student_id', 'period']);
            $table->index(['school_id', 'status', 'due_on']);
        });

        // 3. Invoice Items
        Schema::create('invoice_items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('invoice_id')->constrained('invoices')->cascadeOnDelete();
            $table->foreignUuid('fee_type_id')->nullable()->constrained('fee_types')->nullOnDelete();
            $table->string('description');
            $table->integer('quantity')->default(1);
            $table->unsignedBigInteger('unit_amount');
            $table->unsignedBigInteger('line_amount');
            $table->timestamps();
        });

        // 4. Payments
        Schema::create('payments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignUuid('invoice_id')->constrained('invoices')->cascadeOnDelete();
            $table->unsignedBigInteger('amount');
            $table->string('method', 30)->default('cash'); // cash, transfer, gateway
            $table->string('status', 20)->default('completed'); // pending, completed, failed, refunded
            $table->string('reference')->nullable();
            $table->timestamp('paid_at')->useCurrent();
            $table->foreignUuid('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        // 5. Payment Events (Webhook idempotency)
        Schema::create('payment_events', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('payment_id')->nullable()->constrained('payments')->nullOnDelete();
            $table->string('source', 50); // e.g. xendit, midtrans
            $table->string('event_id')->unique();
            $table->string('payload_hash', 64);
            $table->timestamp('received_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_events');
        Schema::dropIfExists('payments');
        Schema::dropIfExists('invoice_items');
        Schema::dropIfExists('invoices');
        Schema::dropIfExists('fee_types');
    }
};
