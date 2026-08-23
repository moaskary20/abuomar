<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerAddress extends Model
{
    protected $fillable = [
        'customer_id',
        'label',
        'recipient_name',
        'phone',
        'city',
        'area',
        'street',
        'building',
        'floor',
        'apartment',
        'notes',
        'is_default',
    ];

    protected function casts(): array
    {
        return [
            'is_default' => 'boolean',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function getFullAddressAttribute(): string
    {
        return collect([
            $this->city,
            $this->area,
            $this->street,
            $this->building ? 'مبنى '.$this->building : null,
            $this->floor ? 'دور '.$this->floor : null,
            $this->apartment ? 'شقة '.$this->apartment : null,
        ])->filter()->implode(' - ');
    }

    protected static function booted(): void
    {
        static::saving(function (CustomerAddress $address): void {
            if (! $address->is_default) {
                return;
            }

            static::query()
                ->where('customer_id', $address->customer_id)
                ->when($address->exists, fn ($q) => $q->whereKeyNot($address->id))
                ->update(['is_default' => false]);
        });
    }
}
