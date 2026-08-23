<?php

namespace App\Filament\Resources\Reviews;

use App\Filament\Resources\Reviews\Pages\ManageReviews;
use App\Models\Review;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use UnitEnum;

class ReviewResource extends Resource
{
    protected static ?string $model = Review::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedStar;

    protected static ?string $recordTitleAttribute = 'title';

    protected static string|UnitEnum|null $navigationGroup = 'التسويق';

    protected static ?int $navigationSort = 2;

    protected static ?string $navigationLabel = 'التقييمات';

    protected static ?string $modelLabel = 'تقييم';

    protected static ?string $pluralModelLabel = 'التقييمات';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make()
                    ->schema([
                        Select::make('product_id')
                            ->label('المنتج')
                            ->relationship('product', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Select::make('customer_id')
                            ->label('العميل')
                            ->relationship('customer', 'name')
                            ->searchable()
                            ->preload(),
                        TextInput::make('customer_name')->label('اسم المقيّم')->required(),
                        Select::make('rating')
                            ->label('التقييم')
                            ->options([
                                1 => '★☆☆☆☆',
                                2 => '★★☆☆☆',
                                3 => '★★★☆☆',
                                4 => '★★★★☆',
                                5 => '★★★★★',
                            ])
                            ->required(),
                        TextInput::make('title')->label('العنوان'),
                        Textarea::make('comment')->label('التعليق')->columnSpanFull(),
                        Toggle::make('is_approved')->label('موافق عليه')->default(false),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('product.name')->label('المنتج')->searchable()->limit(25),
                TextColumn::make('customer_name')->label('المقيّم')->searchable(),
                TextColumn::make('rating')->label('التقييم')->badge()->color('warning'),
                TextColumn::make('title')->label('العنوان')->limit(30)->toggleable(),
                IconColumn::make('is_approved')->label('موافقة')->boolean(),
                TextColumn::make('created_at')->label('التاريخ')->dateTime('Y-m-d'),
            ])
            ->filters([
                TernaryFilter::make('is_approved')->label('الموافقة'),
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
            'index' => ManageReviews::route('/'),
        ];
    }
}
