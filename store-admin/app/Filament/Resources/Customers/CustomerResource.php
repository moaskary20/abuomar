<?php

namespace App\Filament\Resources\Customers;

use App\Filament\Resources\Customers\Pages\CreateCustomer;
use App\Filament\Resources\Customers\Pages\EditCustomer;
use App\Filament\Resources\Customers\Pages\ListCustomers;
use App\Models\Customer;
use App\Services\LoyaltyService;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use UnitEnum;

class CustomerResource extends Resource
{
    protected static ?string $model = Customer::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUsers;

    protected static ?string $recordTitleAttribute = 'name';

    protected static string|UnitEnum|null $navigationGroup = 'المبيعات';

    protected static ?int $navigationSort = 1;

    protected static ?string $navigationLabel = 'العملاء';

    protected static ?string $modelLabel = 'عميل';

    protected static ?string $pluralModelLabel = 'العملاء';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('بيانات العميل')
                    ->schema([
                        TextInput::make('name')->label('الاسم')->required()->maxLength(255),
                        TextInput::make('email')->label('البريد الإلكتروني')->email()->unique(ignoreRecord: true),
                        TextInput::make('phone')->label('الجوال')->tel(),
                        TextInput::make('password')
                            ->label('كلمة مرور التطبيق')
                            ->password()
                            ->revealable()
                            ->dehydrated(fn (?string $state): bool => filled($state))
                            ->required(fn (string $operation): bool => $operation === 'create')
                            ->helperText('تُستخدم لتسجيل الدخول من تطبيق الموبايل'),
                        TextInput::make('city')->label('المدينة'),
                        Textarea::make('address')->label('العنوان')->columnSpanFull(),
                        Textarea::make('notes')->label('ملاحظات')->columnSpanFull(),
                        Toggle::make('is_active')->label('نشط')->default(true),
                    ])
                    ->columns(2),

                Section::make('نقاط الولاء')
                    ->schema([
                        TextInput::make('loyalty_points')
                            ->label('الرصيد الحالي')
                            ->numeric()
                            ->disabled()
                            ->dehydrated(false)
                            ->default(0),
                        TextInput::make('loyalty_points_earned')
                            ->label('إجمالي المكتسب')
                            ->numeric()
                            ->disabled()
                            ->dehydrated(false)
                            ->default(0),
                        TextInput::make('loyalty_points_redeemed')
                            ->label('إجمالي المستبدل')
                            ->numeric()
                            ->disabled()
                            ->dehydrated(false)
                            ->default(0),
                    ])
                    ->columns(3)
                    ->visibleOn('edit'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->label('الاسم')->searchable()->sortable(),
                TextColumn::make('phone')->label('الجوال')->searchable(),
                TextColumn::make('email')->label('البريد')->searchable()->toggleable(),
                TextColumn::make('city')->label('المدينة')->toggleable(),
                TextColumn::make('loyalty_points')->label('النقاط')->sortable()->badge()->color('success'),
                TextColumn::make('orders_count')->counts('orders')->label('الطلبات'),
                IconColumn::make('is_active')->label('نشط')->boolean(),
                TextColumn::make('created_at')->label('التسجيل')->dateTime('Y-m-d')->sortable(),
            ])
            ->filters([
                TernaryFilter::make('is_active')->label('الحالة'),
            ])
            ->recordActions([
                Action::make('adjustPoints')
                    ->label('تعديل النقاط')
                    ->icon(Heroicon::OutlinedAdjustmentsHorizontal)
                    ->color('warning')
                    ->form([
                        TextInput::make('points')
                            ->label('النقاط (+ إضافة / - خصم)')
                            ->numeric()
                            ->required()
                            ->helperText('أدخل رقماً موجباً للإضافة أو سالباً للخصم'),
                        Textarea::make('description')
                            ->label('السبب')
                            ->required()
                            ->rows(2),
                    ])
                    ->action(function (Customer $record, array $data, LoyaltyService $loyalty): void {
                        try {
                            $loyalty->adjust(
                                $record,
                                (int) $data['points'],
                                $data['description'],
                                auth()->user(),
                            );

                            Notification::make()
                                ->title('تم تحديث نقاط الولاء')
                                ->success()
                                ->send();
                        } catch (\Throwable $e) {
                            Notification::make()
                                ->title('تعذر تعديل النقاط')
                                ->body($e->getMessage())
                                ->danger()
                                ->send();
                        }
                    }),
                EditAction::make()->label('تعديل'),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make()->label('حذف المحدد'),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            RelationManagers\AddressesRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListCustomers::route('/'),
            'create' => CreateCustomer::route('/create'),
            'edit' => EditCustomer::route('/{record}/edit'),
        ];
    }
}
