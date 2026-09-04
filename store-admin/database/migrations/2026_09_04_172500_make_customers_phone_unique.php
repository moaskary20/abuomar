<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $customers = DB::table('customers')->whereNotNull('phone')->get(['id', 'phone']);
        $seen = [];

        foreach ($customers as $customer) {
            $normalized = preg_replace('/\D+/', '', (string) $customer->phone) ?: null;
            if ($normalized === null) {
                DB::table('customers')->where('id', $customer->id)->update(['phone' => null]);

                continue;
            }

            // تحويل +20 إلى صيغة محلية 01...
            if (str_starts_with($normalized, '20') && strlen($normalized) >= 11) {
                $local = substr($normalized, 2);
                $normalized = str_starts_with($local, '0') ? $local : '0'.$local;
            }

            if (isset($seen[$normalized])) {
                $normalized = $normalized.'x'.$customer->id;
            }

            $seen[$normalized] = true;
            DB::table('customers')->where('id', $customer->id)->update(['phone' => $normalized]);
        }

        Schema::table('customers', function (Blueprint $table) {
            $table->unique('phone');
        });
    }

    public function down(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->dropUnique(['phone']);
        });
    }
};
