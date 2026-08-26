<?php

namespace Database\Seeders;

use App\Models\Banner;
use Illuminate\Database\Seeder;

class HomeBannersSeeder extends Seeder
{
    public function run(): void
    {
        $banners = [
            [
                'title' => 'حلويات أبو عمر',
                'subtitle' => 'طازجة من الفرن إلى بابك',
                'image' => 'banners/b1.png',
                'sort_order' => 1,
            ],
            [
                'title' => 'عروض خاصة',
                'subtitle' => 'اكتشف تشكيلتنا اليوم',
                'image' => 'banners/b2.png',
                'sort_order' => 2,
            ],
            [
                'title' => 'تشكيلة اليوم',
                'subtitle' => 'حلويات شرقية وغربية',
                'image' => 'banners/b3.png',
                'sort_order' => 3,
            ],
        ];

        foreach ($banners as $banner) {
            Banner::query()->updateOrCreate(
                ['image' => $banner['image']],
                [
                    'title' => $banner['title'],
                    'subtitle' => $banner['subtitle'],
                    'link_type' => 'none',
                    'link_value' => null,
                    'sort_order' => $banner['sort_order'],
                    'is_active' => true,
                ],
            );
        }

        $this->command?->info('سلايدر الرئيسية: '.count($banners).' بانرات');
    }
}
