<?php

namespace App\Filament\Resources\Banners;

use App\Filament\Resources\Banners\Pages\CreateBanner;
use App\Filament\Resources\Banners\Pages\EditBanner;
use App\Filament\Resources\Banners\Pages\ListBanners;
use App\Models\Banner;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use UnitEnum;

class BannerResource extends Resource
{
    protected static ?string $model = Banner::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedPhoto;

    protected static ?string $recordTitleAttribute = 'title';

    protected static string|UnitEnum|null $navigationGroup = 'التسويق';

    protected static ?int $navigationSort = 1;

    protected static ?string $navigationLabel = 'سلايدر الرئيسية';

    protected static ?string $modelLabel = 'بانر';

    protected static ?string $pluralModelLabel = 'سلايدر الرئيسية';

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('محتوى البانر')
                    ->schema([
                        TextInput::make('title')
                            ->label('العنوان')
                            ->maxLength(255),
                        TextInput::make('subtitle')
                            ->label('النص الفرعي')
                            ->maxLength(255),
                        FileUpload::make('image')
                            ->label('صورة السلايدر')
                            ->image()
                            ->required()
                            ->directory('banners')
                            ->disk('public')
                            ->imageEditor()
                            ->columnSpanFull(),
                        TextInput::make('sort_order')
                            ->label('ترتيب العرض')
                            ->numeric()
                            ->default(0)
                            ->required(),
                        Toggle::make('is_active')
                            ->label('نشط')
                            ->default(true),
                    ])
                    ->columns(2),
                Section::make('الربط والجدولة')
                    ->schema([
                        Select::make('link_type')
                            ->label('نوع الرابط')
                            ->options([
                                'none' => 'بدون رابط',
                                'category' => 'تصنيف',
                                'product' => 'منتج',
                                'url' => 'رابط خارجي',
                            ])
                            ->default('none')
                            ->required()
                            ->live(),
                        TextInput::make('link_value')
                            ->label('قيمة الرابط')
                            ->helperText('معرّف التصنيف/المنتج أو رابط URL')
                            ->maxLength(255)
                            ->visible(fn (callable $get): bool => ($get('link_type') ?? 'none') !== 'none'),
                        DateTimePicker::make('starts_at')
                            ->label('يبدأ من')
                            ->nullable(),
                        DateTimePicker::make('ends_at')
                            ->label('ينتهي في')
                            ->nullable(),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                ImageColumn::make('image')
                    ->label('الصورة')
                    ->disk('public')
                    ->circular(false)
                    ->height(48),
                TextColumn::make('title')
                    ->label('العنوان')
                    ->searchable()
                    ->placeholder('—'),
                TextColumn::make('link_type')
                    ->label('الرابط')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'category' => 'تصنيف',
                        'product' => 'منتج',
                        'url' => 'رابط',
                        default => 'بدون',
                    }),
                TextColumn::make('sort_order')
                    ->label('الترتيب')
                    ->sortable(),
                IconColumn::make('is_active')
                    ->label('نشط')
                    ->boolean(),
                TextColumn::make('updated_at')
                    ->label('آخر تحديث')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
            ])
            ->defaultSort('sort_order')
            ->filters([
                TernaryFilter::make('is_active')->label('نشط'),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListBanners::route('/'),
            'create' => CreateBanner::route('/create'),
            'edit' => EditBanner::route('/{record}/edit'),
        ];
    }
}
