<?php

namespace App\Filament\Resources\StockMovements;

use App\Filament\Resources\StockMovements\Pages\CreateStockMovement;
use App\Filament\Resources\StockMovements\Pages\ListStockMovements;
use App\Models\StockMovement;
use BackedEnum;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use UnitEnum;

class StockMovementResource extends Resource
{
    protected static ?string $model = StockMovement::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedArchiveBox;

    protected static ?string $recordTitleAttribute = 'reference';

    protected static string|UnitEnum|null $navigationGroup = 'المخزون';

    protected static ?int $navigationSort = 1;

    protected static ?string $navigationLabel = 'حركات المخزون';

    protected static ?string $modelLabel = 'حركة مخزون';

    protected static ?string $pluralModelLabel = 'حركات المخزون';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('تسجيل حركة مخزون')
                    ->description('يتم تحديث كمية المنتج تلقائياً عند الحفظ')
                    ->schema([
                        Select::make('product_id')
                            ->label('المنتج')
                            ->relationship('product', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Select::make('type')
                            ->label('نوع الحركة')
                            ->options([
                                'in' => 'إضافة للمخزون',
                                'out' => 'صرف من المخزون',
                                'adjustment' => 'تعديل الكمية',
                            ])
                            ->required()
                            ->native(false),
                        TextInput::make('quantity')
                            ->label('الكمية')
                            ->numeric()
                            ->required()
                            ->minValue(1)
                            ->helperText('للتعديل: أدخل الكمية النهائية المطلوبة'),
                        TextInput::make('reference')
                            ->label('المرجع')
                            ->placeholder('مثال: فاتورة شراء #123'),
                        Textarea::make('notes')
                            ->label('ملاحظات')
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
            ]);
    }

    public static function infolist(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextEntry::make('product.name')->label('المنتج'),
                TextEntry::make('type')
                    ->label('النوع')
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'in' => 'إضافة',
                        'out' => 'صرف',
                        'adjustment' => 'تعديل',
                        default => $state,
                    }),
                TextEntry::make('quantity')->label('الكمية'),
                TextEntry::make('quantity_before')->label('قبل'),
                TextEntry::make('quantity_after')->label('بعد'),
                TextEntry::make('reference')->label('المرجع'),
                TextEntry::make('user.name')->label('بواسطة'),
                TextEntry::make('notes')->label('ملاحظات')->columnSpanFull(),
                TextEntry::make('created_at')->label('التاريخ')->dateTime(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('created_at')->label('التاريخ')->dateTime('Y-m-d H:i')->sortable(),
                TextColumn::make('product.name')->label('المنتج')->searchable(),
                TextColumn::make('type')
                    ->label('النوع')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'in' => 'إضافة',
                        'out' => 'صرف',
                        'adjustment' => 'تعديل',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'in' => 'success',
                        'out' => 'danger',
                        'adjustment' => 'warning',
                        default => 'gray',
                    }),
                TextColumn::make('quantity')->label('الكمية')->sortable(),
                TextColumn::make('quantity_before')->label('قبل'),
                TextColumn::make('quantity_after')->label('بعد'),
                TextColumn::make('reference')->label('المرجع')->toggleable(),
                TextColumn::make('user.name')->label('بواسطة')->toggleable(),
            ])
            ->filters([
                SelectFilter::make('type')->label('النوع')->options([
                    'in' => 'إضافة',
                    'out' => 'صرف',
                    'adjustment' => 'تعديل',
                ]),
            ])
            ->recordActions([
                ViewAction::make()->label('عرض'),
            ])
            ->toolbarActions([]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListStockMovements::route('/'),
            'create' => CreateStockMovement::route('/create'),
        ];
    }

    public static function canEdit($record): bool
    {
        return false;
    }

    public static function canDelete($record): bool
    {
        return false;
    }
}
