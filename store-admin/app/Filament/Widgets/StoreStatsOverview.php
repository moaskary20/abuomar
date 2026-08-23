<?php

namespace App\Filament\Widgets;

use App\Models\Customer;
use App\Models\Order;
use App\Models\Product;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StoreStatsOverview extends StatsOverviewWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $lowStock = Product::query()
            ->where('track_quantity', true)
            ->whereColumn('quantity', '<=', 'low_stock_threshold')
            ->count();

        $pendingOrders = Order::query()->where('status', 'pending')->count();
        $revenue = (float) Order::query()->where('payment_status', 'paid')->sum('total');

        return [
            Stat::make('إجمالي المنتجات', (string) Product::count())
                ->description('المنتجات المسجلة في المتجر')
                ->descriptionIcon('heroicon-m-cube')
                ->color('primary'),
            Stat::make('الطلبات المعلقة', (string) $pendingOrders)
                ->description('بانتظار المعالجة')
                ->descriptionIcon('heroicon-m-clock')
                ->color('warning'),
            Stat::make('إيرادات المدفوع', number_format($revenue, 2).' ج.م')
                ->description('من الطلبات المدفوعة')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('success'),
            Stat::make('نقص المخزون', (string) $lowStock)
                ->description('منتجات تحت الحد الأدنى')
                ->descriptionIcon('heroicon-m-exclamation-triangle')
                ->color($lowStock > 0 ? 'danger' : 'success'),
            Stat::make('العملاء', (string) Customer::count())
                ->description('إجمالي العملاء')
                ->descriptionIcon('heroicon-m-users')
                ->color('info'),
            Stat::make('إجمالي الطلبات', (string) Order::count())
                ->description('كل الطلبات')
                ->descriptionIcon('heroicon-m-shopping-bag')
                ->color('gray'),
        ];
    }
}
