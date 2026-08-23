<?php

namespace App\Filament\Pages;

use App\Models\LoyaltySetting;
use App\Models\StoreSetting;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
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
class ManageLoyaltySettings extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedGift;

    protected static string|UnitEnum|null $navigationGroup = 'التسويق';

    protected static ?int $navigationSort = 3;

    protected static ?string $navigationLabel = 'إعدادات الولاء';

    protected static ?string $title = 'إعدادات نقاط الولاء';

    protected string $view = 'filament.pages.manage-loyalty-settings';

    /**
     * @var array<string, mixed>|null
     */
    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill(LoyaltySetting::all());
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('تفعيل البرنامج')
                    ->description('تحكم في اكتساب واستبدال نقاط الولاء عند الشراء')
                    ->schema([
                        Toggle::make('loyalty_enabled')
                            ->label('تفعيل نظام نقاط الولاء')
                            ->helperText('عند الإيقاف لن تُحسب نقاط جديدة ولن يُسمح بالاستبدال')
                            ->inline(false),
                        Select::make('loyalty_earn_on')
                            ->label('منح النقاط عند')
                            ->options([
                                'paid' => 'دفع الطلب',
                                'delivered' => 'تسليم الطلب (مع الدفع)',
                            ])
                            ->required(),
                    ])
                    ->columns(2),

                Section::make('كسب النقاط')
                    ->schema([
                        TextInput::make('loyalty_points_per_currency')
                            ->label('نقاط لكل جنيه مصري')
                            ->numeric()
                            ->required()
                            ->helperText('مثال: 1 = نقطة واحدة لكل 1 ج.م من إجمالي الطلب'),
                        TextInput::make('loyalty_min_order_to_earn')
                            ->label('أقل مبلغ للطلب لكسب النقاط')
                            ->numeric()
                            ->prefix('ج.م')
                            ->required(),
                    ])
                    ->columns(2),

                Section::make('استبدال النقاط')
                    ->schema([
                        TextInput::make('loyalty_currency_per_point')
                            ->label('قيمة النقطة بالجنيه')
                            ->numeric()
                            ->required()
                            ->helperText('مثال: 0.1 = كل 10 نقاط تساوي 1 ج.م خصم'),
                        TextInput::make('loyalty_min_points_to_redeem')
                            ->label('الحد الأدنى للاستبدال')
                            ->numeric()
                            ->required()
                            ->suffix('نقطة'),
                        TextInput::make('loyalty_max_redeem_percent')
                            ->label('أقصى نسبة خصم من الطلب')
                            ->numeric()
                            ->required()
                            ->suffix('%')
                            ->helperText('لا يمكن استبدال نقاط بأكثر من هذه النسبة من المجموع الفرعي'),
                    ])
                    ->columns(3),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            StoreSetting::setValue(
                $key,
                is_bool($value) ? ($value ? '1' : '0') : (string) $value,
                'loyalty',
            );
        }

        Notification::make()
            ->title('تم حفظ إعدادات الولاء بنجاح')
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
