<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;

class AboOmarCatalogSeeder extends Seeder
{
    public function run(): void
    {
        $path = database_path('data/aboomar.json');

        if (! File::exists($path)) {
            $path = storage_path('app/imports/aboomar.json');
        }

        if (! File::exists($path)) {
            $this->command?->error("ملف كتالوج أبو عمر غير موجود: {$path}");

            return;
        }

        $payload = json_decode(File::get($path), true, 512, JSON_THROW_ON_ERROR);
        $categoryMap = [];

        foreach ($payload['categories'] ?? [] as $categoryData) {
            $category = Category::query()->updateOrCreate(
                ['slug' => $categoryData['slug']],
                [
                    'name' => $categoryData['name'],
                    'image' => $categoryData['image'] ?? null,
                    'is_active' => true,
                    'sort_order' => $categoryData['sort_order'] ?? 0,
                ],
            );

            $categoryMap[$category->slug] = $category->id;
        }

        $count = 0;

        foreach ($payload['products'] ?? [] as $productData) {
            Product::query()->updateOrCreate(
                ['slug' => $productData['slug']],
                [
                    'name' => $productData['name'],
                    'sku' => $productData['sku'] ?? null,
                    'category_id' => $categoryMap[$productData['category_slug']] ?? null,
                    'short_description' => $productData['short_description'] ?? null,
                    'description' => $productData['description'] ?? null,
                    'price' => $productData['price'] ?? 0,
                    'compare_price' => $productData['compare_price'] ?? null,
                    'quantity' => $productData['quantity'] ?? 0,
                    'low_stock_threshold' => 5,
                    'track_quantity' => true,
                    'is_active' => true,
                    'is_featured' => (bool) ($productData['is_featured'] ?? false),
                    'image' => $productData['image'] ?? null,
                    'gallery' => $productData['gallery'] ?? null,
                    'unit' => 'قطعة',
                ],
            );
            $count++;
        }

        $this->command?->info('كتالوج أبو عمر: '.count($categoryMap)." تصنيفات، {$count} منتجات");
    }
}
