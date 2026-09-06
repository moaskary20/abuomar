<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class StoreSetting extends Model
{
    protected $fillable = [
        'key',
        'value',
        'group',
    ];

    public static function getValue(string $key, mixed $default = null): mixed
    {
        return Cache::rememberForever("store_setting_{$key}", function () use ($key, $default) {
            return static::query()->where('key', $key)->value('value') ?? $default;
        });
    }

    public static function setValue(string $key, mixed $value, string $group = 'general'): void
    {
        static::query()->updateOrCreate(
            ['key' => $key],
            ['value' => $value, 'group' => $group],
        );

        Cache::forget("store_setting_{$key}");
    }

    public static function isAppActive(): bool
    {
        $value = static::getValue('app_active', '1');
        if (is_bool($value)) {
            return $value;
        }

        $normalized = strtolower(trim((string) $value));

        return ! in_array($normalized, ['0', 'false', 'no', 'off', ''], true);
    }

    public static function appInactiveMessage(): string
    {
        $message = trim((string) static::getValue(
            'app_inactive_message',
            'شكرا لكم رجاء التوجهه الى اقرب فرع فى منطقتك',
        ));

        return $message !== ''
            ? $message
            : 'شكرا لكم رجاء التوجهه الى اقرب فرع فى منطقتك';
    }

    /**
     * @return array<string, mixed>
     */
    public static function publicStatus(): array
    {
        $active = self::isAppActive();

        return [
            'app_active' => $active,
            'orders_enabled' => $active,
            'inactive_message' => self::appInactiveMessage(),
        ];
    }
}
