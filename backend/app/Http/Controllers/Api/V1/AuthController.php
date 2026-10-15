<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'login' => 'required|string', // email or phone
            'password' => 'required|string',
            'device_name' => 'nullable|string',
        ]);

        $user = User::where('email', $validated['login'])
            ->orWhere('phone', $validated['login'])
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'login' => ['Email/nomor telepon atau kata sandi tidak cocok.'],
            ]);
        }

        if ($user->status !== 'active') {
            return response()->json([
                'message' => 'Akun Anda tidak aktif atau ditangguhkan.',
            ], 403);
        }

        $user->update(['last_login_at' => now()]);

        $deviceName = $validated['device_name'] ?? 'Mobile App';
        $token = $user->createToken($deviceName)->plainTextToken;

        // Retrieve user memberships & roles
        $membership = DB::table('school_memberships')
            ->join('schools', 'school_memberships.school_id', '=', 'schools.id')
            ->where('school_memberships.user_id', $user->id)
            ->where('school_memberships.status', 'active')
            ->select('schools.id as school_id', 'schools.name as school_name', 'school_memberships.id as membership_id')
            ->first();

        $roles = [];
        if ($membership) {
            $roles = DB::table('membership_roles')
                ->join('roles', 'membership_roles.role_id', '=', 'roles.id')
                ->where('membership_roles.membership_id', $membership->membership_id)
                ->pluck('roles.name')
                ->toArray();
        }

        return response()->json([
            'message' => 'Login berhasil.',
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'active_school_id' => $membership?->school_id,
                    'active_school_name' => $membership?->school_name,
                    'roles' => $roles,
                ],
            ],
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        $membership = DB::table('school_memberships')
            ->join('schools', 'school_memberships.school_id', '=', 'schools.id')
            ->where('school_memberships.user_id', $user->id)
            ->where('school_memberships.status', 'active')
            ->select('schools.id as school_id', 'schools.name as school_name', 'school_memberships.id as membership_id')
            ->first();

        $roles = [];
        if ($membership) {
            $roles = DB::table('membership_roles')
                ->join('roles', 'membership_roles.role_id', '=', 'roles.id')
                ->where('membership_roles.membership_id', $membership->membership_id)
                ->pluck('roles.name')
                ->toArray();
        }

        return response()->json([
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'active_school_id' => $membership?->school_id,
                'active_school_name' => $membership?->school_name,
                'roles' => $roles,
            ],
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Berhasil keluar dari akun.',
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate(['login' => 'required|string']);

        // As specified in blueprint: Do not reveal whether user exists
        return response()->json([
            'message' => 'Jika akun terdaftar, instruksi pemulihan kata sandi telah dikirimkan.',
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }

    public function schools(Request $request): JsonResponse
    {
        $user = $request->user();

        $schools = DB::table('school_memberships')
            ->join('schools', 'school_memberships.school_id', '=', 'schools.id')
            ->where('school_memberships.user_id', $user->id)
            ->where('school_memberships.status', 'active')
            ->select('schools.id', 'schools.code', 'schools.name', 'schools.status')
            ->get();

        return response()->json([
            'data' => $schools,
            'meta' => [
                'request_id' => (string) str()->uuid(),
            ],
        ]);
    }
}
