import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/brand_hero_panel.dart';
import '../../data/app_state.dart';
import '../../data/settings_controller.dart';
import '../../models/store_models.dart';
import '../../widgets/cart_animation.dart';
import '../../widgets/store_network_image.dart';
import '../home/product_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  final Map<int, GlobalKey> _addKeys = {};

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FavoritesController>().load();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int id) => _addKeys.putIfAbsent(id, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final cart = context.read<CartController>();
    final reduceMotion = context.watch<SettingsController>().reduceMotion;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      body: favorites.isEmpty
          ? SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _FavoritesTopBar(
                      count: 0,
                      showBack: canPop,
                      onBack: () => Navigator.of(context).maybePop(),
                      onClear: null,
                    ),
                  ),
                  const Expanded(child: _EmptyFavorites3D()),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        children: [
                          _FavoritesTopBar(
                            count: favorites.count,
                            showBack: canPop,
                            onBack: () => Navigator.of(context).maybePop(),
                            onClear: () {
                              HapticFeedback.mediumImpact();
                              favorites.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم تفريغ المفضلة',
                                    style: AppFonts.tajawal(),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _FavoritesHero3D(
                            count: favorites.count,
                            reduceMotion: reduceMotion,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = favorites.items[index];
                        final card = _FavoriteCard3D(
                          product: product,
                          addKey: _keyFor(product.id),
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailsScreen(product: product),
                              ),
                            );
                          },
                          onRemove: () {
                            HapticFeedback.lightImpact();
                            favorites.remove(product.id);
                          },
                          onAddToCart: () async {
                            HapticFeedback.selectionClick();
                            cart.add(product);
                            await CartAnimation.play(
                              context: context,
                              buttonKey: _keyFor(product.id),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تمت إضافة ${product.name} إلى السلة',
                                  style: AppFonts.tajawal(),
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );

                        if (reduceMotion) {
                          return card;
                        }

                        final start = (0.08 + index * 0.06).clamp(0.0, 0.72);
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
                            child: card,
                          ),
                        );
                      },
                      childCount: favorites.items.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FavoritesTopBar extends StatelessWidget {
  const _FavoritesTopBar({
    required this.count,
    required this.showBack,
    required this.onBack,
    required this.onClear,
  });

  final int count;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack) ...[
          _RoundIcon3D(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المفضلة',
                style: AppFonts.tajawal(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.cocoa,
                ),
              ),
              Text(
                count == 0
                    ? 'احفظ ما تحبه بضغطة قلب'
                    : '$count منتج محفوظ',
                style: AppFonts.tajawal(
                  color: AppTheme.muted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: Text(
              'تفريغ',
              style: AppFonts.tajawal(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundIcon3D extends StatefulWidget {
  const _RoundIcon3D({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_RoundIcon3D> createState() => _RoundIcon3DState();
}

class _RoundIcon3DState extends State<_RoundIcon3D> {
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
        child: Icon(widget.icon, size: 16, color: AppTheme.cocoa),
      ),
    );
  }
}

class _FavoritesHero3D extends StatelessWidget {
  const _FavoritesHero3D({
    required this.count,
    required this.reduceMotion,
  });

  final int count;
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
                      ..rotateX(-0.28)
                      ..rotateY(0.32),
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
                        Icons.favorite_rounded,
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
                          'قائمة المفضلة',
                          style: AppFonts.tajawal(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'منتجاتك المحفوظة للطلب لاحقاً',
                          style: AppFonts.tajawal(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: AppFonts.tajawal(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'منتج',
                          style: AppFonts.tajawal(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

class _EmptyFavorites3D extends StatelessWidget {
  const _EmptyFavorites3D();

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
                      Icons.favorite_border_rounded,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'المفضلة فارغة',
                  style: AppFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على علامة القلب في المنتجات لحفظها هنا',
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

class _FavoriteCard3D extends StatefulWidget {
  const _FavoriteCard3D({
    required this.product,
    required this.addKey,
    required this.onOpen,
    required this.onRemove,
    required this.onAddToCart,
  });

  final Product product;
  final GlobalKey addKey;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  @override
  State<_FavoriteCard3D> createState() => _FavoriteCard3DState();
}

class _FavoriteCard3DState extends State<_FavoriteCard3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onOpen();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(_pressed ? 0.01 : -0.04)
          ..rotateY(_pressed ? 0 : 0.02)
          ..translateByDouble(0, _pressed ? 4 : 0, 0, 1),
        transformAlignment: Alignment.center,
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
              color: AppTheme.primary.withValues(alpha: _pressed ? 0.1 : 0.2),
              blurRadius: _pressed ? 10 : 18,
              offset: Offset(0, _pressed ? 5 : 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    StoreNetworkImage(imageUrl: product.imageUrl),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: widget.onRemove,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (product.hasDiscount)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${product.discountPercent}%',
                            style: AppFonts.tajawal(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.tajawal(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${product.price.toStringAsFixed(0)} ${AppConfig.currency}',
                            style: AppFonts.tajawal(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Material(
                          key: widget.addKey,
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: widget.onAddToCart,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
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
