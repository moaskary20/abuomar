<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LoyaltyTransaction extends Model
{
    public const TYPE_EARN = 'earn';

    public const TYPE_REDEEM = 'redeem';

    public const TYPE_ADJUST = 'adjust';

    public const TYPE_REFUND = 'refund';

    protected $fillable = [
        'customer_id',
        'order_id',
        'user_id',
        'type',
        'points',
        'balance_after',
        'description',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'meta' => 'array',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public static function typeLabel(string $type): string
    {
        return match ($type) {
            self::TYPE_EARN => 'كسب',
            self::TYPE_REDEEM => 'استبدال',
            self::TYPE_ADJUST => 'تعديل يدوي',
            self::TYPE_REFUND => 'استرجاع',
            default => $type,
        };
    }
}
