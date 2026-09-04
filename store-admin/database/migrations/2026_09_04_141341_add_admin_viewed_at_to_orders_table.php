<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->timestamp('admin_viewed_at')->nullable()->after('delivered_at');
        });

        // الطلبات الحالية تُعتبر مقروءة حتى لا تظهر كلها كجديدة
        DB::table('orders')->whereNull('admin_viewed_at')->update([
            'admin_viewed_at' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('admin_viewed_at');
        });
    }
};
