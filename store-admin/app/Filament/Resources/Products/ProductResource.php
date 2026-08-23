<?php

namespace App\Filament\Resources\Products;

use App\Filament\Resources\Products\Pages\CreateProduct;
use App\Filament\Resources\Products\Pages\EditProduct;
use App\Filament\Resources\Products\Pages\ListProducts;
use App\Filament\Resources\Products\Pages\ViewProduct;
use App\Models\Product;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use UnitEnum;

class ProductResource extends Resource
{
    protected static ?string $model = Product::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCube;

    protected static ?string $recordTitleAttribute = 'name';

    protected static string|UnitEnum|null $navigationGroup = 'المنتجات';

    protected static ?int $navigationSort = 3;

    protected static ?string $navigationLabel = 'المنتجات';

    protected static ?string $modelLabel = 'منتج';

    protected static ?string $pluralModelLabel = 'المنتجات';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('المعلومات الأساسية')
                    ->schema([
                        TextInput::make('name')
                            ->label('اسم المنتج')
                            ->required()
                            ->maxLength(255)
                            ->live(onBlur: true)
                            ->afterStateUpdated(fn ($state, callable $set) => $set('slug', str($state)->slug()->toString())),
                        TextInput::make('slug')
                            ->label('الرابط')
                            ->required()
                            ->unique(ignoreRecord: true),
                        TextInput::make('sku')
                            ->label('رمز المنتج (SKU)')
                            ->required()
                            ->unique(ignoreRecord: true),
                        TextInput::make('barcode')
                            ->label('الباركود')
                            ->unique(ignoreRecord: true)
                            ->nullable(),
                        Select::make('category_id')
                            ->label('التصنيف')
                            ->relationship('category', 'name')
                            ->searchable()
                            ->preload(),
                        TextInput::make('unit')
                            ->label('وحدة القياس')
                            ->default('قطعة')
                            ->required(),
                    ])
                    ->columns(2),

                Section::make('الوصف')
                    ->schema([
                        Textarea::make('short_description')
                            ->label('وصف مختصر')
                            ->rows(2)
                            ->columnSpanFull(),
                        Textarea::make('description')
                            ->label('الوصف التفصيلي')
                            ->rows(5)
                            ->columnSpanFull(),
                    ]),

                Section::make('الأسعار والمخزون')
                    ->schema([
                        TextInput::make('price')
                            ->label('سعر البيع')
                            ->required()
                            ->numeric()
                            ->prefix('ج.م'),
                        TextInput::make('compare_price')
                            ->label('السعر قبل الخصم')
                            ->numeric()
                            ->prefix('ج.م'),
                        TextInput::make('quantity')
                            ->label('الكمية المتوفرة')
                            ->numeric()
                            ->default(0)
                            ->required(),
                        TextInput::make('low_stock_threshold')
                            ->label('حد التنبيه للمخزون')
                            ->numeric()
                            ->default(5)
                            ->required(),
                        TextInput::make('weight')
                            ->label('الوزن (كجم)')
                            ->numeric(),
                        Toggle::make('track_quantity')
                            ->label('تتبع الكمية')
                            ->default(true),
                        Toggle::make('is_active')
                            ->label('منشور')
                            ->default(true),
                        Toggle::make('is_featured')
                            ->label('منتج مميز')
                            ->default(false),
                    ])
                    ->columns(3),

                Section::make('الصور')
                    ->schema([
                        FileUpload::make('image')
                            ->label('الصورة الرئيسية')
                            ->image()
                            ->directory('products')
                            ->disk('public')
                            ->imageEditor(),
                        FileUpload::make('gallery')
                            ->label('معرض الصور')
                            ->image()
                            ->multiple()
                            ->reorderable()
                            ->directory('products/gallery')
                            ->disk('public')
                            ->columnSpanFull(),
                    ])
                    ->columns(2),
            ]);
    }

    public static function infolist(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('تفاصيل المنتج')
                    ->schema([
                        ImageEntry::make('image')->label('الصورة')->disk('public'),
                        TextEntry::make('name')->label('الاسم'),
                        TextEntry::make('sku')->label('SKU'),
                        TextEntry::make('barcode')->label('الباركود')->placeholder('—'),
                        TextEntry::make('category.name')->label('التصنيف')->placeholder('—'),
                        TextEntry::make('price')->label('السعر')->money('EGP'),
                        TextEntry::make('quantity')->label('الكمية'),
                        TextEntry::make('unit')->label('الوحدة'),
                        IconEntry::make('is_active')->label('منشور')->boolean(),
                        IconEntry::make('is_featured')->label('مميز')->boolean(),
                        TextEntry::make('short_description')->label('وصف مختصر')->columnSpanFull(),
                        TextEntry::make('description')->label('الوصف')->columnSpanFull(),
                    ])
                    ->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                ImageColumn::make('image')->label('الصورة')->disk('public')->circular(false)->height(48),
                TextColumn::make('name')->label('المنتج')->searchable()->sortable()->limit(30),
                TextColumn::make('sku')->label('SKU')->searchable()->copyable(),
                TextColumn::make('category.name')->label('التصنيف')->toggleable(),
                TextColumn::make('price')->label('السعر')->money('EGP')->sortable(),
                TextColumn::make('quantity')
                    ->label('الكمية')
                    ->sortable()
                    ->color(fn (Product $record): string => $record->isLowStock() ? 'danger' : 'success')
                    ->badge(),
                IconColumn::make('is_active')->label('منشور')->boolean(),
                IconColumn::make('is_featured')->label('مميز')->boolean()->toggleable(),
                TextColumn::make('created_at')->label('أُضيف')->dateTime('Y-m-d')->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('category_id')->label('التصنيف')->relationship('category', 'name'),
                TernaryFilter::make('is_active')->label('منشور'),
                TernaryFilter::make('is_featured')->label('مميز'),
            ])
            ->recordActions([
                ViewAction::make()->label('عرض'),
                EditAction::make()->label('تعديل'),
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
            'index' => ListProducts::route('/'),
            'create' => CreateProduct::route('/create'),
            'view' => ViewProduct::route('/{record}'),
            'edit' => EditProduct::route('/{record}/edit'),
        ];
    }
}
