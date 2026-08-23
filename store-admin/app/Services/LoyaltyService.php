<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\LoyaltySetting;
use App\Models\LoyaltyTransaction;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class LoyaltyService
{
    public function calculateEarnablePoints(float $amount): int
    {
        if (! LoyaltySetting::enabled() || $amount < LoyaltySetting::minOrderToEarn()) {
            return 0;
        }

        return (int) floor($amount * LoyaltySetting::pointsPerCurrency());
    }

    public function calculateDiscountFromPoints(int $points): float
    {
        if ($points <= 0) {
            return 0.0;
        }

        return round($points * LoyaltySetting::currencyPerPoint(), 2);
    }

    public function pointsNeededForAmount(float $amount): int
    {
        $rate = LoyaltySetting::currencyPerPoint();

        if ($rate <= 0 || $amount <= 0) {
            return 0;
        }

        return (int) ceil($amount / $rate);
    }

    public function maxRedeemablePoints(Customer $customer, float $orderSubtotal): int
    {
        if (! LoyaltySetting::enabled()) {
            return 0;
        }

        $balance = (int) $customer->loyalty_points;
        $min = LoyaltySetting::minPointsToRedeem();

        if ($balance < $min) {
            return 0;
        }

        $maxDiscount = round($orderSubtotal * (LoyaltySetting::maxRedeemPercent() / 100), 2);
        $maxByPercent = $this->pointsNeededForAmount($maxDiscount);

        return min($balance, $maxByPercent);
    }

    public function processOrder(Order $order): void
    {
        if (! LoyaltySetting::enabled() || ! $order->customer_id || $order->loyalty_processed_at) {
            return;
        }

        $shouldEarn = match (LoyaltySetting::earnOn()) {
            'delivered' => $order->status === 'delivered' && $order->payment_status === 'paid',
            default => $order->payment_status === 'paid',
        };

        if (! $shouldEarn) {
            return;
        }

        DB::transaction(function () use ($order): void {
            $order = Order::query()->lockForUpdate()->find($order->id);

            if (! $order || $order->loyalty_processed_at || ! $order->customer_id) {
                return;
            }

            $customer = Customer::query()->lockForUpdate()->find($order->customer_id);

            if (! $customer) {
                return;
            }

            $redeemPoints = (int) $order->points_to_redeem;

            if ($redeemPoints > 0) {
                if ($customer->loyalty_points < $redeemPoints) {
                    throw new InvalidArgumentException('رصيد نقاط العميل غير كافٍ للاستبدال.');
                }

                if ($redeemPoints < LoyaltySetting::minPointsToRedeem()) {
                    throw new InvalidArgumentException('عدد النقاط أقل من الحد الأدنى للاستبدال.');
                }

                $discount = $this->calculateDiscountFromPoints($redeemPoints);
                $this->applyDelta(
                    $customer,
                    -$redeemPoints,
                    LoyaltyTransaction::TYPE_REDEEM,
                    "استبدال نقاط على الطلب {$order->order_number}",
                    $order,
                );

                $order->points_redeemed = $redeemPoints;
                $order->points_discount_amount = $discount;
            }

            $earnableBase = max(0, (float) $order->total);
            $pointsEarned = $this->calculateEarnablePoints($earnableBase);

            if ($pointsEarned > 0) {
                $this->applyDelta(
                    $customer,
                    $pointsEarned,
                    LoyaltyTransaction::TYPE_EARN,
                    "كسب نقاط من الطلب {$order->order_number}",
                    $order,
                );
                $order->points_earned = $pointsEarned;
            }

            $order->loyalty_processed_at = now();
            $order->save();
        });
    }

    public function reverseOrder(Order $order, ?string $reason = null): void
    {
        if (! $order->loyalty_processed_at || ! $order->customer_id) {
            return;
        }

        DB::transaction(function () use ($order, $reason): void {
            $order = Order::query()->lockForUpdate()->find($order->id);

            if (! $order || ! $order->loyalty_processed_at || ! $order->customer_id) {
                return;
            }

            $customer = Customer::query()->lockForUpdate()->find($order->customer_id);

            if (! $customer) {
                return;
            }

            if ((int) $order->points_earned > 0) {
                $this->applyDelta(
                    $customer,
                    -(int) $order->points_earned,
                    LoyaltyTransaction::TYPE_REFUND,
                    $reason ?: "خصم نقاط مكتسبة بسبب إلغاء/استرجاع الطلب {$order->order_number}",
                    $order,
                );
            }

            if ((int) $order->points_redeemed > 0) {
                $this->applyDelta(
                    $customer,
                    (int) $order->points_redeemed,
                    LoyaltyTransaction::TYPE_REFUND,
                    $reason ?: "إعادة نقاط مستبدلة بسبب إلغاء/استرجاع الطلب {$order->order_number}",
                    $order,
                );
            }

            $order->points_earned = 0;
            $order->points_redeemed = 0;
            $order->loyalty_processed_at = null;
            $order->save();
        });
    }

    public function adjust(Customer $customer, int $points, string $description, ?User $user = null): LoyaltyTransaction
    {
        if ($points === 0) {
            throw new InvalidArgumentException('قيمة التعديل يجب ألا تكون صفراً.');
        }

        return DB::transaction(function () use ($customer, $points, $description, $user) {
            $customer = Customer::query()->lockForUpdate()->findOrFail($customer->id);

            return $this->applyDelta(
                $customer,
                $points,
                LoyaltyTransaction::TYPE_ADJUST,
                $description,
                null,
                $user,
            );
        });
    }

    protected function applyDelta(
        Customer $customer,
        int $points,
        string $type,
        string $description,
        ?Order $order = null,
        ?User $user = null,
    ): LoyaltyTransaction {
        $newBalance = (int) $customer->loyalty_points + $points;

        if ($newBalance < 0) {
            throw new InvalidArgumentException('رصيد النقاط لا يكفي لإتمام العملية.');
        }

        $customer->loyalty_points = $newBalance;

        if ($points > 0) {
            $customer->loyalty_points_earned = (int) $customer->loyalty_points_earned + $points;
        } else {
            $customer->loyalty_points_redeemed = (int) $customer->loyalty_points_redeemed + abs($points);
        }

        $customer->save();

        return LoyaltyTransaction::query()->create([
            'customer_id' => $customer->id,
            'order_id' => $order?->id,
            'user_id' => $user?->id,
            'type' => $type,
            'points' => $points,
            'balance_after' => $newBalance,
            'description' => $description,
        ]);
    }
}
