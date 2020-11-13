<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class PingController extends Controller
{
    /**
     * Handle the incoming request.
     *
     * @param \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function __invoke(Request $request): JsonResponse
    {
        try {
            if (!is_dir(Storage::disk('public')->path(''))) {
                throw new \RuntimeException('Filesytem or storage path is not available');
            }

            DB::connection()->getPdo();
            if (!User::first() instanceof User) {
                throw new \RuntimeException('First user is not available');
            }
        } catch(\Exception $exception) {
            return new JsonResponse([
                'error' => sprintf('%s: %s', get_class($exception), $exception->getMessage()),
            ], JsonResponse::HTTP_INTERNAL_SERVER_ERROR);
        }

        return new JsonResponse(['message' => 'pong']);
    }
}
