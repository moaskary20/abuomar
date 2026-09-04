<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Models\CustomerAddress;
use App\Models\FawrySetting;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\PaymentMethod;
use App\Models\Product;
use App\Models\ShippingMethod;
use App\Services\AdminOrderNotifier;
use App\Services\LoyaltyService;
use App\Support\ApiMedia;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class StoreController extends Controller
{
    public function shippingMethods(): JsonResponse
    {
        $items = ShippingMethod::query()
            ->where('is_active', true)
            ->orderBy('price')
            ->get()
            ->map(fn (ShippingMethod $m) => [
                'id' => $m->id,
                'name' => $m->name,
                'description' => $m->description,
                'price' => (float) $m->price,
                'estimated_days' => $m->estimated_days,
            ]);

        return response()->json(['data' => $items]);
    }

    public function paymentMethods(): JsonResponse
    {
        $items = PaymentMethod::query()
            ->active()
            ->ordered()
            ->get()
            ->map(function (PaymentMethod $m) {
                $payload = [
                    'id' => $m->id,
                    'code' => $m->code,
                    'name' => $m->name,
                    'description' => $m->description,
                    'icon' => $m->icon ?: 'payments',
                    'sort_order' => (int) $m->sort_order,
                    'is_active' => (bool) $m->is_active,
                    'is_default' => (bool) $m->is_default,
                    'requires_online' => (bool) $m->requires_online,
                ];

                if ($m->code === FawrySetting::CODE) {
                    $payload['gateway'] = FawrySetting::publicConfig();
                }

                return $payload;
            });

        return response()->json([
            'data' => $items,
            'gateways' => [
                'fawry' => FawrySetting::publicConfig(),
            ],
        ]);
    }

    public function validateCoupon(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => ['required', 'string'],
            'subtotal' => ['nullable', 'numeric', 'min:0'],
        ]);

        $coupon = Coupon::query()
            ->whereRaw('LOWER(code) = ?', [mb_strtolower(trim($data['code']))])
            ->first();

        if (! $coupon || ! $coupon->is_active) {
            throw ValidationException::withMessages(['code' => ['الكوبون غير صالح']]);
        }

        $now = now();
        if ($coupon->starts_at && $now->lt($coupon->starts_at)) {
            throw ValidationException::withMessages(['code' => ['هذا الكوبون لم يبدأ بعد']]);
        }
        if ($coupon->expires_at && $now->gt($coupon->expires_at)) {
            throw ValidationException::withMessages(['code' => ['انتهت صلاحية هذا الكوبون']]);
        }
        if ($coupon->usage_limit !== null && $coupon->used_count >= $coupon->usage_limit) {
            throw ValidationException::withMessages(['code' => ['تم استهلاك حد استخدام هذا الكوبون']]);
        }

        $subtotal = (float) ($data['subtotal'] ?? 0);
        if ($coupon->min_order_amount !== null && $subtotal < (float) $coupon->min_order_amount) {
            throw ValidationException::withMessages([
                'code' => ['الحد الأدنى للطلب '.(float) $coupon->min_order_amount.' ج.م'],
            ]);
        }

        $discount = $this->couponDiscount($coupon, $subtotal);

        return response()->json([
            'data' => [
                'id' => $coupon->id,
                'code' => $coupon->code,
                'name' => $coupon->name,
                'type' => $coupon->type,
                'value' => (float) $coupon->value,
                'min_order_amount' => $coupon->min_order_amount !== null ? (float) $coupon->min_order_amount : null,
                'max_discount' => $coupon->max_discount !== null ? (float) $coupon->max_discount : null,
                'discount_amount' => $discount,
            ],
        ]);
    }

    public function addresses(Request $request): JsonResponse
    {
        $items = $request->user()
            ->addresses()
            ->orderByDesc('is_default')
            ->orderBy('id')
            ->get()
            ->map(fn (CustomerAddress $a) => $this->addressPayload($a));

        return response()->json(['data' => $items]);
    }

    public function storeAddress(Request $request): JsonResponse
    {
        $data = $this->validateAddress($request);
        $customer = $request->user();

        $address = $customer->addresses()->create([
            ...$data,
            'is_default' => (bool) ($data['is_default'] ?? $customer->addresses()->count() === 0),
        ]);

        return response()->json(['data' => $this->addressPayload($address->fresh())], 201);
    }

    public function updateAddress(Request $request, int $id): JsonResponse
    {
        $address = $request->user()->addresses()->findOrFail($id);
        $data = $this->validateAddress($request, false);
        $address->update($data);

        return response()->json(['data' => $this->addressPayload($address->fresh())]);
    }

    public function deleteAddress(Request $request, int $id): JsonResponse
    {
        $address = $request->user()->addresses()->findOrFail($id);
        $address->delete();

        return response()->json(['message' => 'تم حذف العنوان']);
    }

    public function orders(Request $request): JsonResponse
    {
        $items = $request->user()
            ->orders()
            ->with('items.product:id,image')
            ->latest()
            ->get()
            ->map(fn (Order $o) => $this->orderPayload($o));

        return response()->json(['data' => $items]);
    }

    public function order(Request $request, int $id): JsonResponse
    {
        $order = $request->user()
            ->orders()
            ->with('items.product:id,image')
            ->findOrFail($id);

        return response()->json(['data' => $this->orderPayload($order)]);
    }

    public function placeOrder(Request $request, LoyaltyService $loyalty): JsonResponse
    {
        $data = $request->validate([
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'payment_method' => ['required', 'string', 'max:50'],
            'shipping_method_id' => ['nullable', 'integer', 'exists:shipping_methods,id'],
            'coupon_code' => ['nullable', 'string', 'max:50'],
            'points_to_redeem' => ['nullable', 'integer', 'min:0'],
            'customer_name' => ['required', 'string', 'max:255'],
            'customer_phone' => ['required', 'string', 'max:30'],
            'customer_email' => ['nullable', 'email', 'max:255'],
            'shipping_city' => ['required', 'string', 'max:120'],
            'shipping_address' => ['required', 'string', 'max:500'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ], [
            'items.required' => 'السلة فارغة',
            'customer_name.required' => 'الاسم مطلوب',
            'customer_phone.required' => 'رقم الجوال مطلوب',
            'shipping_city.required' => 'المدينة مطلوبة',
            'shipping_address.required' => 'العنوان مطلوب',
        ]);

        /** @var \App\Models\Customer $customer */
        $customer = $request->user();

        $order = DB::transaction(function () use ($data, $customer, $loyalty) {
            $subtotal = 0.0;
            $lineRows = [];

            foreach ($data['items'] as $row) {
                $product = Product::query()->where('is_active', true)->lockForUpdate()->findOrFail($row['product_id']);
                $qty = (int) $row['quantity'];
                if ($product->track_quantity && $product->quantity < $qty) {
                    throw ValidationException::withMessages([
                        'items' => ["الكمية غير متاحة للمنتج: {$product->name}"],
                    ]);
                }

                $lineTotal = round((float) $product->price * $qty, 2);
                $subtotal += $lineTotal;
                $lineRows[] = [
                    'product' => $product,
                    'quantity' => $qty,
                    'unit_price' => (float) $product->price,
                    'total' => $lineTotal,
                ];
            }

            $shippingAmount = 0.0;
            $shippingMethodId = $data['shipping_method_id'] ?? null;
            if ($shippingMethodId) {
                $shipping = ShippingMethod::query()->where('is_active', true)->findOrFail($shippingMethodId);
                $shippingAmount = (float) $shipping->price;
            } else {
                $shipping = ShippingMethod::query()->where('is_active', true)->orderBy('price')->first();
                if ($shipping) {
                    $shippingMethodId = $shipping->id;
                    $shippingAmount = (float) $shipping->price;
                } else {
                    $shippingAmount = 25;
                }
            }

            $discount = 0.0;
            $couponId = null;
            $couponCode = null;
            if (! empty($data['coupon_code'])) {
                $coupon = Coupon::query()
                    ->whereRaw('LOWER(code) = ?', [mb_strtolower(trim($data['coupon_code']))])
                    ->lockForUpdate()
                    ->first();
                if (! $coupon || ! $coupon->is_active) {
                    throw ValidationException::withMessages(['coupon_code' => ['الكوبون غير صالح']]);
                }
                $discount = $this->couponDiscount($coupon, $subtotal);
                $couponId = $coupon->id;
                $couponCode = $coupon->code;
                $coupon->increment('used_count');
            }

            $pointsToRedeem = (int) ($data['points_to_redeem'] ?? 0);
            $pointsDiscount = 0.0;
            if ($pointsToRedeem > 0) {
                $max = $loyalty->maxRedeemablePoints($customer, $subtotal);
                if ($pointsToRedeem > $max) {
                    throw ValidationException::withMessages([
                        'points_to_redeem' => ['رصيد النقاط غير كافٍ أو يتجاوز الحد المسموح'],
                    ]);
                }
                $pointsDiscount = $loyalty->calculateDiscountFromPoints($pointsToRedeem);
            }

            $total = max(0, round($subtotal - $discount - $pointsDiscount + $shippingAmount, 2));
            $paymentMethod = $data['payment_method'];

            $order = Order::query()->create([
                'customer_id' => $customer->id,
                'shipping_method_id' => $shippingMethodId,
                'coupon_id' => $couponId,
                'status' => 'pending',
                'payment_status' => $paymentMethod === 'cod' ? 'unpaid' : 'unpaid',
                'payment_method' => $paymentMethod,
                'customer_name' => $data['customer_name'],
                'customer_phone' => $data['customer_phone'],
                'customer_email' => $data['customer_email'] ?? $customer->email,
                'shipping_city' => $data['shipping_city'],
                'shipping_address' => $data['shipping_address'],
                'subtotal' => $subtotal,
                'discount_amount' => $discount,
                'shipping_amount' => $shippingAmount,
                'tax_amount' => 0,
                'points_to_redeem' => $pointsToRedeem,
                'points_discount_amount' => $pointsDiscount,
                'points_earned' => 0,
                'points_redeemed' => $pointsToRedeem,
                'total' => $total,
                'notes' => ($data['notes'] ?? null).($couponCode ? "\nكوبون: {$couponCode}" : ''),
            ]);

            foreach ($lineRows as $line) {
                OrderItem::query()->create([
                    'order_id' => $order->id,
                    'product_id' => $line['product']->id,
                    'product_name' => $line['product']->name,
                    'product_sku' => $line['product']->sku,
                    'quantity' => $line['quantity'],
                    'unit_price' => $line['unit_price'],
                    'total' => $line['total'],
                ]);

                if ($line['product']->track_quantity) {
                    $line['product']->decrement('quantity', $line['quantity']);
                }
            }

            if ($pointsToRedeem > 0) {
                $loyalty->adjust(
                    $customer,
                    -$pointsToRedeem,
                    'استبدال نقاط على الطلب '.$order->order_number,
                );
            }

            return $order->load('items.product:id,image');
        });

        app(AdminOrderNotifier::class)->notifyNewOrder($order);

        return response()->json([
            'message' => 'تم إنشاء الطلب بنجاح',
            'data' => $this->orderPayload($order),
        ], 201);
    }

    public function loyalty(Request $request): JsonResponse
    {
        $customer = $request->user()->fresh();
        $history = $customer->loyaltyTransactions()
            ->latest()
            ->limit(50)
            ->get()
            ->map(fn ($t) => [
                'title' => $t->description ?? $t->type,
                'points' => (int) $t->points,
                'created_at' => optional($t->created_at)?->toIso8601String(),
                'type' => $t->type,
            ]);

        return response()->json([
            'data' => [
                'points' => (int) ($customer->loyalty_points ?? 0),
                'earned_total' => (int) ($customer->loyalty_points_earned ?? 0),
                'redeemed_total' => (int) ($customer->loyalty_points_redeemed ?? 0),
                'history' => $history,
            ],
        ]);
    }

    public function favorites(Request $request): JsonResponse
    {
        $ids = $request->user()->favorites()->pluck('product_id');
        $products = Product::query()
            ->with('category:id,name')
            ->whereIn('id', $ids)
            ->where('is_active', true)
            ->get()
            ->map(fn (Product $p) => [
                'id' => $p->id,
                'name' => $p->name,
                'category_id' => (int) $p->category_id,
                'category_name' => $p->category?->name,
                'price' => (float) $p->price,
                'compare_price' => $p->compare_price !== null ? (float) $p->compare_price : null,
                'image_url' => ApiMedia::url($p->image),
                'is_featured' => (bool) $p->is_featured,
                'quantity' => (int) $p->quantity,
                'track_quantity' => (bool) $p->track_quantity,
                'unit' => $p->unit ?: 'قطعة',
            ]);

        return response()->json(['data' => $products]);
    }

    public function addFavorite(Request $request): JsonResponse
    {
        $data = $request->validate([
            'product_id' => ['required', 'integer', 'exists:products,id'],
        ]);

        $request->user()->favorites()->syncWithoutDetaching([$data['product_id']]);

        return response()->json(['message' => 'تمت الإضافة للمفضلة']);
    }

    public function removeFavorite(Request $request, int $productId): JsonResponse
    {
        $request->user()->favorites()->detach($productId);

        return response()->json(['message' => 'تمت الإزالة من المفضلة']);
    }

    private function validateAddress(Request $request, bool $requireAll = true): array
    {
        $rules = [
            'label' => [$requireAll ? 'required' : 'sometimes', 'string', 'max:80'],
            'recipient_name' => [$requireAll ? 'required' : 'sometimes', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:30'],
            'city' => [$requireAll ? 'required' : 'sometimes', 'string', 'max:120'],
            'area' => ['nullable', 'string', 'max:120'],
            'street' => [$requireAll ? 'required' : 'sometimes', 'string', 'max:255'],
            'building' => ['nullable', 'string', 'max:50'],
            'floor' => ['nullable', 'string', 'max:50'],
            'apartment' => ['nullable', 'string', 'max:50'],
            'notes' => ['nullable', 'string', 'max:500'],
            'is_default' => ['nullable', 'boolean'],
        ];

        return $request->validate($rules);
    }

    private function addressPayload(CustomerAddress $a): array
    {
        return [
            'id' => $a->id,
            'label' => $a->label,
            'recipient_name' => $a->recipient_name,
            'phone' => $a->phone,
            'city' => $a->city,
            'area' => $a->area,
            'street' => $a->street,
            'building' => $a->building,
            'floor' => $a->floor,
            'apartment' => $a->apartment,
            'notes' => $a->notes,
            'is_default' => (bool) $a->is_default,
            'full_address' => $a->full_address,
        ];
    }

    private function orderPayload(Order $o): array
    {
        return [
            'id' => $o->id,
            'order_number' => $o->order_number,
            'status' => $o->status,
            'payment_status' => $o->payment_status,
            'payment_method' => $o->payment_method,
            'subtotal' => (float) $o->subtotal,
            'discount_amount' => (float) $o->discount_amount,
            'shipping_amount' => (float) $o->shipping_amount,
            'points_earned' => (int) ($o->points_earned ?? 0),
            'points_redeemed' => (int) ($o->points_redeemed ?? 0),
            'total' => (float) $o->total,
            'created_at' => optional($o->created_at)?->toIso8601String(),
            'shipping_city' => $o->shipping_city,
            'shipping_address' => $o->shipping_address,
            'notes' => $o->notes,
            'items' => $o->items->map(fn (OrderItem $i) => [
                'product_id' => $i->product_id,
                'name' => $i->product_name,
                'image_url' => ApiMedia::url($i->product?->image),
                'unit_price' => (float) $i->unit_price,
                'quantity' => (int) $i->quantity,
            ])->values()->all(),
        ];
    }

    private function couponDiscount(Coupon $coupon, float $subtotal): float
    {
        if ($subtotal <= 0) {
            return 0.0;
        }

        $discount = $coupon->type === 'percentage'
            ? $subtotal * ((float) $coupon->value / 100)
            : (float) $coupon->value;

        if ($coupon->max_discount !== null) {
            $discount = min($discount, (float) $coupon->max_discount);
        }

        return round(min($discount, $subtotal), 2);
    }
}
