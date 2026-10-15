<?php

use App\Http\Controllers\Api\V1\AnnouncementController;
use App\Http\Controllers\Api\V1\AttendanceController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ClassController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\FinanceController;
use App\Http\Controllers\Api\V1\StudentController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - V1
|--------------------------------------------------------------------------
| Prefix: /api/v1 (configured in bootstrap/app.php)
| Source of Truth for School Management System
*/

// Public Authentication
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
});

// Protected routes (Requires Sanctum personal access token)
Route::middleware('auth:sanctum')->group(function () {
    // Auth & Identity
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/schools', [AuthController::class, 'schools']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Master Data: Students & Student Cards (Kartu Pelajar)
    Route::get('/students', [StudentController::class, 'index']);
    Route::get('/students/{student}', [StudentController::class, 'show']);
    Route::post('/students/{student}/cards/issue', [StudentController::class, 'issueCard']);
    Route::post('/student-cards/{card}/revoke', [StudentController::class, 'revokeCard']);

    // Classes
    Route::get('/classes', [ClassController::class, 'index']);
    Route::get('/classes/{class}/students', [ClassController::class, 'students']);

    // Attendance & QR Scanner
    Route::get('/attendance', [AttendanceController::class, 'index']);
    Route::post('/attendance/scans', [AttendanceController::class, 'scan']);
    Route::get('/attendance/sessions/{session}/records', [AttendanceController::class, 'sessionRecords']);

    // Finance & Invoices
    Route::get('/invoices', [FinanceController::class, 'invoices']);
    Route::get('/invoices/{invoice}', [FinanceController::class, 'show']);
    Route::post('/invoices/{invoice}/payments', [FinanceController::class, 'recordPayment']);

    // Announcements
    Route::get('/announcements', [AnnouncementController::class, 'index']);
    Route::post('/announcements/{id}/read', [AnnouncementController::class, 'markAsRead']);
});
