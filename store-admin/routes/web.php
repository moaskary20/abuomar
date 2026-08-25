<?php

use App\Http\Controllers\LegalController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/privacy-policy', [LegalController::class, 'privacyPolicy'])->name('privacy-policy');
Route::get('/privacy', [LegalController::class, 'privacyPolicy']);
Route::get('/privacy.html', [LegalController::class, 'privacyPolicy']);
