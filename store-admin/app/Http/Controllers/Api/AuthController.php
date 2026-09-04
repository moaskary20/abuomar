<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Support\Phone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:30'],
            'password' => ['required', 'string', 'min:6'],
            'email' => ['nullable', 'email', 'max:255', 'unique:customers,email'],
        ], [
            'name.required' => 'الاسم مطلوب',
            'phone.required' => 'رقم الجوال مطلوب',
            'password.required' => 'كلمة المرور مطلوبة',
            'password.min' => 'كلمة المرور يجب ألا تقل عن 6 أحرف',
            'email.email' => 'بريد إلكتروني غير صالح',
            'email.unique' => 'هذا البريد مسجّل مسبقاً',
        ]);

        $phone = Phone::normalize($data['phone']);

        if (! Phone::isValidEgyptianMobile($phone)) {
            throw ValidationException::withMessages([
                'phone' => ['أدخل رقم جوال مصري صحيح مثل 01xxxxxxxxx'],
            ]);
        }

        if (Customer::query()->where('phone', $phone)->exists()) {
            throw ValidationException::withMessages([
                'phone' => ['رقم الجوال مسجّل مسبقاً'],
            ]);
        }

        $customer = Customer::query()->create([
            'name' => $data['name'],
            'phone' => $phone,
            'email' => $data['email'] ?? null,
            'password' => $data['password'],
            'is_active' => true,
        ]);

        $token = $customer->createToken('mobile')->plainTextToken;

        return response()->json([
            'message' => 'تم إنشاء الحساب بنجاح',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => $customer->toApiArray(),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'phone' => ['required', 'string'],
            'password' => ['required', 'string'],
        ], [
            'phone.required' => 'رقم الجوال مطلوب',
            'password.required' => 'كلمة المرور مطلوبة',
        ]);

        $phone = Phone::normalize($data['phone']);

        $customer = $phone
            ? Customer::query()->where('phone', $phone)->first()
            : null;

        if (! $customer || blank($customer->password) || ! Hash::check($data['password'], $customer->password)) {
            throw ValidationException::withMessages([
                'phone' => ['بيانات الدخول غير صحيحة'],
            ]);
        }

        if (! $customer->is_active) {
            throw ValidationException::withMessages([
                'phone' => ['هذا الحساب غير مفعّل. تواصل مع المتجر'],
            ]);
        }

        $customer->tokens()->where('name', 'mobile')->delete();
        $token = $customer->createToken('mobile')->plainTextToken;

        return response()->json([
            'message' => 'تم تسجيل الدخول بنجاح',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => $customer->toApiArray(),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        /** @var Customer $customer */
        $customer = $request->user();

        return response()->json([
            'user' => $customer->toApiArray(),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $token = $request->user()?->currentAccessToken();
        if ($token) {
            $token->delete();
        }

        return response()->json([
            'message' => 'تم تسجيل الخروج',
        ]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'phone' => ['required', 'string'],
        ], [
            'phone.required' => 'رقم الجوال مطلوب',
        ]);

        $phone = Phone::normalize($data['phone']);
        $exists = $phone
            ? Customer::query()->where('phone', $phone)->exists()
            : false;

        return response()->json([
            'message' => $exists
                ? 'إذا كان رقم الجوال مسجّلاً لديك، يمكنك التواصل مع المتجر لإعادة تعيين كلمة المرور'
                : 'إذا كان رقم الجوال مسجّلاً لديك، يمكنك التواصل مع المتجر لإعادة تعيين كلمة المرور',
        ]);
    }
}
