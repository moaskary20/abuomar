<?php

namespace App\Filament\Resources\Orders;

use App\Filament\Resources\Orders\Pages\CreateOrder;
use App\Filament\Resources\Orders\Pages\EditOrder;
use App\Filament\Resources\Orders\Pages\ListOrders;
use App\Filament\Resources\Orders\Pages\ViewOrder;
use App\Models\Order;
use App\Models\Product;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Repeater;
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

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedShoppingBag;

    protected static ?string $recordTitleAttribute = 'order_number';

    protected static string|UnitEnum|null $navigationGroup = 'المبيعات';

    protected static ?int $navigationSort = 2;

    protected static ?string $navigationLabel = 'الطلبات';

    protected static ?string $modelLabel = 'طلب';

    protected static ?string $pluralModelLabel = 'الطلبات';

    public static function getNavigationBadge(): ?string
    {
        $count = Order::unviewedCount();

        return $count > 0 ? (string) $count : null;
    }

    public static function getNavigationBadgeColor(): string|array|null
    {
        return Order::unviewedCount() > 0 ? 'danger' : null;
    }

    public static function getNavigationBadgeTooltip(): string|\Illuminate\Contracts\Support\Htmlable|null
    {
        $count = Order::unviewedCount();

        return $count > 0
            ? "{$count} طلب جديد لم يُفتح"
            : null;
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('بيانات الطلب')
                    ->schema([
                        TextInput::make('order_number')
                            ->label('رقم الطلب')
                            ->disabled()
                            ->dehydrated(false)
                            ->placeholder('يُنشأ تلقائياً')
                            ->visibleOn('edit'),
                        Select::make('customer_id')
                            ->label('العميل')
                            ->relationship('customer', 'name')
                            ->searchable()
                            ->preload()
                            ->live()
                            ->afterStateUpdated(function ($state, callable $set): void {
                                if (! $state) {
                                    return;
                                }

                                $customer = \App\Models\Customer::find($state);
                                if ($customer) {
                                    $set('customer_name', $customer->name);
                                    $set('customer_phone', $customer->phone);
                                    $set('customer_email', $customer->email);
                                    $set('shipping_city', $customer->city);
                                    $set('shipping_address', $customer->address);
                                }
                            }),
                        Select::make('status')
                            ->label('حالة الطلب')
                            ->options([
                                'pending' => 'قيد الانتظار',
                                'confirmed' => 'مؤكد',
                                'processing' => 'قيد التجهيز',
                                'shipped' => 'تم الشحن',
                                'delivered' => 'تم التسليم',
                                'cancelled' => 'ملغي',
                            ])
                            ->default('pending')
                            ->required(),
                        Select::make('payment_status')
                            ->label('حالة الدفع')
                            ->options([
                                'unpaid' => 'غير مدفوع',
                                'paid' => 'مدفوع',
                                'partial' => 'مدفوع جزئياً',
                                'refunded' => 'مسترجع',
                            ])
                            ->default('unpaid')
                            ->required(),
                        Select::make('payment_method')
                            ->label('طريقة الدفع')
                            ->options(fn (): array => \App\Models\PaymentMethod::query()
                                ->ordered()
                                ->pluck('name', 'code')
                                ->all() ?: [
                                    'cod' => 'الدفع عند الاستلام',
                                    'card' => 'بطاقة',
                                    'transfer' => 'تحويل بنكي',
                                    'wallet' => 'محفظة إلكترونية',
                                ]),
                        Select::make('shipping_method_id')
                            ->label('طريقة الشحن')
                            ->relationship('shippingMethod', 'name')
                            ->searchable()
                            ->preload()
                            ->live()
                            ->afterStateUpdated(function ($state, callable $set): void {
                                if (! $state) {
                                    return;
                                }
                                $method = \App\Models\ShippingMethod::find($state);
                                if ($method) {
                                    $set('shipping_amount', $method->price);
                                }
                            }),
                        Select::make('coupon_id')
                            ->label('كوبون الخصم')
                            ->relationship('coupon', 'code')
                            ->searchable()
                            ->preload(),
                        TextInput::make('points_to_redeem')
                            ->label('نقاط للاستبدال')
                            ->numeric()
                            ->default(0)
                            ->minValue(0)
                            ->helperText('تُخصم من رصيد العميل عند معالجة الولاء (بعد الدفع/التسليم حسب الإعدادات)')
                            ->live(onBlur: true)
                            ->afterStateUpdated(function ($state, callable $set): void {
                                $points = max(0, (int) $state);
                                $rate = (float) \App\Models\LoyaltySetting::currencyPerPoint();
                                $set('points_discount_amount', round($points * $rate, 2));
                            }),
                    ])
                    ->columns(2),

                Section::make('بيانات المستلم')
                    ->schema([
                        TextInput::make('customer_name')->label('اسم المستلم')->required(),
                        TextInput::make('customer_phone')->label('جوال المستلم')->tel(),
                        TextInput::make('customer_email')->label('بريد المستلم')->email(),
                        TextInput::make('shipping_city')->label('المدينة'),
                        Textarea::make('shipping_address')->label('عنوان الشحن')->columnSpanFull(),
                        Textarea::make('notes')->label('ملاحظات')->columnSpanFull(),
                    ])
                    ->columns(2),

                Section::make('منتجات الطلب')
                    ->schema([
                        Repeater::make('items')
                            ->label('العناصر')
                            ->relationship()
                            ->schema([
                                Select::make('product_id')
                                    ->label('المنتج')
                                    ->relationship('product', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(function ($state, callable $set): void {
                                        $product = Product::find($state);
                                        if ($product) {
                                            $set('product_name', $product->name);
                                            $set('product_sku', $product->sku);
                                            $set('unit_price', $product->price);
                                        }
                                    }),
                                TextInput::make('product_name')->label('اسم المنتج')->required(),
                                TextInput::make('product_sku')->label('SKU'),
                                TextInput::make('quantity')
                                    ->label('الكمية')
                                    ->numeric()
                                    ->default(1)
                                    ->required()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(function ($state, callable $get, callable $set): void {
                                        $set('total', (float) $get('unit_price') * (int) $state);
                                    }),
                                TextInput::make('unit_price')
                                    ->label('سعر الوحدة')
                                    ->numeric()
                                    ->prefix('ج.م')
                                    ->required()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(function ($state, callable $get, callable $set): void {
                                        $set('total', (float) $state * (int) $get('quantity'));
                                    }),
                                TextInput::make('total')
                                    ->label('الإجمالي')
                                    ->numeric()
                                    ->prefix('ج.م')
                                    ->required(),
                            ])
                            ->columns(3)
                            ->defaultItems(1)
                            ->collapsible()
                            ->columnSpanFull(),
                    ]),

                Section::make('المبالغ')
                    ->schema([
                        TextInput::make('subtotal')->label('المجموع الفرعي')->numeric()->prefix('ج.م')->default(0),
                        TextInput::make('discount_amount')->label('الخصم')->numeric()->prefix('ج.م')->default(0),
                        TextInput::make('points_discount_amount')
                            ->label('خصم النقاط')
                            ->numeric()
                            ->prefix('ج.م')
                            ->default(0)
                            ->disabled()
                            ->dehydrated(),
                        TextInput::make('shipping_amount')->label('الشحن')->numeric()->prefix('ج.م')->default(0),
                        TextInput::make('tax_amount')->label('الضريبة')->numeric()->prefix('ج.م')->default(0),
                        TextInput::make('total')->label('الإجمالي النهائي')->numeric()->prefix('ج.م')->default(0)->required(),
                        TextInput::make('points_earned')->label('النقاط المكتسبة')->numeric()->disabled()->dehydrated(false)->visibleOn('edit'),
                        TextInput::make('points_redeemed')->label('النقاط المستبدلة')->numeric()->disabled()->dehydrated(false)->visibleOn('edit'),
                        DateTimePicker::make('paid_at')->label('تاريخ الدفع'),
                        DateTimePicker::make('shipped_at')->label('تاريخ الشحن'),
                        DateTimePicker::make('delivered_at')->label('تاريخ التسليم'),
                    ])
                    ->columns(4),
            ]);
    }

    public static function infolist(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('ملخص الطلب')
                    ->schema([
                        TextEntry::make('order_number')->label('رقم الطلب'),
                        TextEntry::make('status')
                            ->label('الحالة')
                            ->formatStateUsing(fn (?string $state): string => match ($state) {
                                'pending' => 'قيد الانتظار',
                                'confirmed' => 'مؤكد',
                                'processing' => 'قيد التجهيز',
                                'shipped' => 'تم الشحن',
                                'delivered' => 'تم التسليم',
                                'cancelled' => 'ملغي',
                                default => $state ?? '—',
                            }),
                        TextEntry::make('payment_status')
                            ->label('الدفع')
                            ->formatStateUsing(fn (?string $state): string => match ($state) {
                                'unpaid' => 'غير مدفوع',
                                'paid' => 'مدفوع',
                                'partial' => 'مدفوع جزئياً',
                                'refunded' => 'مسترجع',
                                default => $state ?? '—',
                            }),
                        TextEntry::make('customer_name')->label('المستلم'),
                        TextEntry::make('customer_phone')->label('الجوال'),
                        TextEntry::make('shipping_city')->label('المدينة'),
                        TextEntry::make('total')->label('الإجمالي')->money('EGP'),
                        TextEntry::make('points_earned')->label('نقاط مكتسبة')->placeholder('0'),
                        TextEntry::make('points_redeemed')->label('نقاط مستبدلة')->placeholder('0'),
                        TextEntry::make('points_discount_amount')->label('خصم النقاط')->money('EGP'),
                        TextEntry::make('shipping_address')->label('العنوان')->columnSpanFull(),
                        TextEntry::make('notes')->label('ملاحظات')->columnSpanFull(),
                    ])
                    ->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('order_number')->label('رقم الطلب')->searchable()->sortable()->copyable(),
                TextColumn::make('customer_name')->label('العميل')->searchable(),
                TextColumn::make('status')
                    ->label('الحالة')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending' => 'قيد الانتظار',
                        'confirmed' => 'مؤكد',
                        'processing' => 'قيد التجهيز',
                        'shipped' => 'تم الشحن',
                        'delivered' => 'تم التسليم',
                        'cancelled' => 'ملغي',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'confirmed', 'processing' => 'info',
                        'shipped' => 'primary',
                        'delivered' => 'success',
                        'cancelled' => 'danger',
                        default => 'gray',
                    }),
                TextColumn::make('payment_status')
                    ->label('الدفع')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'unpaid' => 'غير مدفوع',
                        'paid' => 'مدفوع',
                        'partial' => 'جزئي',
                        'refunded' => 'مسترجع',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'paid' => 'success',
                        'unpaid' => 'danger',
                        'partial' => 'warning',
                        default => 'gray',
                    }),
                TextColumn::make('total')->label('الإجمالي')->money('EGP')->sortable(),
                TextColumn::make('created_at')->label('التاريخ')->dateTime('Y-m-d H:i')->sortable(),
            ])
            ->filters([
                SelectFilter::make('status')->label('الحالة')->options([
                    'pending' => 'قيد الانتظار',
                    'confirmed' => 'مؤكد',
                    'processing' => 'قيد التجهيز',
                    'shipped' => 'تم الشحن',
                    'delivered' => 'تم التسليم',
                    'cancelled' => 'ملغي',
                ]),
                SelectFilter::make('payment_status')->label('الدفع')->options([
                    'unpaid' => 'غير مدفوع',
                    'paid' => 'مدفوع',
                    'partial' => 'جزئي',
                    'refunded' => 'مسترجع',
                ]),
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
            'index' => ListOrders::route('/'),
            'create' => CreateOrder::route('/create'),
            'view' => ViewOrder::route('/{record}'),
            'edit' => EditOrder::route('/{record}/edit'),
        ];
    }
}
