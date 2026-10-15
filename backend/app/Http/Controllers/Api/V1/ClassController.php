<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClassController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $schoolId = $this->getSchoolId($request);

        $classes = DB::table('classes')
            ->leftJoin('school_memberships', 'classes.homeroom_membership_id', '=', 'school_memberships.id')
            ->leftJoin('users', 'school_memberships.user_id', '=', 'users.id')
            ->where('classes.school_id', $schoolId)
            ->select(
                'classes.id',
                'classes.name',
                'classes.grade_level',
                'users.name as homeroom_teacher_name'
            )
            ->get();

        return response()->json([
            'data' => $classes,
        ]);
    }

    public function students(Request $request, string $classId): JsonResponse
    {
        $schoolId = $this->getSchoolId($request);

        $students = DB::table('class_enrollments')
            ->join('students', 'class_enrollments.student_id', '=', 'students.id')
            ->where('class_enrollments.class_id', $classId)
            ->where('class_enrollments.status', 'active')
            ->where('students.school_id', $schoolId)
            ->select(
                'students.id',
                'students.admission_no',
                'students.nisn',
                'students.name',
                'students.gender',
                'students.status'
            )
            ->orderBy('students.name')
            ->get();

        return response()->json([
            'data' => $students,
        ]);
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
