<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class StudentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $schoolId = $this->getSchoolId($request);

        $query = DB::table('students')
            ->leftJoin('class_enrollments', function ($join) {
                $join->on('students.id', '=', 'class_enrollments.student_id')
                    ->where('class_enrollments.status', 'active');
            })
            ->leftJoin('classes', 'class_enrollments.class_id', '=', 'classes.id')
            ->where('students.school_id', $schoolId)
            ->select(
                'students.id',
                'students.admission_no',
                'students.nisn',
                'students.name',
                'students.gender',
                'students.status',
                'classes.name as class_name'
            );

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('students.name', 'like', "%{$search}%")
                    ->orWhere('students.admission_no', 'like', "%{$search}%");
            });
        }

        if ($classId = $request->query('class_id')) {
            $query->where('classes.id', $classId);
        }

        $perPage = min((int) ($request->query('per_page', 15)), 100);
        $students = $query->paginate($perPage);

        return response()->json([
            'data' => $students->items(),
            'meta' => [
                'current_page' => $students->currentPage(),
                'per_page' => $students->perPage(),
                'total' => $students->total(),
                'last_page' => $students->lastPage(),
            ],
        ]);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $schoolId = $this->getSchoolId($request);

        $student = DB::table('students')
            ->leftJoin('class_enrollments', function ($join) {
                $join->on('students.id', '=', 'class_enrollments.student_id')
                    ->where('class_enrollments.status', 'active');
            })
            ->leftJoin('classes', 'class_enrollments.class_id', '=', 'classes.id')
            ->where('students.school_id', $schoolId)
            ->where('students.id', $id)
            ->select(
                'students.*',
                'classes.name as class_name',
                'classes.id as class_id'
            )
            ->first();

        if (! $student) {
            return response()->json(['message' => 'Siswa tidak ditemukan.'], 404);
        }

        // Active Student Card (without plain token)
        $card = DB::table('student_cards')
            ->where('student_id', $student->id)
            ->whereNull('revoked_at')
            ->select('id', 'card_number', 'issued_at', 'expires_at')
            ->first();

        // Guardians
        $guardians = DB::table('student_guardians')
            ->join('guardians', 'student_guardians.guardian_id', '=', 'guardians.id')
            ->where('student_guardians.student_id', $student->id)
            ->select('guardians.name', 'guardians.phone', 'student_guardians.relationship')
            ->get();

        return response()->json([
            'data' => [
                'student' => $student,
                'card' => $card,
                'guardians' => $guardians,
            ],
        ]);
    }

    /**
     * Issue a new Kartu Pelajar (generates opaque token for QR, stores only SHA256 hash).
     */
    public function issueCard(Request $request, string $studentId): JsonResponse
    {
        $schoolId = $this->getSchoolId($request);

        $student = DB::table('students')
            ->where('school_id', $schoolId)
            ->where('id', $studentId)
            ->first();

        if (! $student) {
            return response()->json(['message' => 'Siswa tidak ditemukan.'], 404);
        }

        // Revoke any previous active cards
        DB::table('student_cards')
            ->where('student_id', $studentId)
            ->whereNull('revoked_at')
            ->update(['revoked_at' => now()]);

        // Generate high-entropy opaque token
        $rawToken = 'KP_' . Str::random(32);
        $tokenHash = hash('sha256', $rawToken);

        $cardId = (string) Str::uuid();
        DB::table('student_cards')->insert([
            'id' => $cardId,
            'school_id' => $schoolId,
            'student_id' => $studentId,
            'token_hash' => $tokenHash,
            'card_number' => 'KP-' . date('Y') . '-' . substr($student->admission_no, -4),
            'issued_at' => now(),
            'issued_by' => $request->user()->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'message' => 'Kartu Pelajar berhasil diterbitkan.',
            'data' => [
                'card_id' => $cardId,
                'card_token' => $rawToken, // Sent once for printing QR
                'student_name' => $student->name,
                'admission_no' => $student->admission_no,
            ],
        ], 201);
    }

    public function revokeCard(Request $request, string $cardId): JsonResponse
    {
        $schoolId = $this->getSchoolId($request);

        $updated = DB::table('student_cards')
            ->where('school_id', $schoolId)
            ->where('id', $cardId)
            ->whereNull('revoked_at')
            ->update(['revoked_at' => now()]);

        if (! $updated) {
            return response()->json(['message' => 'Kartu tidak ditemukan atau sudah dinonaktifkan.'], 404);
        }

        return response()->json(['message' => 'Kartu Pelajar berhasil dinonaktifkan.']);
    }

    private function getSchoolId(Request $request): string
    {
        $headerSchoolId = $request->header('X-School-Id');
        if ($headerSchoolId) return $headerSchoolId;

        $membership = DB::table('school_memberships')
            ->where('user_id', $request->user()->id)
            ->where('status', 'active')
            ->first();

        return $membership?->school_id ?? '';
    }
}
