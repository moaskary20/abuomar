<?php

namespace App\Filament\Livewire;

use Filament\Livewire\Sidebar as FilamentSidebar;
use Illuminate\Contracts\View\View;

class PollingSidebar extends FilamentSidebar
{
    public function render(): View
    {
        return view('filament.polling-sidebar');
    }
}
