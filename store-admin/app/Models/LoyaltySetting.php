<?php

namespace App\Models;

class LoyaltySetting
{
    public static function enabled(): bool
    {
        return (bool) StoreSetting::getValue('loyalty_enabled', '1');
    }

    /** كم نقطة يكتسبها العميل لكل جنيه مصري من مبلغ الطلب */
    public static function pointsPerCurrency(): float
    {
        return (float) StoreSetting::getValue('loyalty_points_per_currency', '1');
    }

    /** قيمة النقطة بالجنيه عند الاستبدال */
    public static function currencyPerPoint(): float
    {
        return (float) StoreSetting::getValue('loyalty_currency_per_point', '0.1');
    }

    public static function minOrderToEarn(): float
    {
        return (float) StoreSetting::getValue('loyalty_min_order_to_earn', '0');
    }

    public static function minPointsToRedeem(): int
    {
        return (int) StoreSetting::getValue('loyalty_min_points_to_redeem', '50');
    }

    /** أقصى نسبة من قيمة الطلب يمكن خصمها بالنقاط */
    public static function maxRedeemPercent(): float
    {
        return (float) StoreSetting::getValue('loyalty_max_redeem_percent', '50');
    }

    /** متى تُمنح النقاط: paid | delivered */
    public static function earnOn(): string
    {
        return (string) StoreSetting::getValue('loyalty_earn_on', 'paid');
    }

    /**
     * @return array<string, mixed>
     */
    public static function all(): array
    {
        return [
            'loyalty_enabled' => self::enabled(),
            'loyalty_points_per_currency' => self::pointsPerCurrency(),
            'loyalty_currency_per_point' => self::currencyPerPoint(),
            'loyalty_min_order_to_earn' => self::minOrderToEarn(),
            'loyalty_min_points_to_redeem' => self::minPointsToRedeem(),
            'loyalty_max_redeem_percent' => self::maxRedeemPercent(),
            'loyalty_earn_on' => self::earnOn(),
        ];
    }
}
