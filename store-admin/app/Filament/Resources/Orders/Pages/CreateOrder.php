<?php

namespace App\Filament\Resources\Orders\Pages;

use App\Filament\Resources\Orders\OrderResource;
use App\Models\LoyaltySetting;
use App\Models\Order;
use App\Services\LoyaltyService;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\CreateRecord;

class CreateOrder extends CreateRecord
{
    protected static string $resource = OrderResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $points = max(0, (int) ($data['points_to_redeem'] ?? 0));
        $data['points_to_redeem'] = $points;
        $data['points_discount_amount'] = round($points * LoyaltySetting::currencyPerPoint(), 2);

        return $data;
    }

    protected function afterCreate(): void
    {
        /** @var Order $order */
        $order = $this->record;
        $subtotal = $order->items()->sum('total');
        $order->update([
            'subtotal' => $subtotal,
            'total' => max(
                0,
                $subtotal
                - (float) $order->discount_amount
                - (float) $order->points_discount_amount
                + (float) $order->shipping_amount
                + (float) $order->tax_amount
            ),
        ]);

        try {
            app(LoyaltyService::class)->processOrder($order->fresh());
        } catch (\Throwable $e) {
            Notification::make()
                ->title('تنبيه نقاط الولاء')
                ->body($e->getMessage())
                ->warning()
                ->send();
        }
    }
}
