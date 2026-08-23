<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Order extends Model
{
    protected $fillable = [
        'order_number',
        'customer_id',
        'shipping_method_id',
        'coupon_id',
        'status',
        'payment_status',
        'payment_method',
        'customer_name',
        'customer_phone',
        'customer_email',
        'shipping_city',
        'shipping_address',
        'subtotal',
        'discount_amount',
        'shipping_amount',
        'tax_amount',
        'points_to_redeem',
        'points_discount_amount',
        'points_earned',
        'points_redeemed',
        'total',
        'notes',
        'paid_at',
        'shipped_at',
        'delivered_at',
        'loyalty_processed_at',
    ];

    protected function casts(): array
    {
        return [
            'subtotal' => 'decimal:2',
            'discount_amount' => 'decimal:2',
            'shipping_amount' => 'decimal:2',
            'tax_amount' => 'decimal:2',
            'points_discount_amount' => 'decimal:2',
            'total' => 'decimal:2',
            'paid_at' => 'datetime',
            'shipped_at' => 'datetime',
            'delivered_at' => 'datetime',
            'loyalty_processed_at' => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Order $order): void {
            if (blank($order->order_number)) {
                $order->order_number = 'ORD-' . now()->format('Ymd') . '-' . strtoupper(Str::random(6));
            }
        });
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function shippingMethod(): BelongsTo
    {
        return $this->belongsTo(ShippingMethod::class);
    }

    public function coupon(): BelongsTo
    {
        return $this->belongsTo(Coupon::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function loyaltyTransactions(): HasMany
    {
        return $this->hasMany(LoyaltyTransaction::class);
    }

    public function recalculateTotals(): void
    {
        $subtotal = $this->items()->sum('total');
        $this->subtotal = $subtotal;
        $this->total = max(
            0,
            $subtotal
            - (float) $this->discount_amount
            - (float) $this->points_discount_amount
            + (float) $this->shipping_amount
            + (float) $this->tax_amount
        );
        $this->save();
    }
}
