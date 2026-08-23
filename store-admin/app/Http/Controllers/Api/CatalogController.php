<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use App\Models\Category;
use App\Models\Product;
use App\Support\ApiMedia;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public function banners(): JsonResponse
    {
        $items = Banner::query()
            ->active()
            ->ordered()
            ->get()
            ->map(fn (Banner $b) => [
                'id' => $b->id,
                'title' => $b->title,
                'subtitle' => $b->subtitle,
                'image_url' => ApiMedia::url($b->image),
                'link_type' => $b->link_type ?? 'none',
                'link_value' => $b->link_value,
                'sort_order' => (int) $b->sort_order,
            ]);

        return response()->json(['data' => $items]);
    }

    public function categories(): JsonResponse
    {
        $items = Category::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->map(fn (Category $c) => [
                'id' => $c->id,
                'name' => $c->name,
                'image_url' => ApiMedia::url($c->image),
                'sort_order' => (int) $c->sort_order,
            ]);

        return response()->json(['data' => $items]);
    }

    public function products(Request $request): JsonResponse
    {
        $query = Product::query()
            ->with(['category:id,name', 'reviews' => fn ($q) => $q->where('is_approved', true)->latest()->limit(20)])
            ->where('is_active', true);

        if ($request->filled('category_id')) {
            $query->where('category_id', (int) $request->query('category_id'));
        }

        if ($request->boolean('featured')) {
            $query->where('is_featured', true);
        }

        if ($request->filled('q')) {
            $q = trim((string) $request->query('q'));
            $query->where(function ($builder) use ($q): void {
                $builder->where('name', 'like', "%{$q}%")
                    ->orWhere('sku', 'like', "%{$q}%");
            });
        }

        $items = $query
            ->orderByDesc('is_featured')
            ->orderBy('name')
            ->get()
            ->map(fn (Product $p) => $this->productPayload($p));

        return response()->json(['data' => $items]);
    }

    public function product(int $id): JsonResponse
    {
        $product = Product::query()
            ->with(['category:id,name', 'reviews' => fn ($q) => $q->where('is_approved', true)->latest()->limit(30)])
            ->where('is_active', true)
            ->findOrFail($id);

        return response()->json(['data' => $this->productPayload($product)]);
    }

    private function productPayload(Product $p): array
    {
        $reviews = $p->relationLoaded('reviews')
            ? $p->reviews->map(fn ($r) => [
                'customer_name' => $r->customer_name ?? $r->name ?? 'عميل',
                'rating' => (int) $r->rating,
                'title' => $r->title,
                'comment' => $r->comment ?? $r->body,
            ])->values()->all()
            : [];

        return [
            'id' => $p->id,
            'name' => $p->name,
            'slug' => $p->slug,
            'sku' => $p->sku,
            'barcode' => $p->barcode,
            'category_id' => (int) $p->category_id,
            'category_name' => $p->category?->name,
            'short_description' => $p->short_description,
            'description' => $p->description,
            'price' => (float) $p->price,
            'compare_price' => $p->compare_price !== null ? (float) $p->compare_price : null,
            'quantity' => (int) $p->quantity,
            'low_stock_threshold' => (int) $p->low_stock_threshold,
            'track_quantity' => (bool) $p->track_quantity,
            'is_featured' => (bool) $p->is_featured,
            'image_url' => ApiMedia::url($p->image),
            'gallery_urls' => ApiMedia::urls($p->gallery),
            'weight' => $p->weight !== null ? (float) $p->weight : null,
            'unit' => $p->unit ?: 'قطعة',
            'reviews' => $reviews,
        ];
    }
}
