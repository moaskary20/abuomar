<?php

namespace App\Models;

class FawrySetting
{
    public const CODE = 'fawry';

    public static function enabled(): bool
    {
        return (bool) StoreSetting::getValue('fawry_enabled', '0');
    }

    public static function mode(): string
    {
        $mode = (string) StoreSetting::getValue('fawry_mode', 'sandbox');

        return in_array($mode, ['sandbox', 'live'], true) ? $mode : 'sandbox';
    }

    public static function isLive(): bool
    {
        return self::mode() === 'live';
    }

    public static function merchantCode(): string
    {
        return (string) StoreSetting::getValue('fawry_merchant_code', '');
    }

    public static function secureKey(): string
    {
        return (string) StoreSetting::getValue('fawry_secure_key', '');
    }

    public static function displayName(): string
    {
        return (string) StoreSetting::getValue('fawry_display_name', 'فوري');
    }

    public static function description(): string
    {
        return (string) StoreSetting::getValue(
            'fawry_description',
            'ادفع عبر فوري: كود مرجعي، بطاقة، أو محفظة إلكترونية',
        );
    }

    public static function language(): string
    {
        return (string) StoreSetting::getValue('fawry_language', 'ar-eg');
    }

    public static function currency(): string
    {
        return (string) StoreSetting::getValue('fawry_currency', 'EGP');
    }

    public static function enable3ds(): bool
    {
        return (bool) StoreSetting::getValue('fawry_enable_3ds', '1');
    }

    public static function returnUrl(): string
    {
        return (string) StoreSetting::getValue('fawry_return_url', '');
    }

    public static function webhookUrl(): string
    {
        return (string) StoreSetting::getValue('fawry_webhook_url', '');
    }

    public static function stagingBaseUrl(): string
    {
        return (string) StoreSetting::getValue(
            'fawry_staging_base_url',
            'https://atfawry.fawrystaging.com',
        );
    }

    public static function liveBaseUrl(): string
    {
        return (string) StoreSetting::getValue(
            'fawry_live_base_url',
            'https://www.atfawry.com',
        );
    }

    public static function baseUrl(): string
    {
        return rtrim(self::isLive() ? self::liveBaseUrl() : self::stagingBaseUrl(), '/');
    }

    public static function customerInstructions(): string
    {
        return (string) StoreSetting::getValue(
            'fawry_customer_instructions',
            'بعد تأكيد الطلب ستصلك تعليمات الدفع عبر فوري (كود مرجعي أو رابط دفع).',
        );
    }

    /**
     * قنوات الدفع المفعّلة داخل بوابة فوري.
     *
     * @return list<string>
     */
    public static function channels(): array
    {
        $raw = StoreSetting::getValue('fawry_channels', 'PayAtFawry,CARD,MWALLET');
        if (is_array($raw)) {
            return array_values(array_filter(array_map('strval', $raw)));
        }

        $parts = array_filter(array_map('trim', explode(',', (string) $raw)));

        return array_values($parts);
    }

    public static function isConfigured(): bool
    {
        return self::merchantCode() !== '' && self::secureKey() !== '';
    }

    /**
     * إعدادات آمنة للعرض في التطبيق (بدون المفتاح السري).
     *
     * @return array<string, mixed>
     */
    public static function publicConfig(): array
    {
        return [
            'provider' => self::CODE,
            'enabled' => self::enabled() && self::isConfigured(),
            'mode' => self::mode(),
            'merchant_code' => self::merchantCode(),
            'display_name' => self::displayName(),
            'description' => self::description(),
            'language' => self::language(),
            'currency' => self::currency(),
            'enable_3ds' => self::enable3ds(),
            'channels' => self::channels(),
            'customer_instructions' => self::customerInstructions(),
            'return_url' => self::returnUrl(),
            'configured' => self::isConfigured(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public static function all(): array
    {
        return [
            'fawry_enabled' => self::enabled(),
            'fawry_mode' => self::mode(),
            'fawry_merchant_code' => self::merchantCode(),
            'fawry_secure_key' => self::secureKey(),
            'fawry_display_name' => self::displayName(),
            'fawry_description' => self::description(),
            'fawry_language' => self::language(),
            'fawry_currency' => self::currency(),
            'fawry_channels' => self::channels(),
            'fawry_enable_3ds' => self::enable3ds(),
            'fawry_return_url' => self::returnUrl(),
            'fawry_webhook_url' => self::webhookUrl(),
            'fawry_staging_base_url' => self::stagingBaseUrl(),
            'fawry_live_base_url' => self::liveBaseUrl(),
            'fawry_customer_instructions' => self::customerInstructions(),
        ];
    }
}
