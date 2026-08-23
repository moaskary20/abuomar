<?php

namespace App\Support;

class ApiMedia
{
    public static function url(?string $path): ?string
    {
        if ($path === null || trim($path) === '') {
            return null;
        }

        $path = trim($path);
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        $normalized = ltrim($path, '/');
        if (str_starts_with($normalized, 'storage/')) {
            $normalized = substr($normalized, strlen('storage/'));
        }

        $base = request()?->getSchemeAndHttpHost()
            ?: rtrim((string) config('app.url'), '/');

        return $base.'/storage/'.$normalized;
    }

    public static function urls(?array $paths): array
    {
        if (! is_array($paths)) {
            return [];
        }

        return collect($paths)
            ->map(fn ($p) => self::url(is_string($p) ? $p : null))
            ->filter()
            ->values()
            ->all();
    }
}
