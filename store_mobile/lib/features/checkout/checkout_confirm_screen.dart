import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/brand_hero_panel.dart';
import '../../data/app_state.dart';
import '../../models/store_models.dart';
import '../../widgets/store_network_image.dart';
import '../account/addresses_screen.dart';
import 'checkout_payment_screen.dart';

class CheckoutConfirmScreen extends StatefulWidget {
  const CheckoutConfirmScreen({super.key});

  @override
  State<CheckoutConfirmScreen> createState() => _CheckoutConfirmScreenState();
}

class _CheckoutConfirmScreenState extends State<CheckoutConfirmScreen> {
  DeliveryAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final addresses = context.read<AddressesController>();
      addresses.syncUser(auth.user).then((_) {
        if (!mounted) {
          return;
        }
        setState(() => _selectedAddress = addresses.defaultAddress);
      });
    });
  }

  Future<void> _pickAddress() async {
    final addresses = context.read<AddressesController>().items;
    if (addresses.isEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddressesScreen()),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedAddress = context.read<AddressesController>().defaultAddress;
      });
      return;
    }

    final selected = await showModalBottomSheet<DeliveryAddress>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر عنوان التوصيل',
                style: AppFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              const SizedBox(height: 12),
              ...addresses.map(
                (a) => ListTile(
                  onTap: () => Navigator.pop(ctx, a),
                  leading: Icon(
                    a.isDefault ? Icons.home_rounded : Icons.location_on_outlined,
                    color: AppTheme.primary,
                  ),
                  title: Text(a.label, style: AppFonts.tajawal(fontWeight: FontWeight.w800)),
                  subtitle: Text(a.fullAddress, style: AppFonts.tajawal(fontSize: 12.5)),
                  trailing: _selectedAddress?.id == a.id
                      ? const Icon(Icons.check_circle, color: AppTheme.primary)
                      : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddressesScreen()),
                  );
                },
                child: Text('إدارة العناوين', style: AppFonts.tajawal(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedAddress = selected);
    }
  }

  void _continueToPayment() {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('أضف عنوان توصيل أولاً', style: AppFonts.tajawal()),
          action: SnackBarAction(
            label: 'عناوين',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddressesScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPaymentScreen(address: _selectedAddress!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final loyalty = context.watch<LoyaltyController>();

    if (cart.items.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF6F1),
        body: Center(
          child: Text('السلة فارغة', style: AppFonts.tajawal(fontWeight: FontWeight.w800)),
        ),
      );
    }

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
                          _CheckoutTopBar(
                            title: 'تأكيد الطلب',
                            subtitle: 'راجع البيانات قبل الدفع',
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 14),
                          const _CheckoutHero3D(
                            title: 'مراجعة الطلب',
                            subtitle: 'المنتجات · العنوان · الملخص المالي',
                            icon: Icons.receipt_long_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: _SectionTitle(title: 'عنوان التوصيل'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _AddressConfirmCard3D(
                      address: _selectedAddress,
                      onChange: _pickAddress,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: _SectionTitle(title: 'المنتجات (${cart.totalQuantity})'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _OrderItemCard3D(
                        name: item.product.name,
                        imageUrl: item.product.imageUrl,
                        quantity: item.quantity,
                        lineTotal: item.lineTotal,
                        unitPrice: item.product.price,
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: _SummaryCard3D(
                      subtotal: cart.subtotal,
                      discount: cart.discountAmount,
                      shipping: cart.shippingAmount,
                      total: cart.payableTotal,
                      couponCode: cart.appliedCoupon?.code,
                      loyaltyPoints: loyalty.earnableFromOrder(cart.payableTotal),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _BottomCta3D(
            label: 'متابعة للدفع',
            onPressed: _continueToPayment,
          ),
        ],
      ),
    );
  }
}

class _CheckoutTopBar extends StatelessWidget {
  const _CheckoutTopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
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
                title,
                style: AppFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
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

class _CheckoutHero3D extends StatelessWidget {
  const _CheckoutHero3D({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {

    return BrandHeroPanel3D(
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(-0.28)
                        ..rotateY(0.3),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppFonts.tajawal(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppFonts.tajawal(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }
}

class _AddressConfirmCard3D extends StatelessWidget {
  const _AddressConfirmCard3D({
    required this.address,
    required this.onChange,
  });

  final DeliveryAddress? address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.03)
        ..rotateY(0.015),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF8F4)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 8),
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
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.location_on_rounded, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: address == null
                  ? Text(
                      'لا يوجد عنوان — أضف عنواناً للمتابعة',
                      style: AppFonts.tajawal(fontWeight: FontWeight.w700),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address!.label,
                          style: AppFonts.tajawal(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address!.fullAddress,
                          style: AppFonts.tajawal(
                            color: AppTheme.muted,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
            ),
            TextButton(
              onPressed: onChange,
              child: Text(
                address == null ? 'إضافة' : 'تغيير',
                style: AppFonts.tajawal(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemCard3D extends StatelessWidget {
  const _OrderItemCard3D({
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.lineTotal,
    required this.unitPrice,
  });

  final String name;
  final String imageUrl;
  final int quantity;
  final double lineTotal;
  final double unitPrice;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.025),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoa.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: StoreNetworkImage(imageUrl: imageUrl, width: 64, height: 64),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$quantity × ${unitPrice.toStringAsFixed(0)} ${AppConfig.currency}',
                    style: AppFonts.tajawal(color: AppTheme.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Text(
              '${lineTotal.toStringAsFixed(0)} ${AppConfig.currency}',
              style: AppFonts.tajawal(
                color: AppTheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard3D extends StatelessWidget {
  const _SummaryCard3D({
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.total,
    this.couponCode,
    this.loyaltyPoints,
  });

  final double subtotal;
  final double discount;
  final double shipping;
  final double total;
  final String? couponCode;
  final int? loyaltyPoints;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.03),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF8F4)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _row('المجموع الفرعي', '${subtotal.toStringAsFixed(0)} ${AppConfig.currency}'),
            if (discount > 0)
              _row(
                'خصم${couponCode != null ? ' ($couponCode)' : ''}',
                '-${discount.toStringAsFixed(0)} ${AppConfig.currency}',
                valueColor: const Color(0xFF276749),
              ),
            _row('الشحن', '${shipping.toStringAsFixed(0)} ${AppConfig.currency}'),
            const Divider(height: 20),
            _row(
              'الإجمالي',
              '${total.toStringAsFixed(0)} ${AppConfig.currency}',
              bold: true,
              valueColor: AppTheme.primary,
            ),
            if (loyaltyPoints != null) ...[
              const SizedBox(height: 8),
              Text(
                'ستكسب $loyaltyPoints نقطة ولاء',
                style: AppFonts.tajawal(color: AppTheme.muted, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: AppFonts.tajawal(
              color: bold ? AppTheme.cocoa : AppTheme.muted,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppFonts.tajawal(
              color: valueColor ?? AppTheme.cocoa,
              fontWeight: FontWeight.w900,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCta3D extends StatelessWidget {
  const _BottomCta3D({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                label,
                style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
