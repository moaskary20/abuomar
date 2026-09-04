<?php

namespace App\Support;

class Phone
{
    /**
     * يوحّد رقم الجوال لأرقام فقط (مع دعم الصيغة المصرية +20).
     */
    public static function normalize(?string $phone): ?string
    {
        if ($phone === null) {
            return null;
        }

        $digits = preg_replace('/\D+/', '', $phone) ?? '';
        if ($digits === '') {
            return null;
        }

        // +20xxxxxxxxxxx أو 20xxxxxxxxxxx → 0xxxxxxxxxxx
        if (str_starts_with($digits, '20') && strlen($digits) >= 11) {
            $local = substr($digits, 2);
            if (str_starts_with($local, '0')) {
                return $local;
            }

            return '0'.$local;
        }

        return $digits;
    }

    public static function isValidEgyptianMobile(?string $phone): bool
    {
        $normalized = self::normalize($phone);

        return $normalized !== null && (bool) preg_match('/^01[0125][0-9]{8}$/', $normalized);
    }
}
