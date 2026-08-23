<?php

namespace App\Filament\Resources\LoyaltyTransactions;

use App\Filament\Resources\LoyaltyTransactions\Pages\ManageLoyaltyTransactions;
use App\Models\LoyaltyTransaction;
use BackedEnum;
use Filament\Actions\ViewAction;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use UnitEnum;

class LoyaltyTransactionResource extends Resource
{
    protected static ?string $model = LoyaltyTransaction::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedStar;

    protected static string|UnitEnum|null $navigationGroup = 'التسويق';

    protected static ?int $navigationSort = 2;

    protected static ?string $navigationLabel = 'سجل نقاط الولاء';

    protected static ?string $modelLabel = 'حركة نقاط';

    protected static ?string $pluralModelLabel = 'سجل نقاط الولاء';

    public static function canCreate(): bool
    {
        return false;
    }

    public static function infolist(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('تفاصيل الحركة')
                    ->schema([
                        TextEntry::make('customer.name')->label('العميل'),
                        TextEntry::make('type')
                            ->label('النوع')
                            ->formatStateUsing(fn (string $state): string => LoyaltyTransaction::typeLabel($state)),
                        TextEntry::make('points')->label('النقاط'),
                        TextEntry::make('balance_after')->label('الرصيد بعد العملية'),
                        TextEntry::make('order.order_number')->label('الطلب')->placeholder('—'),
                        TextEntry::make('user.name')->label('بواسطة')->placeholder('النظام'),
                        TextEntry::make('description')->label('الوصف')->columnSpanFull(),
                        TextEntry::make('created_at')->label('التاريخ')->dateTime('Y-m-d H:i'),
                    ])
                    ->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('created_at')->label('التاريخ')->dateTime('Y-m-d H:i')->sortable(),
                TextColumn::make('customer.name')->label('العميل')->searchable()->sortable(),
                TextColumn::make('type')
                    ->label('النوع')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'earn' => 'success',
                        'redeem' => 'warning',
                        'adjust' => 'info',
                        'refund' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => LoyaltyTransaction::typeLabel($state)),
                TextColumn::make('points')
                    ->label('النقاط')
                    ->sortable()
                    ->color(fn (int $state): string => $state >= 0 ? 'success' : 'danger')
                    ->formatStateUsing(fn (int $state): string => ($state > 0 ? '+' : '').$state),
                TextColumn::make('balance_after')->label('الرصيد')->sortable(),
                TextColumn::make('order.order_number')->label('الطلب')->placeholder('—')->toggleable(),
                TextColumn::make('description')->label('الوصف')->limit(40)->wrap(),
            ])
            ->filters([
                SelectFilter::make('type')
                    ->label('النوع')
                    ->options([
                        'earn' => 'كسب',
                        'redeem' => 'استبدال',
                        'adjust' => 'تعديل يدوي',
                        'refund' => 'استرجاع',
                    ]),
                SelectFilter::make('customer_id')
                    ->label('العميل')
                    ->relationship('customer', 'name')
                    ->searchable()
                    ->preload(),
            ])
            ->recordActions([
                ViewAction::make()->label('عرض'),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ManageLoyaltyTransactions::route('/'),
        ];
    }
}
