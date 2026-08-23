<?php

namespace App\Filament\Pages;

use App\Models\StoreSetting;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Components\Actions;
use Filament\Schemas\Components\Component;
use Filament\Schemas\Components\EmbeddedSchema;
use Filament\Schemas\Components\Form;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use UnitEnum;

/**
 * @property-read Schema $form
 */
class ManageStoreSettings extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCog6Tooth;

    protected static string|UnitEnum|null $navigationGroup = 'الإعدادات';

    protected static ?int $navigationSort = 2;

    protected static ?string $navigationLabel = 'إعدادات المتجر';

    protected static ?string $title = 'إعدادات المتجر';

    protected string $view = 'filament.pages.manage-store-settings';

    /**
     * @var array<string, mixed>|null
     */
    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'store_name' => StoreSetting::getValue('store_name', 'متجري'),
            'store_email' => StoreSetting::getValue('store_email'),
            'store_phone' => StoreSetting::getValue('store_phone'),
            'store_address' => StoreSetting::getValue('store_address'),
            'currency' => StoreSetting::getValue('currency', 'EGP'),
            'tax_rate' => StoreSetting::getValue('tax_rate', '15'),
            'low_stock_alert' => (bool) StoreSetting::getValue('low_stock_alert', true),
            'order_prefix' => StoreSetting::getValue('order_prefix', 'ORD'),
        ]);
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('معلومات المتجر')
                    ->schema([
                        TextInput::make('store_name')->label('اسم المتجر')->required(),
                        TextInput::make('store_email')->label('البريد الإلكتروني')->email(),
                        TextInput::make('store_phone')->label('رقم الجوال')->tel(),
                        Textarea::make('store_address')->label('عنوان المتجر')->columnSpanFull(),
                    ])
                    ->columns(2),
                Section::make('إعدادات البيع')
                    ->schema([
                        TextInput::make('currency')->label('العملة')->required(),
                        TextInput::make('tax_rate')->label('نسبة الضريبة %')->numeric()->suffix('%'),
                        TextInput::make('order_prefix')->label('بادئة رقم الطلب'),
                        Toggle::make('low_stock_alert')->label('تنبيه نقص المخزون')->inline(false),
                    ])
                    ->columns(2),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            $group = in_array($key, ['currency', 'tax_rate', 'order_prefix', 'low_stock_alert'], true)
                ? 'sales'
                : 'general';

            StoreSetting::setValue($key, is_bool($value) ? ($value ? '1' : '0') : $value, $group);
        }

        Notification::make()
            ->title('تم حفظ إعدادات المتجر بنجاح')
            ->success()
            ->send();
    }

    public function content(Schema $schema): Schema
    {
        return $schema
            ->components([
                $this->getFormContentComponent(),
            ]);
    }

    public function getFormContentComponent(): Component
    {
        return Form::make([EmbeddedSchema::make('form')])
            ->id('form')
            ->livewireSubmitHandler('save')
            ->footer([
                Actions::make([
                    Action::make('save')
                        ->label('حفظ الإعدادات')
                        ->submit('save'),
                ]),
            ]);
    }
}
