import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/api_client.dart';
import '../../data/app_state.dart';
import '../../data/catalog_store.dart';
import '../../models/store_models.dart';
import '../../widgets/brand_hero_panel.dart';
import '../../widgets/celebration_confetti.dart';
import '../auth/login_screen.dart';
import '../orders/orders_screen.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  const CheckoutPaymentScreen({super.key, required this.address});

  final DeliveryAddress address;

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  late String _methodCode;
  final _notesController = TextEditingController();
  bool _submitting = false;

  List<StorePaymentMethod> get _methods => PaymentMethodsCatalog.active;

  @override
  void initState() {
    super.initState();
    _methodCode = PaymentMethodsCatalog.defaultMethod.code;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  IconData _iconFor(StorePaymentMethod method) => switch (method.icon) {
        'credit_card' => Icons.credit_card_rounded,
        'account_balance' => Icons.account_balance_rounded,
        'account_balance_wallet' => Icons.account_balance_wallet_rounded,
        _ => Icons.payments_rounded,
      };

  Future<void> _placeOrder() async {
    if (_submitting) {
      return;
    }

    final cart = context.read<CartController>();
    final auth = context.read<AuthController>();
    final orders = context.read<OrdersController>();
    final loyalty = context.read<LoyaltyController>();
    final catalog = context.read<CatalogStore>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('سجّل الدخول لإتمام الطلب', style: AppFonts.tajawal())),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (cart.items.isEmpty) {
      return;
    }

    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();

    final method = _methods.firstWhere(
      (m) => m.code == _methodCode,
      orElse: () => PaymentMethodsCatalog.defaultMethod,
    );

    final shippingMethods = catalog.shippingMethods;
    final shippingMethodId =
        shippingMethods.isNotEmpty ? shippingMethods.first.id : null;

    try {
      final order = await orders.placeOrder(
        cartItems: List.of(cart.items),
        user: auth.user!,
        shippingAmount: cart.shippingAmount,
        discountAmount: cart.discountAmount,
        couponCode: cart.appliedCoupon?.code,
        paymentMethod: method.code,
        shippingCity: widget.address.city,
        shippingAddress: widget.address.fullAddress,
        shippingMethodId: shippingMethodId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      cart.clear();
      await loyalty.refresh();

      if (!mounted) {
        return;
      }

      HapticFeedback.heavyImpact();

      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        pageBuilder: (ctx, _, _) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                const Positioned.fill(child: ConfettiRain()),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      title: Text(
                        'تم تأكيد طلبك',
                        style: AppFonts.tajawal(fontWeight: FontWeight.w900),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رقم الطلب: ${order.orderNumber}',
                            style: AppFonts.tajawal(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'وسيلة الدفع: ${method.name}',
                            style: AppFonts.tajawal(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'كسبت ${order.pointsEarned} نقطة ولاء',
                            style: AppFonts.tajawal(color: AppTheme.muted),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const OrdersScreen(),
                              ),
                              (route) => route.isFirst,
                            );
                          },
                          child: Text(
                            'طلباتي',
                            style: AppFonts.tajawal(fontWeight: FontWeight.w800),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            context.read<ShellTabController>().openHome();
                          },
                          child: Text(
                            'العودة للمتجر',
                            style: AppFonts.tajawal(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message, style: AppFonts.tajawal())),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إتمام الطلب', style: AppFonts.tajawal())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final selected = _methods.firstWhere(
      (m) => m.code == _methodCode,
      orElse: () => PaymentMethodsCatalog.defaultMethod,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        children: [
                          _TopBar(
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 14),
                          _PaymentHero3D(total: cart.payableTotal),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: Text(
                      'وسيلة الدفع',
                      style: AppFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: _methods.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final method = _methods[index];
                      final active = method.code == _methodCode;
                      return _PaymentMethodCard3D(
                        method: method,
                        icon: _iconFor(method),
                        selected: active,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _methodCode = method.code);
                        },
                      );
                    },
                  ),
                ),
                if (selected.requiresOnline)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC47A1A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'هذه الوسيلة إلكترونية — سيتم تسجيل الطلب الآن وإكمال الدفع لاحقاً عند التفعيل الكامل.',
                          style: AppFonts.tajawal(
                            color: const Color(0xFF9B4D1B),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: Text(
                      'ملاحظات الطلب',
                      style: AppFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(-0.025),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 4,
                          style: AppFonts.tajawal(height: 1.5),
                          decoration: InputDecoration(
                            hintText: 'مثال: اتصل قبل الوصول، اترك الطلب عند البوابة...',
                            hintStyle: AppFonts.tajawal(color: AppTheme.muted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: _MiniSummary(
                      address: widget.address,
                      methodName: selected.name,
                      total: cart.payableTotal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cocoa.withValues(alpha: 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateX(-0.06),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _placeOrder,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _submitting ? 'جاري التأكيد...' : 'تأكيد الطلب والدفع',
                      style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundBack(onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الدفع',
                style: AppFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              Text(
                'اختر وسيلة الدفع وأضف ملاحظاتك',
                style: AppFonts.tajawal(color: AppTheme.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundBack extends StatefulWidget {
  const _RoundBack({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RoundBack> createState() => _RoundBackState();
}

class _RoundBackState extends State<_RoundBack> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoa.withValues(alpha: _pressed ? 0.06 : 0.12),
              blurRadius: _pressed ? 6 : 14,
              offset: Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.cocoa),
      ),
    );
  }
}

class _PaymentHero3D extends StatelessWidget {
  const _PaymentHero3D({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return BrandHeroPanel3D(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const BrandHeroIcon3D(icon: Icons.payments_rounded, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ المستحق',
                  style: AppFonts.tajawal(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(0)} ${AppConfig.currency}',
                  style: AppFonts.tajawal(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard3D extends StatefulWidget {
  const _PaymentMethodCard3D({
    required this.method,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final StorePaymentMethod method;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PaymentMethodCard3D> createState() => _PaymentMethodCard3DState();
}

class _PaymentMethodCard3DState extends State<_PaymentMethodCard3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.method;
    final selected = widget.selected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(_pressed ? 0.01 : -0.035)
          ..rotateY(selected ? 0.02 : 0.01)
          ..translateByDouble(0, _pressed ? 3 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: selected
                ? [AppTheme.primary, AppTheme.primaryDark]
                : const [Colors.white, Color(0xFFFFF8F4)],
          ),
          border: Border.all(
            color: selected ? Colors.white.withValues(alpha: 0.35) : Colors.white,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? AppTheme.primary : AppTheme.cocoa)
                  .withValues(alpha: selected ? 0.35 : 0.1),
              blurRadius: selected ? 18 : 12,
              offset: Offset(0, selected ? 10 : 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppTheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                widget.icon,
                color: selected ? Colors.white : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.name,
                          style: AppFonts.tajawal(
                            color: selected ? Colors.white : AppTheme.cocoa,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (m.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.2)
                                : AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'أساسية',
                            style: AppFonts.tajawal(
                              color: selected ? Colors.white : AppTheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (m.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      m.description!,
                      style: AppFonts.tajawal(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.88)
                            : AppTheme.muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.white : AppTheme.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  const _MiniSummary({
    required this.address,
    required this.methodName,
    required this.total,
  });

  final DeliveryAddress address;
  final String methodName;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: AppTheme.cocoa.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _line('التوصيل إلى', address.label),
          _line('العنوان', address.fullAddress),
          _line('الدفع', methodName),
          const Divider(height: 16),
          _line(
            'الإجمالي',
            '${total.toStringAsFixed(0)} ${AppConfig.currency}',
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _line(String k, String v, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              k,
              style: AppFonts.tajawal(color: AppTheme.muted, fontSize: 12.5),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: AppFonts.tajawal(
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
                color: emphasize ? AppTheme.primary : AppTheme.cocoa,
                fontSize: emphasize ? 16 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
