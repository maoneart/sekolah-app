<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AnnouncementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $schoolId = $this->getSchoolId($request);
        $user = $request->user();

        $announcements = DB::table('announcements')
            ->leftJoin('announcement_reads', function ($join) use ($user) {
                $join->on('announcements.id', '=', 'announcement_reads.announcement_id')
                    ->where('announcement_reads.user_id', $user->id);
            })
            ->where('announcements.school_id', $schoolId)
            ->where('announcements.status', 'published')
            ->select(
                'announcements.id',
                'announcements.title',
                'announcements.body',
                'announcements.published_at',
                DB::raw('case when announcement_reads.read_at is not null then true else false end as is_read')
            )
            ->orderByDesc('announcements.published_at')
            ->paginate(15);

        return response()->json([
            'data' => $announcements->items(),
            'meta' => [
                'current_page' => $announcements->currentPage(),
                'total' => $announcements->total(),
            ],
        ]);
    }

    public function markAsRead(Request $request, string $id): JsonResponse
    {
        $user = $request->user();

        DB::table('announcement_reads')->updateOrInsert(
            ['announcement_id' => $id, 'user_id' => $user->id],
            ['read_at' => now()]
        );

        return response()->json(['message' => 'Pengumuman telah ditandai dibaca.']);
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
