<?php

namespace App\Console\Commands;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class ImportAboOmarPastry extends Command
{
    protected $signature = 'store:import-aboomar
                            {--fresh : حذف التصنيفات والمنتجات الحالية قبل الاستيراد}
                            {--json= : مسار ملف JSON الناتج عن السكربت}';

    protected $description = 'استيراد التصنيفات والمنتجات من ملف scraped aboomarpastry.com';

    public function handle(): int
    {
        $jsonPath = $this->option('json') ?: storage_path('app/imports/aboomar.json');

        if (! File::exists($jsonPath)) {
            $this->error("الملف غير موجود: {$jsonPath}");
            $this->line('شغّل أولاً: python3 scripts/scrape_aboomar.py');

            return self::FAILURE;
        }

        $payload = json_decode(File::get($jsonPath), true, 512, JSON_THROW_ON_ERROR);

        if ($this->option('fresh')) {
            $this->warn('حذف البيانات الحالية...');

            foreach (['order_items', 'reviews', 'stock_movements'] as $table) {
                if (DB::getSchemaBuilder()->hasTable($table)) {
                    DB::table($table)->delete();
                }
            }

            Product::query()->delete();
            Category::query()->delete();
        }

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
            $this->line("✓ تصنيف: {$category->name}");
        }

        $count = 0;

        foreach ($payload['products'] ?? [] as $productData) {
            Product::query()->updateOrCreate(
                ['slug' => $productData['slug']],
                [
                    'name' => $productData['name'],
                    'sku' => $productData['sku'],
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

        $this->info('اكتمل الاستيراد: '.count($categoryMap)." تصنيفات، {$count} منتجات");

        return self::SUCCESS;
    }
}
