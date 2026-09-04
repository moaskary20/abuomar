<?php

namespace App\Services;

use App\Models\FawrySetting;
use App\Models\Order;
use App\Models\PaymentMethod;

class FawryService
{
    /**
     * مزامنة وسيلة الدفع «فوري» في جدول payment_methods حسب الإعدادات.
     */
    public function syncPaymentMethod(): PaymentMethod
    {
        $enabled = FawrySetting::enabled() && FawrySetting::isConfigured();

        return PaymentMethod::query()->updateOrCreate(
            ['code' => FawrySetting::CODE],
            [
                'name' => FawrySetting::displayName() ?: 'فوري',
                'description' => FawrySetting::description(),
                'icon' => 'account_balance',
                'sort_order' => 20,
                'is_active' => $enabled,
                'is_default' => false,
                'requires_online' => true,
            ],
        );
    }

    /**
     * توقيع طلب الشحن حسب توثيق FawryPay.
     */
    public function chargeSignature(
        string $merchantRefNum,
        string $paymentMethod,
        float $amount,
        ?string $customerProfileId = null,
    ): string {
        $amountFormatted = number_format($amount, 2, '.', '');
        $payload = FawrySetting::merchantCode()
            .$merchantRefNum
            .($customerProfileId ?? '')
            .$paymentMethod
            .$amountFormatted
            .FawrySetting::secureKey();

        return hash('sha256', $payload);
    }

    /**
     * توقيع استعلام حالة الدفع.
     */
    public function statusSignature(string $merchantRefNum): string
    {
        $payload = FawrySetting::merchantCode()
            .$merchantRefNum
            .FawrySetting::secureKey();

        return hash('sha256', $payload);
    }

    /**
     * بناء مرجع التاجر من رقم الطلب.
     */
    public function merchantRefForOrder(Order $order): string
    {
        $base = preg_replace('/[^A-Za-z0-9]/', '', (string) $order->order_number) ?: ('ORD'.$order->id);

        return substr($base, 0, 40);
    }

    /**
     * هل الطلب جاهز للبدء عبر فوري؟
     */
    public function canCharge(): bool
    {
        return FawrySetting::enabled() && FawrySetting::isConfigured();
    }

    /**
     * @return array<string, mixed>
     */
    public function chargeEndpoint(): array
    {
        return [
            'base_url' => FawrySetting::baseUrl(),
            'charge_path' => '/ECommerceWeb/Fawry/payments/charge',
            'status_path' => '/ECommerceWeb/Fawry/payments/status',
        ];
    }
}
