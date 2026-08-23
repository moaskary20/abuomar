<?php

namespace App\Filament\Resources\PaymentMethods;

use App\Filament\Resources\PaymentMethods\Pages\ManagePaymentMethods;
use App\Models\PaymentMethod;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Textarea;
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

class PaymentMethodResource extends Resource
{
    protected static ?string $model = PaymentMethod::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCreditCard;

    protected static ?string $recordTitleAttribute = 'name';

    protected static string|UnitEnum|null $navigationGroup = 'الإعدادات';

    protected static ?int $navigationSort = 2;

    protected static ?string $navigationLabel = 'وسائل الدفع';

    protected static ?string $modelLabel = 'وسيلة دفع';

    protected static ?string $pluralModelLabel = 'وسائل الدفع';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('بيانات وسيلة الدفع')
                    ->schema([
                        TextInput::make('name')
                            ->label('الاسم')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('code')
                            ->label('الكود')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->helperText('مثال: cod, card, transfer, wallet')
                            ->maxLength(50),
                        TextInput::make('icon')
                            ->label('أيقونة')
                            ->placeholder('payments / credit_card / account_balance')
                            ->maxLength(50),
                        TextInput::make('sort_order')
                            ->label('الترتيب')
                            ->numeric()
                            ->default(0)
                            ->required(),
                        Toggle::make('is_active')
                            ->label('نشط في التطبيق')
                            ->default(true),
                        Toggle::make('is_default')
                            ->label('الافتراضية')
                            ->helperText('تُختار تلقائياً في صفحة الدفع')
                            ->default(false),
                        Toggle::make('requires_online')
                            ->label('تتطلب دفعاً إلكترونياً')
                            ->default(false),
                        Textarea::make('description')
                            ->label('الوصف')
                            ->rows(3)
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('sort_order')
            ->columns([
                TextColumn::make('name')->label('الاسم')->searchable(),
                TextColumn::make('code')->label('الكود')->badge()->copyable(),
                TextColumn::make('sort_order')->label('الترتيب')->sortable(),
                IconColumn::make('is_default')->label('افتراضي')->boolean(),
                IconColumn::make('is_active')->label('نشط')->boolean(),
                IconColumn::make('requires_online')->label('إلكتروني')->boolean()->toggleable(),
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
            'index' => ManagePaymentMethods::route('/'),
        ];
    }
}
