<?php

namespace App\Filament\Resources\Customers\RelationManagers;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class AddressesRelationManager extends RelationManager
{
    protected static string $relationship = 'addresses';

    protected static ?string $title = 'عناوين التوصيل';

    protected static ?string $modelLabel = 'عنوان';

    protected static ?string $pluralModelLabel = 'عناوين التوصيل';

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('بيانات العنوان')
                    ->schema([
                        TextInput::make('label')
                            ->label('التسمية')
                            ->placeholder('المنزل / العمل')
                            ->required()
                            ->maxLength(100)
                            ->default('المنزل'),
                        TextInput::make('recipient_name')
                            ->label('اسم المستلم')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('phone')
                            ->label('جوال التواصل')
                            ->tel()
                            ->maxLength(30),
                        TextInput::make('city')
                            ->label('المدينة')
                            ->required()
                            ->maxLength(100),
                        TextInput::make('area')
                            ->label('المنطقة / الحي')
                            ->maxLength(100),
                        TextInput::make('street')
                            ->label('الشارع')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('building')
                            ->label('المبنى')
                            ->maxLength(100),
                        TextInput::make('floor')
                            ->label('الدور')
                            ->maxLength(50),
                        TextInput::make('apartment')
                            ->label('الشقة')
                            ->maxLength(50),
                        Textarea::make('notes')
                            ->label('ملاحظات التوصيل')
                            ->rows(2)
                            ->columnSpanFull(),
                        Toggle::make('is_default')
                            ->label('العنوان الافتراضي')
                            ->default(false),
                    ])
                    ->columns(2),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('label')
            ->columns([
                TextColumn::make('label')->label('التسمية')->searchable(),
                TextColumn::make('recipient_name')->label('المستلم'),
                TextColumn::make('city')->label('المدينة'),
                TextColumn::make('street')->label('الشارع')->limit(24),
                TextColumn::make('phone')->label('الجوال')->toggleable(),
                IconColumn::make('is_default')->label('افتراضي')->boolean(),
            ])
            ->headerActions([
                CreateAction::make()->label('إضافة عنوان'),
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
}
