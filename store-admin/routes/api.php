<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\StoreController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('forgot-password', [AuthController::class, 'forgotPassword']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('me', [AuthController::class, 'me']);
        Route::post('logout', [AuthController::class, 'logout']);
    });
});

Route::get('banners', [CatalogController::class, 'banners']);
Route::get('categories', [CatalogController::class, 'categories']);
Route::get('products', [CatalogController::class, 'products']);
Route::get('products/{id}', [CatalogController::class, 'product'])->whereNumber('id');

Route::get('shipping-methods', [StoreController::class, 'shippingMethods']);
Route::get('payment-methods', [StoreController::class, 'paymentMethods']);
Route::get('store-status', [StoreController::class, 'storeStatus']);
Route::post('coupons/validate', [StoreController::class, 'validateCoupon']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('addresses', [StoreController::class, 'addresses']);
    Route::post('addresses', [StoreController::class, 'storeAddress']);
    Route::put('addresses/{id}', [StoreController::class, 'updateAddress'])->whereNumber('id');
    Route::delete('addresses/{id}', [StoreController::class, 'deleteAddress'])->whereNumber('id');

    Route::get('orders', [StoreController::class, 'orders']);
    Route::get('orders/{id}', [StoreController::class, 'order'])->whereNumber('id');
    Route::post('orders', [StoreController::class, 'placeOrder']);

    Route::get('loyalty', [StoreController::class, 'loyalty']);

    Route::get('favorites', [StoreController::class, 'favorites']);
    Route::post('favorites', [StoreController::class, 'addFavorite']);
    Route::delete('favorites/{productId}', [StoreController::class, 'removeFavorite'])->whereNumber('productId');
});
