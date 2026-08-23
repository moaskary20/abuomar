<?php

namespace App\Filament\Resources\Coupons;

use App\Filament\Resources\Coupons\Pages\ManageCoupons;
use App\Models\Coupon;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use UnitEnum;

class CouponResource extends Resource
{
    protected static ?string $model = Coupon::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedTicket;

    protected static ?string $recordTitleAttribute = 'code';

    protected static string|UnitEnum|null $navigationGroup = 'التسويق';

    protected static ?int $navigationSort = 1;

    protected static ?string $navigationLabel = 'الكوبونات';

    protected static ?string $modelLabel = 'كوبون';

    protected static ?string $pluralModelLabel = 'الكوبونات';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make()
                    ->schema([
                        TextInput::make('code')->label('كود الخصم')->required()->unique(ignoreRecord: true)->extraInputAttributes(['style' => 'text-transform:uppercase']),
                        TextInput::make('name')->label('اسم العرض')->required(),
                        Select::make('type')
                            ->label('نوع الخصم')
                            ->options([
                                'percentage' => 'نسبة مئوية',
                                'fixed' => 'مبلغ ثابت',
                            ])
                            ->default('percentage')
                            ->required(),
                        TextInput::make('value')->label('قيمة الخصم')->numeric()->required(),
                        TextInput::make('min_order_amount')->label('أقل مبلغ للطلب')->numeric()->prefix('ج.م'),
                        TextInput::make('max_discount')->label('أقصى خصم')->numeric()->prefix('ج.م'),
                        TextInput::make('usage_limit')->label('حد الاستخدام')->numeric(),
                        TextInput::make('used_count')->label('مرات الاستخدام')->numeric()->default(0)->disabled()->dehydrated(),
                        DateTimePicker::make('starts_at')->label('يبدأ من'),
                        DateTimePicker::make('expires_at')->label('ينتهي في'),
                        Toggle::make('is_active')->label('نشط')->default(true),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('code')->label('الكود')->searchable()->copyable()->badge(),
                TextColumn::make('name')->label('العرض')->searchable(),
                TextColumn::make('type')
                    ->label('النوع')
                    ->formatStateUsing(fn (string $state): string => $state === 'percentage' ? 'نسبة' : 'ثابت'),
                TextColumn::make('value')->label('القيمة')->sortable(),
                TextColumn::make('used_count')->label('مستخدم')->sortable(),
                TextColumn::make('usage_limit')->label('الحد')->placeholder('∞'),
                TextColumn::make('expires_at')->label('الانتهاء')->dateTime('Y-m-d')->placeholder('—'),
                IconColumn::make('is_active')->label('نشط')->boolean(),
            ])
            ->recordActions([
                EditAction::make()->label('تعديل'),
                DeleteAction::make()->label('حذف'),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make()->label('حذف المحدد'),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ManageCoupons::route('/'),
        ];
    }
}
