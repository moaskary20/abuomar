<?php

namespace App\Models;

use App\Support\Phone;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Customer extends Authenticatable
{
    use HasApiTokens;
    use Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'city',
        'address',
        'notes',
        'is_active',
        'loyalty_points',
        'loyalty_points_earned',
        'loyalty_points_redeemed',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'password' => 'hashed',
        ];
    }

    protected static function booted(): void
    {
        static::saving(function (Customer $customer): void {
            if ($customer->phone !== null) {
                $customer->phone = Phone::normalize($customer->phone);
            }
        });
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function loyaltyTransactions(): HasMany
    {
        return $this->hasMany(LoyaltyTransaction::class);
    }

    public function addresses(): HasMany
    {
        return $this->hasMany(CustomerAddress::class);
    }

    public function favorites(): BelongsToMany
    {
        return $this->belongsToMany(Product::class, 'favorites')->withTimestamps();
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'city' => $this->city,
            'address' => $this->address,
            'is_active' => (bool) $this->is_active,
            'loyalty_points' => (int) ($this->loyalty_points ?? 0),
        ];
    }
}
