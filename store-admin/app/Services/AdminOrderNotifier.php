<?php

namespace App\Services;

use App\Filament\Resources\Orders\OrderResource;
use App\Models\Order;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Notifications\Events\DatabaseNotificationsSent;
use Filament\Notifications\Notification;

class AdminOrderNotifier
{
    public function notifyNewOrder(Order $order): void
    {
        $users = User::query()->get();

        if ($users->isEmpty()) {
            return;
        }

        $url = OrderResource::getUrl('view', ['record' => $order], panel: 'admin');

        $notification = Notification::make()
            ->title('طلب جديد')
            ->body("طلب رقم {$order->order_number} من {$order->customer_name} — الإجمالي {$order->total} ج.م")
            ->icon('heroicon-o-shopping-bag')
            ->danger()
            ->actions([
                Action::make('view')
                    ->label('فتح الطلب')
                    ->url($url)
                    ->markAsRead(),
            ]);

        foreach ($users as $user) {
            // فوري بدون queue حتى يظهر الإشعار بدون تشغيل queue worker
            $user->notifyNow($notification->toDatabase());
            DatabaseNotificationsSent::dispatch($user);
        }
    }
}
