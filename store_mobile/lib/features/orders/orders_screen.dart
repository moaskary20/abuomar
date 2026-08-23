import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/settings_controller.dart';
import '../../models/store_models.dart';
import '../../widgets/brand_hero_panel.dart';
import '../../widgets/store_network_image.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  String _filter = 'all';
  late final AnimationController _enter;

  static const _filters = <(String, String, IconData)>[
    ('all', 'الكل', Icons.layers_rounded),
    ('pending', 'انتظار', Icons.hourglass_top_rounded),
    ('processing', 'تجهيز', Icons.bakery_dining_rounded),
    ('shipped', 'شحن', Icons.local_shipping_rounded),
    ('delivered', 'تسليم', Icons.verified_rounded),
    ('cancelled', 'ملغي', Icons.cancel_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrdersController>().load();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Color _statusColor(String status) => switch (status) {
        'pending' => const Color(0xFFC47A1A),
        'confirmed' => const Color(0xFF2B6CB0),
        'processing' => const Color(0xFF9B4D1B),
        'shipped' => const Color(0xFF1F7A6E),
        'delivered' => const Color(0xFF2F6B3A),
        'cancelled' => AppTheme.primary,
        _ => AppTheme.muted,
      };

  @override
  Widget build(BuildContext context) {
    final ordersCtrl = context.watch<OrdersController>();
    final reduceMotion = context.watch<SettingsController>().reduceMotion;
    final all = ordersCtrl.orders;
    final filtered = ordersCtrl.byStatus(_filter);
    final dateFormat = DateFormat('d MMM yyyy · HH:mm', 'ar');

    final activeCount = all
        .where((o) => !const {'delivered', 'cancelled'}.contains(o.status))
        .length;
    final deliveredCount = all.where((o) => o.status == 'delivered').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    _OrdersTopBar(
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 14),
                    _OrdersHero3D(
                      totalOrders: all.length,
                      activeOrders: activeCount,
                      deliveredOrders: deliveredCount,
                      reduceMotion: reduceMotion,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final (value, label, icon) = _filters[index];
                          final count = value == 'all'
                              ? all.length
                              : ordersCtrl.byStatus(value).length;
                          return _FilterPill3D(
                            label: label,
                            icon: icon,
                            count: count,
                            selected: _filter == value,
                            accent: value == 'all'
                                ? AppTheme.primary
                                : _statusColor(value),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _filter = value);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyOrders3D(filter: _filter),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final order = filtered[index];
                  final child = _OrderCard3D(
                    order: order,
                    dateLabel: dateFormat.format(order.createdAt),
                    statusColor: _statusColor(order.status),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsScreen(orderId: order.id),
                        ),
                      );
                    },
                  );

                  if (reduceMotion) {
                    return child;
                  }

                  final start = (0.08 + index * 0.07).clamp(0.0, 0.72);
                  final end = (start + 0.28).clamp(0.0, 1.0);
                  final curved = CurvedAnimation(
                    parent: _enter,
                    curve: Interval(start, end, curve: Curves.easeOutCubic),
                  );

                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OrdersTopBar extends StatelessWidget {
  const _OrdersTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton3D(
          icon: Icons.arrow_forward_ios_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'طلباتي',
                style: AppFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.cocoa,
                ),
              ),
              Text(
                'تتبع كل طلب بلمسة ثلاثية الأبعاد',
                style: AppFonts.tajawal(
                  color: AppTheme.muted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton3D extends StatefulWidget {
  const _RoundIconButton3D({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_RoundIconButton3D> createState() => _RoundIconButton3DState();
}

class _RoundIconButton3DState extends State<_RoundIconButton3D> {
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
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoa.withValues(alpha: _pressed ? 0.06 : 0.12),
              blurRadius: _pressed ? 6 : 14,
              offset: Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        child: Icon(widget.icon, size: 16, color: AppTheme.cocoa),
      ),
    );
  }
}

class _OrdersHero3D extends StatelessWidget {
  const _OrdersHero3D({
    required this.totalOrders,
    required this.activeOrders,
    required this.deliveredOrders,
    required this.reduceMotion,
  });

  final int totalOrders;
  final int activeOrders;
  final int deliveredOrders;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final card = BrandHeroPanel3D(
      applyTilt: false,
      borderRadius: 28,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandHeroIcon3D(icon: Icons.receipt_long_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة الطلبات',
                      style: AppFonts.tajawal(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ملخص سريع لحالة طلباتك الحالية',
                      style: AppFonts.tajawal(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'الإجمالي',
                  value: '$totalOrders',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStat(
                  label: 'نشطة',
                  value: '$activeOrders',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStat(
                  label: 'مُسلَّمة',
                  value: '$deliveredOrders',
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
        ..rotateX(-0.05)
        ..rotateY(0.03),
      child: card,
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.tajawal(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.tajawal(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill3D extends StatefulWidget {
  const _FilterPill3D({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_FilterPill3D> createState() => _FilterPill3DState();
}

class _FilterPill3DState extends State<_FilterPill3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 92,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateX(_pressed ? 0.04 : -0.08)
          ..translateByDouble(0, _pressed ? 3 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: selected
                ? [
                    widget.accent,
                    Color.lerp(widget.accent, Colors.black, 0.18)!,
                  ]
                : const [Colors.white, Color(0xFFFFF3EC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? widget.accent : AppTheme.cocoa)
                  .withValues(alpha: selected ? 0.35 : 0.1),
              blurRadius: selected ? 16 : 10,
              offset: Offset(0, selected ? 10 : 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 18,
              color: selected ? Colors.white : widget.accent,
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.tajawal(
                color: selected ? Colors.white : AppTheme.cocoa,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            Text(
              '${widget.count}',
              style: AppFonts.tajawal(
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders3D extends StatelessWidget {
  const _EmptyOrders3D({required this.filter});

  final String filter;

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
                    width: 84,
                    height: 84,
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
                      Icons.inventory_2_outlined,
                      size: 38,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  filter == 'all'
                      ? 'لا توجد طلبات بعد'
                      : 'لا توجد طلبات بهذه الحالة',
                  style: AppFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'عند إتمام طلب من السلة سيظهر هنا مباشرة بتجربة تتبع أوضح',
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

class _OrderCard3D extends StatefulWidget {
  const _OrderCard3D({
    required this.order,
    required this.dateLabel,
    required this.statusColor,
    required this.onTap,
  });

  final StoreOrder order;
  final String dateLabel;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  State<_OrderCard3D> createState() => _OrderCard3DState();
}

class _OrderCard3DState extends State<_OrderCard3D> {
  bool _pressed = false;

  static const _statusSteps = [
    'pending',
    'processing',
    'shipped',
    'delivered',
  ];

  int get _stepIndex {
    final status = widget.order.status;
    if (status == 'cancelled') {
      return -1;
    }
    if (status == 'confirmed') {
      return 1;
    }
    final i = _statusSteps.indexOf(status);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final images = order.items.take(3).map((e) => e.imageUrl).toList();
    final step = _stepIndex;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(_pressed ? 0.01 : -0.035)
          ..rotateY(_pressed ? 0 : 0.018)
          ..translateByDouble(0, _pressed ? 4 : 0, 0, 1),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF8F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: widget.statusColor.withValues(alpha: _pressed ? 0.12 : 0.22),
              blurRadius: _pressed ? 12 : 22,
              offset: Offset(0, _pressed ? 6 : 14),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                left: -10,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: widget.statusColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StackedThumbs3D(images: images),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.orderNumber,
                                      style: AppFonts.tajawal(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15.5,
                                      ),
                                    ),
                                  ),
                                  _StatusBadge3D(
                                    label: order.statusLabelAr,
                                    color: widget.statusColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.dateLabel,
                                style: AppFonts.tajawal(
                                  color: AppTheme.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${order.itemsCount} منتج · ${order.paymentMethodLabelAr}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.tajawal(
                                  color: AppTheme.cocoa.withValues(alpha: 0.75),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (step >= 0) _OrderProgress3D(activeIndex: step),
                    if (step < 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'تم إلغاء هذا الطلب',
                          style: AppFonts.tajawal(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.cocoa.withValues(alpha: 0.06),
                          ),
                          child: Text(
                            order.paymentStatusLabelAr,
                            style: AppFonts.tajawal(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.cocoa,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${order.total.toStringAsFixed(0)} ${AppConfig.currency}',
                          style: AppFonts.tajawal(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateY(-0.25),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [
                                  widget.statusColor.withValues(alpha: 0.18),
                                  widget.statusColor.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: widget.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackedThumbs3D extends StatelessWidget {
  const _StackedThumbs3D({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(0.25)
          ..rotateX(-0.12),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
          child: const Icon(Icons.cake_outlined, color: AppTheme.primary),
        ),
      );
    }

    final count = math.min(images.length, 3);
    final width = 64.0 + (count - 1) * 14;

    return SizedBox(
      width: width,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              right: i * 14.0,
              top: i * 2.0,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateY(0.18 - i * 0.04)
                  ..rotateX(-0.1),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: StoreNetworkImage(
                      imageUrl: images[i],
                      width: 58,
                      height: 58,
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

class _StatusBadge3D extends StatelessWidget {
  const _StatusBadge3D({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(-0.15)
        ..rotateY(-0.12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              color,
              Color.lerp(color, Colors.black, 0.18)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppFonts.tajawal(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

class _OrderProgress3D extends StatelessWidget {
  const _OrderProgress3D({required this.activeIndex});

  final int activeIndex;

  static const _labels = ['انتظار', 'تجهيز', 'شحن', 'تسليم'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(_labels.length * 2 - 1, (i) {
            if (i.isOdd) {
              final after = i ~/ 2;
              final done = activeIndex > after;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: done
                        ? AppTheme.primary
                        : AppTheme.cocoa.withValues(alpha: 0.1),
                  ),
                ),
              );
            }

            final index = i ~/ 2;
            final active = index <= activeIndex;
            final current = index == activeIndex;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateX(current ? -0.25 : -0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: current ? 18 : 12,
                height: current ? 18 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: active
                      ? const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryDark],
                        )
                      : null,
                  color: active ? null : AppTheme.cocoa.withValues(alpha: 0.12),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                  border: Border.all(
                    color: Colors.white,
                    width: current ? 2 : 1,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_labels.length, (index) {
            final active = index <= activeIndex;
            return Expanded(
              child: Text(
                _labels[index],
                textAlign: TextAlign.center,
                style: AppFonts.tajawal(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? AppTheme.cocoa : AppTheme.muted,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
