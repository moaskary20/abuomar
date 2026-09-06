import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/store_models.dart';
import '../../widgets/cart_animation.dart';
import '../../widgets/orders_gate.dart';
import '../../widgets/store_network_image.dart';
import '../auth/login_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  int _imageIndex = 0;
  final GlobalKey _addButtonKey = GlobalKey();
  late final PageController _pageController;

  Product get product => widget.product;

  List<String> get _images => product.allImages;

  int get _maxQuantity {
    if (!product.trackQuantity) {
      return 99;
    }
    if (product.quantity <= 0) {
      return 1;
    }
    return product.quantity.clamp(1, 99);
  }

  double get _lineTotal => product.price * _quantity;

  bool get _canAdd => product.isInStock;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changeQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, _maxQuantity);
    });
  }

  Future<void> _addToCart({required bool goCheckout}) async {
    if (!_canAdd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هذا المنتج غير متوفر حالياً', style: AppFonts.tajawal()),
        ),
      );
      return;
    }

    final cart = context.read<CartController>();
    final shellTab = context.read<ShellTabController>();
    final auth = context.read<AuthController>();

    cart.add(product, quantity: _quantity);

    if (goCheckout && !auth.isLoggedIn) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سجّل الدخول لإتمام الطلب', style: AppFonts.tajawal()),
        ),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (goCheckout) {
      final allowed = await ensureOrdersEnabled(context);
      if (!allowed || !mounted) {
        return;
      }
    }

    if (!goCheckout) {
      await CartAnimation.play(
        context: context,
        buttonKey: _addButtonKey,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت إضافة $_quantity من ${product.name} إلى السلة',
            style: AppFonts.tajawal(),
          ),
        ),
      );
      return;
    }

    shellTab.openCart();
    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final isFavorite = favorites.contains(product.id);
    final images = _images;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 360,
            backgroundColor: Colors.white,
            title: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  final added = favorites.toggle(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        added ? 'تمت الإضافة إلى المفضلة' : 'تمت الإزالة من المفضلة',
                        style: AppFonts.tajawal(),
                      ),
                    ),
                  );
                },
                icon: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                  color: AppTheme.primary,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (images.isEmpty)
                    const ColoredBox(
                      color: Color(0xFFFFF0EA),
                      child: Icon(Icons.cake_outlined, size: 64, color: AppTheme.primary),
                    )
                  else
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemBuilder: (_, index) {
                        return StoreNetworkImage(imageUrl: images[index]);
                      },
                    ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 56,
                    right: 14,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (product.isFeatured)
                          const _BadgePill(
                            label: 'مميز',
                            color: AppTheme.primary,
                            icon: Icons.star_rounded,
                          ),
                        if (product.hasDiscount)
                          _BadgePill(
                            label: 'خصم ${product.discountPercent}%',
                            color: const Color(0xFFC47A1A),
                            icon: Icons.local_offer_rounded,
                          ),
                        if (product.isLowStock)
                          const _BadgePill(
                            label: 'كمية محدودة',
                            color: Color(0xFF9B4D1B),
                            icon: Icons.inventory_2_outlined,
                          ),
                        if (product.isOutOfStock)
                          const _BadgePill(
                            label: 'غير متوفر',
                            color: AppTheme.muted,
                            icon: Icons.remove_shopping_cart_outlined,
                          ),
                      ],
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          final active = i == _imageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: active
                                  ? AppTheme.primary
                                  : Colors.white.withValues(alpha: 0.75),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (images.length > 1)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  itemCount: images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final selected = index == _imageIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                        setState(() => _imageIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.cocoa.withValues(alpha: 0.1),
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: StoreNetworkImage(imageUrl: images[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.categoryName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.categoryName!,
                        style: AppFonts.tajawal(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    product.name,
                    style: AppFonts.tajawal(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  if (product.shortDescription != null &&
                      product.shortDescription!.trim().isNotEmpty &&
                      product.shortDescription != product.description) ...[
                    const SizedBox(height: 8),
                    Text(
                      product.shortDescription!,
                      style: AppFonts.tajawal(
                        color: AppTheme.muted,
                        height: 1.45,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)} ${AppConfig.currency}',
                        style: AppFonts.tajawal(
                          color: AppTheme.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${product.comparePrice!.toStringAsFixed(0)} ${AppConfig.currency}',
                          style: AppFonts.tajawal(
                            color: AppTheme.muted,
                            fontSize: 15,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '/ ${product.unit}',
                        style: AppFonts.tajawal(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (product.reviews.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = i < product.averageRating.round();
                          return Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 18,
                            color: const Color(0xFFC47A1A),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${product.averageRating.toStringAsFixed(1)} · ${product.reviews.length} تقييم',
                          style: AppFonts.tajawal(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _StockBanner(product: product),
                  const SizedBox(height: 16),
                  _InfoGrid(product: product),
                  if (product.description != null &&
                      product.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'الوصف',
                      child: Text(
                        product.description!,
                        style: AppFonts.tajawal(
                          color: AppTheme.cocoa.withValues(alpha: 0.85),
                          height: 1.65,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'الكمية',
                    child: Row(
                      children: [
                        _QtyControl(
                          icon: Icons.remove_rounded,
                          onTap: _canAdd && _quantity > 1
                              ? () => _changeQuantity(-1)
                              : null,
                        ),
                        Container(
                          width: 64,
                          alignment: Alignment.center,
                          child: Text(
                            '$_quantity',
                            style: AppFonts.tajawal(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _QtyControl(
                          icon: Icons.add_rounded,
                          onTap: _canAdd && _quantity < _maxQuantity
                              ? () => _changeQuantity(1)
                              : null,
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'الإجمالي',
                              style: AppFonts.tajawal(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_lineTotal.toStringAsFixed(0)} ${AppConfig.currency}',
                              style: AppFonts.tajawal(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (product.reviews.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'التقييمات',
                      child: Column(
                        children: [
                          for (var i = 0; i < product.reviews.length; i++) ...[
                            if (i > 0) const Divider(height: 22),
                            _ReviewTile(review: product.reviews[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  key: _addButtonKey,
                  child: FilledButton.icon(
                    onPressed: _canAdd ? () => _addToCart(goCheckout: false) : null,
                    icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                    label: Text(
                      _canAdd ? 'أضف إلى السلة' : 'غير متوفر',
                      style: AppFonts.tajawal(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canAdd ? () => _addToCart(goCheckout: true) : null,
                  icon: const Icon(Icons.payment_outlined, size: 20),
                  label: Text(
                    'إتمام الطلب',
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(
                      color: _canAdd
                          ? AppTheme.primary
                          : AppTheme.muted.withValues(alpha: 0.4),
                      width: 1.4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppFonts.tajawal(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBanner extends StatelessWidget {
  const _StockBanner({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;
    final IconData icon;

    if (!product.trackQuantity) {
      color = const Color(0xFF2F6B3A);
      text = 'متوفر للطلب';
      icon = Icons.check_circle_rounded;
    } else if (product.isOutOfStock) {
      color = AppTheme.primary;
      text = 'نفدت الكمية حالياً';
      icon = Icons.cancel_rounded;
    } else if (product.isLowStock) {
      color = const Color(0xFFC47A1A);
      text = 'متبقي ${product.quantity} ${product.unit} فقط';
      icon = Icons.warning_amber_rounded;
    } else {
      color = const Color(0xFF2F6B3A);
      text = 'متوفر · ${product.quantity} ${product.unit}';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppFonts.tajawal(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      if (product.sku != null && product.sku!.isNotEmpty)
        (Icons.qr_code_2_rounded, 'رمز المنتج', product.sku!),
      if (product.barcode != null && product.barcode!.isNotEmpty)
        (Icons.view_week_rounded, 'الباركود', product.barcode!),
      (Icons.scale_rounded, 'الوحدة', product.unit),
      if (product.weight != null)
        (Icons.monitor_weight_outlined, 'الوزن', '${product.weight} كجم'),
      if (product.categoryName != null)
        (Icons.category_outlined, 'التصنيف', product.categoryName!),
      if (product.isFeatured)
        (Icons.star_rounded, 'العرض', 'منتج مميز'),
    ];

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'تفاصيل من لوحة التحكم',
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 18, color: AppTheme.cocoa.withValues(alpha: 0.08)),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primary.withValues(alpha: 0.08),
                  ),
                  child: Icon(items[i].$1, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i].$2,
                    style: AppFonts.tajawal(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    items[i].$3,
                    textAlign: TextAlign.left,
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cocoa.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cocoa.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              child: Text(
                review.customerName.characters.first,
                style: AppFonts.tajawal(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                review.customerName,
                style: AppFonts.tajawal(fontWeight: FontWeight.w800),
              ),
            ),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14,
                  color: const Color(0xFFC47A1A),
                );
              }),
            ),
          ],
        ),
        if (review.title != null) ...[
          const SizedBox(height: 8),
          Text(
            review.title!,
            style: AppFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 13.5),
          ),
        ],
        if (review.comment != null) ...[
          const SizedBox(height: 4),
          Text(
            review.comment!,
            style: AppFonts.tajawal(
              color: AppTheme.muted,
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? AppTheme.primary.withValues(alpha: 0.12)
          : AppTheme.muted.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppTheme.primary : AppTheme.muted,
          ),
        ),
      ),
    );
  }
}
