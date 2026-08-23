<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Auth;

class StockMovement extends Model
{
    protected $fillable = [
        'product_id',
        'type',
        'quantity',
        'quantity_before',
        'quantity_after',
        'reference',
        'notes',
        'user_id',
    ];

    protected static function booted(): void
    {
        static::creating(function (StockMovement $movement): void {
            $product = Product::query()->findOrFail($movement->product_id);
            $before = (int) $product->quantity;
            $change = (int) $movement->quantity;

            $after = match ($movement->type) {
                'in' => $before + abs($change),
                'out' => max(0, $before - abs($change)),
                'adjustment' => abs($change),
                default => $before,
            };

            $movement->quantity_before = $before;
            $movement->quantity_after = $after;
            $movement->quantity = abs($change);
            $movement->user_id ??= Auth::id();

            $product->update(['quantity' => $after]);
        });
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
