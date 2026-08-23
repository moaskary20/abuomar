<?php

namespace App\Filament\Resources\Orders\Pages;

use App\Filament\Resources\Orders\OrderResource;
use App\Models\LoyaltySetting;
use App\Models\Order;
use App\Services\LoyaltyService;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;

class EditOrder extends EditRecord
{
    protected static string $resource = OrderResource::class;

    protected function getHeaderActions(): array
    {
        return [
            ViewAction::make()->label('عرض'),
            DeleteAction::make()->label('حذف'),
        ];
    }

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $points = max(0, (int) ($data['points_to_redeem'] ?? 0));
        $data['points_to_redeem'] = $points;
        $data['points_discount_amount'] = round($points * LoyaltySetting::currencyPerPoint(), 2);

        return $data;
    }

    protected function afterSave(): void
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

        $this->syncLoyalty($order->fresh());
    }

    protected function syncLoyalty(Order $order): void
    {
        $loyalty = app(LoyaltyService::class);

        try {
            if (in_array($order->status, ['cancelled'], true) || $order->payment_status === 'refunded') {
                $loyalty->reverseOrder($order);

                return;
            }

            $loyalty->processOrder($order);
        } catch (\Throwable $e) {
            Notification::make()
                ->title('تنبيه نقاط الولاء')
                ->body($e->getMessage())
                ->warning()
                ->send();
        }
    }
}
