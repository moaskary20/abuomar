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
            'متجري الإلكتروني',
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
        | Categories
        |--------------------------------------------------------------------------
        */

        $electronics = Category::query()->updateOrCreate(
            ['slug' => 'electronics'],
            [
                'name' => 'إلكترونيات',
                'is_active' => true,
                'sort_order' => 1,
            ]
        );

        $fashion = Category::query()->updateOrCreate(
            ['slug' => 'fashion'],
            [
                'name' => 'أزياء',
                'is_active' => true,
                'sort_order' => 2,
            ]
        );

        $home = Category::query()->updateOrCreate(
            ['slug' => 'home'],
            [
                'name' => 'منزل ومطبخ',
                'is_active' => true,
                'sort_order' => 3,
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | Products
        |--------------------------------------------------------------------------
        */

        $products = [
            [
                'name' => 'سماعات لاسلكية',
                'slug' => 'wireless-headphones',
                'sku' => 'SKU-1001',
                'category_id' => $electronics->id,
                'price' => 249.00,
                'compare_price' => 299.00,
                'quantity' => 40,
                'is_featured' => true,
                'short_description' => 'سماعات بلوتوث بجودة عالية',
            ],
            [
                'name' => 'ساعة ذكية',
                'slug' => 'smart-watch',
                'sku' => 'SKU-1002',
                'category_id' => $electronics->id,
                'price' => 899.00,
                'compare_price' => 999.00,
                'quantity' => 15,
                'is_featured' => true,
                'short_description' => 'ساعة ذكية بتتبع اللياقة',
            ],
            [
                'name' => 'حذاء رياضي',
                'slug' => 'running-shoes',
                'sku' => 'SKU-2001',
                'category_id' => $fashion->id,
                'price' => 399.00,
                'quantity' => 3,
                'low_stock_threshold' => 5,
                'short_description' => 'حذاء مريح للجري اليومي',
            ],
            [
                'name' => 'مقلاة كهربائية',
                'slug' => 'air-fryer',
                'sku' => 'SKU-3001',
                'category_id' => $home->id,
                'price' => 450.00,
                'quantity' => 22,
                'short_description' => 'مقلاة هوائية سعة 5 لتر',
            ],
        ];

        $createdProducts = [];

        foreach ($products as $product) {
            $createdProducts[] = Product::query()->updateOrCreate(
                ['slug' => $product['slug']],
                array_merge(
                    [
                        'is_active' => true,
                        'track_quantity' => true,
                        'unit' => 'قطعة',
                    ],
                    $product
                )
            );
        }

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

        /*
        |--------------------------------------------------------------------------
        | Demo Order
        |--------------------------------------------------------------------------
        */

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

                'subtotal' => 648.00,
                'discount_amount' => 64.80,
                'shipping_amount' => 25.00,
                'tax_amount' => 0,
                'total' => 608.20,

                'notes' => 'طلب تجريبي',
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | Order Items
        |--------------------------------------------------------------------------
        */

        OrderItem::query()->updateOrCreate(
            [
                'order_id' => $order->id,
                'product_id' => $createdProducts[0]->id,
            ],
            [
                'product_name' => $createdProducts[0]->name,
                'product_sku' => $createdProducts[0]->sku,
                'quantity' => 1,
                'unit_price' => $createdProducts[0]->price,
                'total' => $createdProducts[0]->price,
            ]
        );

        OrderItem::query()->updateOrCreate(
            [
                'order_id' => $order->id,
                'product_id' => $createdProducts[2]->id,
            ],
            [
                'product_name' => $createdProducts[2]->name,
                'product_sku' => $createdProducts[2]->sku,
                'quantity' => 1,
                'unit_price' => $createdProducts[2]->price,
                'total' => $createdProducts[2]->price,
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | Product Review
        |--------------------------------------------------------------------------
        */

        Review::query()->updateOrCreate(
            [
                'product_id' => $createdProducts[0]->id,
                'customer_id' => $customer->id,
            ],
            [
                'customer_name' => $customer->name,
                'rating' => 5,
                'title' => 'ممتازة',
                'comment' => 'جودة الصوت رائعة والتوصيل سريع',
                'is_approved' => true,
            ]
        );
    }
}