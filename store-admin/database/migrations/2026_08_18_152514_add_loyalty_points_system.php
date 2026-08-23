<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('customers', function (Blueprint $table) {
            $table->unsignedInteger('loyalty_points')->default(0)->after('is_active');
            $table->unsignedInteger('loyalty_points_earned')->default(0)->after('loyalty_points');
            $table->unsignedInteger('loyalty_points_redeemed')->default(0)->after('loyalty_points_earned');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->unsignedInteger('points_to_redeem')->default(0)->after('tax_amount');
            $table->decimal('points_discount_amount', 12, 2)->default(0)->after('points_to_redeem');
            $table->unsignedInteger('points_earned')->default(0)->after('points_discount_amount');
            $table->unsignedInteger('points_redeemed')->default(0)->after('points_earned');
            $table->timestamp('loyalty_processed_at')->nullable()->after('delivered_at');
        });

        Schema::create('loyalty_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->foreignId('order_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type'); // earn, redeem, adjust, refund
            $table->integer('points');
            $table->unsignedInteger('balance_after');
            $table->string('description')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['customer_id', 'created_at']);
            $table->index(['type', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loyalty_transactions');

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn([
                'points_to_redeem',
                'points_discount_amount',
                'points_earned',
                'points_redeemed',
                'loyalty_processed_at',
            ]);
        });

        Schema::table('customers', function (Blueprint $table) {
            $table->dropColumn([
                'loyalty_points',
                'loyalty_points_earned',
                'loyalty_points_redeemed',
            ]);
        });
    }
};
