import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/settings_controller.dart';
import '../../widgets/brand_hero_panel.dart';
import '../../widgets/store_network_image.dart';
import '../auth/login_screen.dart';
import '../checkout/checkout_confirm_screen.dart';
import '../../widgets/orders_gate.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  final _couponController = TextEditingController();
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final loyalty = context.read<LoyaltyController>();
    final auth = context.watch<AuthController>();
    final reduceMotion = context.watch<SettingsController>().reduceMotion;

    if (cart.items.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFFFF6F1),
        child: _EmptyCart3D(),
      );
    }

    return ColoredBox(
      color: const Color(0xFFFFF6F1),
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _CartHero3D(
                      itemCount: cart.totalQuantity,
                      total: cart.payableTotal,
                      discount: cart.discountAmount,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  sliver: SliverList.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final card = _CartItemCard3D(
                        name: item.product.name,
                        imageUrl: item.product.imageUrl,
                        unitPrice: item.product.price,
                        quantity: item.quantity,
                        lineTotal: item.lineTotal,
                        onInc: () {
                          HapticFeedback.selectionClick();
                          cart.updateQuantity(
                            item.product.id,
                            item.quantity + 1,
                          );
                        },
                        onDec: () {
                          HapticFeedback.selectionClick();
                          cart.updateQuantity(
                            item.product.id,
                            item.quantity - 1,
                          );
                        },
                        onRemove: () {
                          HapticFeedback.lightImpact();
                          cart.remove(item.product.id);
                        },
                      );

                      if (reduceMotion) {
                        return card;
                      }

                      final start = (0.08 + index * 0.07).clamp(0.0, 0.7);
                      final end = (start + 0.28).clamp(0.0, 1.0);
                      final curved = CurvedAnimation(
                        parent: _enter,
                        curve: Interval(start, end, curve: Curves.easeOutCubic),
                      );

                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(curved),
                          child: card,
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
            ),
          ),
          _CheckoutPanel3D(
            couponController: _couponController,
            cart: cart,
            loyaltyHint: auth.isLoggedIn
                ? 'ستكسب ${loyalty.earnableFromOrder(cart.payableTotal)} نقطة ولاء'
                : null,
            onCheckout: () async {
              if (!auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'سجّل الدخول لإتمام الطلب',
                      style: AppFonts.tajawal(),
                    ),
                  ),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                return;
              }

              final allowed = await ensureOrdersEnabled(context);
              if (!allowed || !context.mounted) {
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CheckoutConfirmScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyCart3D extends StatelessWidget {
  const _EmptyCart3D();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-0.06)
            ..rotateY(0.04),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFFF4EF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(-0.25)
                    ..rotateY(0.35),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.18),
                          AppTheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'السلة فارغة',
                  style: AppFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أضف منتجاتك المفضلة من المتجر لتظهر هنا بتجربة طلب أوضح',
                  textAlign: TextAlign.center,
                  style: AppFonts.tajawal(
                    color: AppTheme.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartHero3D extends StatelessWidget {
  const _CartHero3D({
    required this.itemCount,
    required this.total,
    required this.discount,
    required this.reduceMotion,
  });

  final int itemCount;
  final double total;
  final double discount;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final card = BrandHeroPanel3D(
      applyTilt: false,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(-0.3)
                      ..rotateY(0.35),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سلة التسوق',
                          style: AppFonts.tajawal(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$itemCount منتج · جاهزة للدفع',
                          style: AppFonts.tajawal(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                          ),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'وفّرت ${discount.toStringAsFixed(0)} ${AppConfig.currency}',
                              style: AppFonts.tajawal(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الإجمالي',
                        style: AppFonts.tajawal(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        total.toStringAsFixed(0),
                        style: AppFonts.tajawal(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        AppConfig.currency,
                        style: AppFonts.tajawal(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );

    if (reduceMotion) {
      return card;
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.00115)
        ..rotateX(-0.045)
        ..rotateY(0.025),
      child: card,
    );
  }
}

class _CartItemCard3D extends StatefulWidget {
  const _CartItemCard3D({
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
  });

  final String name;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;

  @override
  State<_CartItemCard3D> createState() => _CartItemCard3DState();
}

class _CartItemCard3DState extends State<_CartItemCard3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(_pressed ? 0.01 : -0.03)
          ..rotateY(_pressed ? 0 : 0.015)
          ..translateByDouble(0, _pressed ? 3 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF8F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: _pressed ? 0.1 : 0.18),
              blurRadius: _pressed ? 10 : 18,
              offset: Offset(0, _pressed ? 5 : 10),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(0.18)
                ..rotateX(-0.08),
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: StoreNetworkImage(imageUrl: widget.imageUrl),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.unitPrice.toStringAsFixed(0)} ${AppConfig.currency} للقطعة',
                    style: AppFonts.tajawal(
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QtyChip3D(
                        icon: Icons.remove_rounded,
                        onTap: widget.onDec,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${widget.quantity}',
                          style: AppFonts.tajawal(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _QtyChip3D(
                        icon: Icons.add_rounded,
                        onTap: widget.onInc,
                      ),
                      const Spacer(),
                      Text(
                        '${widget.lineTotal.toStringAsFixed(0)} ${AppConfig.currency}',
                        style: AppFonts.tajawal(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: widget.onRemove,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyChip3D extends StatelessWidget {
  const _QtyChip3D({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(11),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
      ),
    );
  }
}

class _CheckoutPanel3D extends StatelessWidget {
  const _CheckoutPanel3D({
    required this.couponController,
    required this.cart,
    required this.onCheckout,
    this.loyaltyHint,
  });

  final TextEditingController couponController;
  final CartController cart;
  final VoidCallback onCheckout;
  final String? loyaltyHint;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0008)
        ..rotateX(0.02),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoa.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CouponField3D(controller: couponController, cart: cart),
              const SizedBox(height: 12),
              _SummaryRow3D(
                label: 'المجموع الفرعي',
                value: '${cart.subtotal.toStringAsFixed(0)} ${AppConfig.currency}',
              ),
              if (cart.discountAmount > 0)
                _SummaryRow3D(
                  label:
                      'خصم الكوبون${cart.appliedCoupon != null ? ' (${cart.appliedCoupon!.code})' : ''}',
                  value:
                      '-${cart.discountAmount.toStringAsFixed(0)} ${AppConfig.currency}',
                  valueColor: const Color(0xFF276749),
                ),
              _SummaryRow3D(
                label: 'الشحن',
                value:
                    '${cart.shippingAmount.toStringAsFixed(0)} ${AppConfig.currency}',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.1),
                      AppTheme.primary.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'الإجمالي',
                      style: AppFonts.tajawal(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${cart.payableTotal.toStringAsFixed(0)} ${AppConfig.currency}',
                      style: AppFonts.tajawal(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              if (loyaltyHint != null) ...[
                const SizedBox(height: 8),
                Text(
                  loyaltyHint!,
                  style: AppFonts.tajawal(
                    color: AppTheme.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateX(-0.06),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onCheckout,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'إتمام الطلب',
                      style: AppFonts.tajawal(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponField3D extends StatelessWidget {
  const _CouponField3D({
    required this.controller,
    required this.cart,
  });

  final TextEditingController controller;
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    final applied = cart.appliedCoupon;
    final message = cart.couponMessage;
    final success = applied != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'كوبون الخصم',
          style: AppFonts.tajawal(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                style: AppFonts.tajawal(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'مثال: WELCOME10',
                  hintStyle: AppFonts.tajawal(color: AppTheme.muted),
                  filled: true,
                  fillColor: const Color(0xFFFFF6F1),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppTheme.cocoa.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppTheme.cocoa.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.4,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.local_offer_outlined,
                    color: AppTheme.primary,
                  ),
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),
            const SizedBox(width: 8),
            if (applied != null)
              IconButton.filledTonal(
                onPressed: () {
                  cart.removeCoupon();
                  controller.clear();
                },
                tooltip: 'إزالة الكوبون',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primary,
                ),
                icon: const Icon(Icons.close_rounded),
              )
            else
              FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'تطبيق',
                  style: AppFonts.tajawal(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: AppFonts.tajawal(
              color: success ? const Color(0xFF276749) : AppTheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _apply() async {
    final error = await cart.applyCouponCode(controller.text);
    if (error == null && cart.appliedCoupon != null) {
      controller.text = cart.appliedCoupon!.code;
    }
  }
}

class _SummaryRow3D extends StatelessWidget {
  const _SummaryRow3D({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: AppFonts.tajawal(
              color: AppTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppFonts.tajawal(
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppTheme.cocoa,
            ),
          ),
        ],
      ),
    );
  }
}
