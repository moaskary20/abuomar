<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Product extends Model
{
    protected $fillable = [
        'name',
        'slug',
        'sku',
        'barcode',
        'category_id',
        'short_description',
        'description',
        'price',
        'compare_price',
        'quantity',
        'low_stock_threshold',
        'track_quantity',
        'is_active',
        'is_featured',
        'image',
        'gallery',
        'weight',
        'unit',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'compare_price' => 'decimal:2',
            'weight' => 'decimal:2',
            'track_quantity' => 'boolean',
            'is_active' => 'boolean',
            'is_featured' => 'boolean',
            'gallery' => 'array',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Product $product): void {
            if (blank($product->slug)) {
                $product->slug = Str::slug($product->name) ?: Str::random(8);
            }
        });
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function stockMovements(): HasMany
    {
        return $this->hasMany(StockMovement::class);
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function isLowStock(): bool
    {
        return $this->track_quantity && $this->quantity <= $this->low_stock_threshold;
    }
}
