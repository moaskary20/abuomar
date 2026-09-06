<?php

namespace App\Filament\Pages;

use App\Models\FawrySetting;
use App\Models\StoreSetting;
use App\Services\FawryService;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\CheckboxList;
use Filament\Forms\Components\Select;
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
            'app_active' => StoreSetting::isAppActive(),
            'app_inactive_message' => StoreSetting::appInactiveMessage(),
            'currency' => StoreSetting::getValue('currency', 'EGP'),
            'tax_rate' => StoreSetting::getValue('tax_rate', '15'),
            'low_stock_alert' => (bool) StoreSetting::getValue('low_stock_alert', true),
            'order_prefix' => StoreSetting::getValue('order_prefix', 'ORD'),
            ...FawrySetting::all(),
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

                Section::make('حالة التطبيق والطلبات')
                    ->description('عند إيقاف التطبيق لن يتمكن العملاء من إتمام أي طلب من التطبيق')
                    ->schema([
                        Toggle::make('app_active')
                            ->label('التطبيق نشط (يستقبل الطلبات)')
                            ->helperText('عطّله لإيقاف الطلبات مؤقتاً مع إظهار رسالة للعميل')
                            ->inline(false)
                            ->live(),
                        Textarea::make('app_inactive_message')
                            ->label('رسالة إيقاف الطلبات')
                            ->rows(3)
                            ->required()
                            ->helperText('تظهر للعميل عند محاولة إتمام طلب والتطبيق غير نشط')
                            ->columnSpanFull(),
                    ])
                    ->columns(1),

                Section::make('إعدادات البيع')
                    ->schema([
                        TextInput::make('currency')->label('العملة')->required(),
                        TextInput::make('tax_rate')->label('نسبة الضريبة %')->numeric()->suffix('%'),
                        TextInput::make('order_prefix')->label('بادئة رقم الطلب'),
                        Toggle::make('low_stock_alert')->label('تنبيه نقص المخزون')->inline(false),
                    ])
                    ->columns(2),

                Section::make('بوابة الدفع فوري (FawryPay)')
                    ->description('ربط المتجر ببوابة فوري — تظهر كوسيلة دفع في التطبيق عند التفعيل وإدخال البيانات')
                    ->schema([
                        Toggle::make('fawry_enabled')
                            ->label('تفعيل بوابة فوري')
                            ->helperText('عند التفعيل تُضاف/تُفعَّل وسيلة الدفع «فوري» تلقائياً في وسائل الدفع')
                            ->inline(false)
                            ->live(),
                        Select::make('fawry_mode')
                            ->label('وضع التشغيل')
                            ->options([
                                'sandbox' => 'تجريبي (Sandbox / Staging)',
                                'live' => 'مباشر (Production)',
                            ])
                            ->required()
                            ->native(false),
                        TextInput::make('fawry_display_name')
                            ->label('الاسم في التطبيق')
                            ->required()
                            ->maxLength(100),
                        Textarea::make('fawry_description')
                            ->label('وصف وسيلة الدفع')
                            ->rows(2)
                            ->columnSpanFull(),
                    ])
                    ->columns(2)
                    ->collapsed(false),

                Section::make('بيانات تاجر فوري')
                    ->description('من لوحة تاجر FawryPay — لا تشارك المفتاح السري')
                    ->schema([
                        TextInput::make('fawry_merchant_code')
                            ->label('Merchant Code')
                            ->required(fn (callable $get): bool => (bool) $get('fawry_enabled'))
                            ->password(false)
                            ->maxLength(255)
                            ->helperText('كود التاجر الصادر من فوري'),
                        TextInput::make('fawry_secure_key')
                            ->label('Secure Key / Security Key')
                            ->password()
                            ->revealable()
                            ->required(fn (callable $get): bool => (bool) $get('fawry_enabled'))
                            ->maxLength(255)
                            ->helperText('المفتاح السري للتوقيع SHA-256 — يُحفظ على السيرفر فقط'),
                        Select::make('fawry_language')
                            ->label('لغة صفحة الدفع')
                            ->options([
                                'ar-eg' => 'العربية (ar-eg)',
                                'en-gb' => 'English (en-gb)',
                            ])
                            ->required()
                            ->native(false),
                        TextInput::make('fawry_currency')
                            ->label('عملة فوري')
                            ->default('EGP')
                            ->required()
                            ->maxLength(10)
                            ->helperText('فوري تدعم EGP'),
                        CheckboxList::make('fawry_channels')
                            ->label('قنوات الدفع داخل فوري')
                            ->options([
                                'PayAtFawry' => 'الدفع بكود فوري (PayAtFawry)',
                                'CARD' => 'بطاقة بنكية (CARD)',
                                'MWALLET' => 'محفظة إلكترونية (MWALLET)',
                            ])
                            ->columns(3)
                            ->required(fn (callable $get): bool => (bool) $get('fawry_enabled'))
                            ->columnSpanFull(),
                        Toggle::make('fawry_enable_3ds')
                            ->label('تفعيل 3D Secure للبطاقات')
                            ->inline(false)
                            ->default(true),
                    ])
                    ->columns(2),

                Section::make('روابط العودة والإشعارات')
                    ->schema([
                        TextInput::make('fawry_return_url')
                            ->label('Return URL')
                            ->url()
                            ->maxLength(500)
                            ->helperText('رابط رجوع العميل بعد الدفع (مثلاً صفحة نجاح الطلب على الموقع/التطبيق)'),
                        TextInput::make('fawry_webhook_url')
                            ->label('Webhook / Callback URL')
                            ->url()
                            ->maxLength(500)
                            ->helperText('رابط إشعار السيرفر بنتيجة الدفع من فوري (orderWebHookUrl)'),
                        TextInput::make('fawry_staging_base_url')
                            ->label('رابط بيئة التجربة')
                            ->url()
                            ->required()
                            ->default('https://atfawry.fawrystaging.com'),
                        TextInput::make('fawry_live_base_url')
                            ->label('رابط بيئة الإنتاج')
                            ->url()
                            ->required()
                            ->default('https://www.atfawry.com'),
                        Textarea::make('fawry_customer_instructions')
                            ->label('تعليمات للعميل بعد الطلب')
                            ->rows(3)
                            ->columnSpanFull()
                            ->helperText('تظهر في التطبيق عند اختيار فوري'),
                    ])
                    ->columns(2),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        $generalKeys = ['store_name', 'store_email', 'store_phone', 'store_address', 'app_active', 'app_inactive_message'];
        $salesKeys = ['currency', 'tax_rate', 'order_prefix', 'low_stock_alert'];

        foreach ($data as $key => $value) {
            if (str_starts_with($key, 'fawry_')) {
                $group = 'fawry';
                if ($key === 'fawry_channels' && is_array($value)) {
                    $value = implode(',', $value);
                }
            } elseif (in_array($key, $salesKeys, true)) {
                $group = 'sales';
            } elseif (in_array($key, $generalKeys, true)) {
                $group = 'general';
            } else {
                $group = 'general';
            }

            StoreSetting::setValue(
                $key,
                is_bool($value) ? ($value ? '1' : '0') : (string) ($value ?? ''),
                $group,
            );
        }

        $method = app(FawryService::class)->syncPaymentMethod();

        $message = 'تم حفظ إعدادات المتجر بنجاح';
        if (FawrySetting::enabled()) {
            $message .= FawrySetting::isConfigured()
                ? ' — تم تفعيل وسيلة الدفع فوري في التطبيق'
                : ' — فوري مفعّل لكن أدخل Merchant Code و Secure Key لاكتمال الربط';
        } else {
            $message .= ' — وسيلة فوري غير نشطة في التطبيق';
        }

        Notification::make()
            ->title($message)
            ->body('كود الوسيلة: '.$method->code.' | الحالة: '.($method->is_active ? 'نشطة' : 'متوقفة'))
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
