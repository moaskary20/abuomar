<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
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
            'email' => ['required', 'email', 'max:255', 'unique:customers,email'],
            'phone' => ['required', 'string', 'max:30'],
            'password' => ['required', 'string', 'min:6'],
        ], [
            'name.required' => 'الاسم مطلوب',
            'email.required' => 'البريد الإلكتروني مطلوب',
            'email.email' => 'بريد إلكتروني غير صالح',
            'email.unique' => 'هذا البريد مسجّل مسبقاً',
            'phone.required' => 'رقم الجوال مطلوب',
            'password.required' => 'كلمة المرور مطلوبة',
            'password.min' => 'كلمة المرور يجب ألا تقل عن 6 أحرف',
        ]);

        $customer = Customer::query()->create([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'],
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
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ], [
            'email.required' => 'البريد الإلكتروني مطلوب',
            'email.email' => 'بريد إلكتروني غير صالح',
            'password.required' => 'كلمة المرور مطلوبة',
        ]);

        $customer = Customer::query()
            ->where('email', $data['email'])
            ->first();

        if (! $customer || blank($customer->password) || ! Hash::check($data['password'], $customer->password)) {
            throw ValidationException::withMessages([
                'email' => ['بيانات الدخول غير صحيحة'],
            ]);
        }

        if (! $customer->is_active) {
            throw ValidationException::withMessages([
                'email' => ['هذا الحساب غير مفعّل. تواصل مع المتجر'],
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
            'email' => ['required', 'email'],
        ], [
            'email.required' => 'البريد الإلكتروني مطلوب',
            'email.email' => 'بريد إلكتروني غير صالح',
        ]);

        $exists = Customer::query()->where('email', $data['email'])->exists();

        return response()->json([
            'message' => $exists
                ? 'إذا كان البريد مسجّلاً لديك، يمكنك التواصل مع المتجر لإعادة تعيين كلمة المرور'
                : 'إذا كان البريد مسجّلاً لديك، يمكنك التواصل مع المتجر لإعادة تعيين كلمة المرور',
        ]);
    }
}
