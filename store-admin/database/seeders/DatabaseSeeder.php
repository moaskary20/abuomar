<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Coupon;
use App\Models\Customer;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Review;
use App\Models\ShippingMethod;
use App\Models\StoreSetting;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Admin User
        |--------------------------------------------------------------------------
        */

        User::query()->updateOrCreate(
            ['email' => 'admin@store.test'],
            [
                'name' => 'مدير المتجر',
                'password' => Hash::make('password'),
            ],
        );

        /*
        |--------------------------------------------------------------------------
        | Store Settings
        |--------------------------------------------------------------------------
        */

        StoreSetting::setValue(
            'store_name',
            'حلوانى ابوعمر',
            'general'
        );

        StoreSetting::setValue(
            'store_email',
            'info@store.test',
            'general'
        );

        StoreSetting::setValue(
            'store_phone',
            '0500000000',
            'general'
        );

        StoreSetting::setValue(
            'store_address',
            'الرياض، المملكة العربية السعودية',
            'general'
        );

        StoreSetting::setValue(
            'currency',
            'EGP',
            'sales'
        );

        StoreSetting::setValue(
            'tax_rate',
            '15',
            'sales'
        );

        StoreSetting::setValue(
            'order_prefix',
            'ORD',
            'sales'
        );

        StoreSetting::setValue(
            'low_stock_alert',
            '1',
            'sales'
        );

        /*
        |--------------------------------------------------------------------------
        | FawryPay Gateway Settings
        |--------------------------------------------------------------------------
        */

        StoreSetting::setValue('fawry_enabled', '0', 'fawry');
        StoreSetting::setValue('fawry_mode', 'sandbox', 'fawry');
        StoreSetting::setValue('fawry_merchant_code', '', 'fawry');
        StoreSetting::setValue('fawry_secure_key', '', 'fawry');
        StoreSetting::setValue('fawry_display_name', 'فوري', 'fawry');
        StoreSetting::setValue(
            'fawry_description',
            'ادفع عبر فوري: كود مرجعي، بطاقة، أو محفظة إلكترونية',
            'fawry'
        );
        StoreSetting::setValue('fawry_language', 'ar-eg', 'fawry');
        StoreSetting::setValue('fawry_currency', 'EGP', 'fawry');
        StoreSetting::setValue('fawry_channels', 'PayAtFawry,CARD,MWALLET', 'fawry');
        StoreSetting::setValue('fawry_enable_3ds', '1', 'fawry');
        StoreSetting::setValue('fawry_return_url', '', 'fawry');
        StoreSetting::setValue('fawry_webhook_url', '', 'fawry');
        StoreSetting::setValue('fawry_staging_base_url', 'https://atfawry.fawrystaging.com', 'fawry');
        StoreSetting::setValue('fawry_live_base_url', 'https://www.atfawry.com', 'fawry');
        StoreSetting::setValue(
            'fawry_customer_instructions',
            'بعد تأكيد الطلب ستصلك تعليمات الدفع عبر فوري (كود مرجعي أو رابط دفع).',
            'fawry'
        );

        app(\App\Services\FawryService::class)->syncPaymentMethod();

        /*
        |--------------------------------------------------------------------------
        | Loyalty Settings
        |--------------------------------------------------------------------------
        */

        StoreSetting::setValue(
            'loyalty_enabled',
            '1',
            'loyalty'
        );

        StoreSetting::setValue(
            'loyalty_points_per_currency',
            '1',
            'loyalty'
        );

        StoreSetting::setValue(
            'loyalty_currency_per_point',
            '0.1',
            'loyalty'
        );

        StoreSetting::setValue(
            'loyalty_min_order_to_earn',
            '0',
            'loyalty'
        );

        StoreSetting::setValue(
            'loyalty_min_points_to_redeem',
            '50',
            'loyalty'
        );

        StoreSetting::setValue(
            'loyalty_max_redeem_percent',
            '50',
            'loyalty'
        );

        StoreSetting::setValue(
            'loyalty_earn_on',
            'paid',
            'loyalty'
        );

        /*
        |--------------------------------------------------------------------------
        | Abo Omar pastry catalog
        |--------------------------------------------------------------------------
        */

        $this->call(AboOmarCatalogSeeder::class);
        $this->call(HomeBannersSeeder::class);

        /*
        |--------------------------------------------------------------------------
        | Customer
        |--------------------------------------------------------------------------
        */

        $customer = Customer::query()->updateOrCreate(
            ['email' => 'ahmed@example.com'],
            [
                'name' => 'أحمد محمد',
                'phone' => '0501234567',
                'password' => 'password',
                'city' => 'الرياض',
                'address' => 'حي النرجس، شارع الأمير',
                'is_active' => true,
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | Shipping Methods
        |--------------------------------------------------------------------------
        */

        $shipping = ShippingMethod::query()->updateOrCreate(
            ['name' => 'توصيل عادي'],
            [
                'price' => 25,
                'estimated_days' => 3,
                'is_active' => true,
                'description' => 'توصيل خلال 2-4 أيام عمل',
            ]
        );

        ShippingMethod::query()->updateOrCreate(
            ['name' => 'توصيل سريع'],
            [
                'price' => 45,
                'estimated_days' => 1,
                'is_active' => true,
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | Coupon
        |--------------------------------------------------------------------------
        */

        $coupon = Coupon::query()->updateOrCreate(
            ['code' => 'WELCOME10'],
            [
                'name' => 'خصم ترحيبي 10%',
                'type' => 'percentage',
                'value' => 10,
                'min_order_amount' => 100,
                'usage_limit' => 100,
                'is_active' => true,
            ]
        );

        $demoProducts = Product::query()->orderBy('id')->take(2)->get();

        if ($demoProducts->count() >= 2) {
            $first = $demoProducts[0];
            $second = $demoProducts[1];
            $subtotal = (float) $first->price + (float) $second->price;
            $discount = round($subtotal * 0.10, 2);
            $shippingAmount = 25.00;

            $order = Order::query()->updateOrCreate(
                [
                    'customer_id' => $customer->id,
                    'notes' => 'طلب تجريبي',
                ],
                [
                    'shipping_method_id' => $shipping->id,
                    'coupon_id' => $coupon->id,
                    'status' => 'pending',
                    'payment_status' => 'unpaid',
                    'payment_method' => 'cod',

                    'customer_name' => $customer->name,
                    'customer_phone' => $customer->phone,
                    'customer_email' => $customer->email,

                    'shipping_city' => $customer->city,
                    'shipping_address' => $customer->address,

                    'subtotal' => $subtotal,
                    'discount_amount' => $discount,
                    'shipping_amount' => $shippingAmount,
                    'tax_amount' => 0,
                    'total' => $subtotal - $discount + $shippingAmount,

                    'notes' => 'طلب تجريبي',
                ]
            );

            OrderItem::query()->updateOrCreate(
                [
                    'order_id' => $order->id,
                    'product_id' => $first->id,
                ],
                [
                    'product_name' => $first->name,
                    'product_sku' => $first->sku,
                    'quantity' => 1,
                    'unit_price' => $first->price,
                    'total' => $first->price,
                ]
            );

            OrderItem::query()->updateOrCreate(
                [
                    'order_id' => $order->id,
                    'product_id' => $second->id,
                ],
                [
                    'product_name' => $second->name,
                    'product_sku' => $second->sku,
                    'quantity' => 1,
                    'unit_price' => $second->price,
                    'total' => $second->price,
                ]
            );

            Review::query()->updateOrCreate(
                [
                    'product_id' => $first->id,
                    'customer_id' => $customer->id,
                ],
                [
                    'customer_name' => $customer->name,
                    'rating' => 5,
                    'title' => 'ممتازة',
                    'comment' => 'طعم رائع والتوصيل سريع',
                    'is_approved' => true,
                ]
            );
        }
    }
}