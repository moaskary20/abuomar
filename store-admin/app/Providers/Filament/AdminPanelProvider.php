<?php

namespace App\Providers\Filament;

use App\Filament\Livewire\PollingSidebar;
use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Pages\Dashboard;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\View\PanelsRenderHook;
use Filament\Widgets\AccountWidget;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\Support\Facades\Blade;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login()
            ->brandName('لوحة تحكم المتجر')
            ->font('Cairo')
            ->colors([
                'primary' => Color::Teal,
            ])
            ->sidebarLivewireComponent(PollingSidebar::class)
            ->databaseNotifications()
            ->databaseNotificationsPolling('10s')
            ->renderHook(
                PanelsRenderHook::STYLES_AFTER,
                fn (): string => Blade::render(<<<'HTML'
                    <style>
                        .fi-sidebar-item.fi-orders-unread .fi-sidebar-item-label {
                            color: #dc2626 !important;
                            font-weight: 700;
                        }

                        .fi-sidebar-item.fi-orders-unread .fi-sidebar-item-icon {
                            color: #dc2626 !important;
                        }

                        .dark .fi-sidebar-item.fi-orders-unread .fi-sidebar-item-label,
                        .dark .fi-sidebar-item.fi-orders-unread .fi-sidebar-item-icon {
                            color: #f87171 !important;
                        }
                    </style>
                HTML),
            )
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
            ->pages([
                Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
            ->widgets([
                AccountWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ])
            ->navigationGroups([
                'المنتجات',
                'المخزون',
                'المبيعات',
                'التسويق',
                'الإعدادات',
            ]);
    }
}
