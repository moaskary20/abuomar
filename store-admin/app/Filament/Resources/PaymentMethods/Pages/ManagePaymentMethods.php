<?php

namespace App\Filament\Resources\PaymentMethods\Pages;

use App\Filament\Resources\PaymentMethods\PaymentMethodResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManagePaymentMethods extends ManageRecords
{
    protected static string $resource = PaymentMethodResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label('إضافة وسيلة دفع')
                ->mutateFormDataUsing(function (array $data): array {
                    $data['code'] = strtolower(trim((string) ($data['code'] ?? '')));
                    $data['is_active'] = array_key_exists('is_active', $data)
                        ? (bool) $data['is_active']
                        : true;
                    $data['is_default'] = (bool) ($data['is_default'] ?? false);
                    $data['requires_online'] = (bool) ($data['requires_online'] ?? false);

                    return $data;
                }),
        ];
    }
}
