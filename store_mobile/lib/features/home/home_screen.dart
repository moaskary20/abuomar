import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/catalog_store.dart';
import '../../data/mock_store_data.dart';
import '../../data/notifications_controller.dart';
import '../../models/store_models.dart';
import '../../widgets/cart_animation.dart';
import '../../widgets/store_network_image.dart';
import '../categories/category_products_screen.dart';
import 'home_engagement.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  Category? get _offersCategory {
    for (final c in MockStoreData.categories) {
      if (c.id == 33 || c.name.contains('العروض')) {
        return c;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthController>().isLoggedIn) {
        context.read<NotificationsController>().pollNow();
      }
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _openOffers() {
    final category = _offersCategory;
    if (category == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogStore>();
    final categoriesWithProducts = catalog.categories
        .where((c) => catalog.byCategory(c.id).isNotEmpty)
        .toList(growable: false);
    final offers = _offersCategory;

    if (catalog.loading && !catalog.loaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (!catalog.loading && catalog.products.isEmpty) {
      return _CatalogUnavailable(
        message: catalog.error ?? 'لا توجد منتجات للعرض حالياً',
        onRetry: () => catalog.load(force: true),
      );
    }

    return Stack(
      children: [
        const Positioned.fill(child: _HomeAtmosphere()),
        RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => catalog.load(force: true),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
            SliverToBoxAdapter(
              child: _FadeSlideIn(
                animation: _enter,
                begin: 0,
                child: const HomeGreetingSection(),
              ),
            ),
            SliverToBoxAdapter(
              child: _FadeSlideIn(
                animation: _enter,
                begin: 0.06,
                child: const HomeEngagementSection(),
              ),
            ),
            SliverToBoxAdapter(
              child: _FadeSlideIn(
                animation: _enter,
                begin: 0.1,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(14, 6, 14, 2),
                  child: _HomeBannerSlider(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FadeSlideIn(
                animation: _enter,
                begin: 0.12,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: _HomeSectionHeader(
                    title: 'التصنيفات',
                    subtitle: 'اختر ما تشتهيه',
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FadeSlideIn(
                animation: _enter,
                begin: 0.18,
                child: const _CategoriesCircleSlider(),
              ),
            ),
            SliverToBoxAdapter(
              child: _FadeSlideIn(
                animation: _enter,
                begin: 0.28,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
                  child: _HomeSectionHeader(
                    title: 'منتجات مختارة',
                    subtitle: 'اختيارات اليوم من الفرن',
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FadeSlideIn(
                animation: _enter,
                begin: 0.34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: _HomeProductsTripleSlider(
                    products: catalog.featured,
                  ),
                ),
              ),
            ),
            ...categoriesWithProducts.map(
              (category) => SliverToBoxAdapter(
                child: _CategoryProductsHomeSection(category: category),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
        ),
        if (offers != null)
          Positioned(
            left: 14,
            bottom: 14,
            child: _OffersFloatingBadge3D(
              onTap: _openOffers,
            ),
          ),
      ],
    );
  }
}

class _CatalogUnavailable extends StatelessWidget {
  const _CatalogUnavailable({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 42,
              color: AppTheme.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.cocoa,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onRetry(),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: Text('إعادة المحاولة', style: AppFonts.tajawal()),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAtmosphere extends StatelessWidget {
  const _HomeAtmosphere();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFFFFF1EA),
            AppTheme.cream,
            const Color(0xFFFFF8F3),
            const Color(0xFFFFEDE6).withValues(alpha: 0.9),
          ],
          stops: const [0, 0.28, 0.62, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _Blob(
              size: 220,
              color: AppTheme.primary.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            top: 180,
            right: -90,
            child: _Blob(
              size: 260,
              color: const Color(0xFFE8A07A).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -70,
            child: _Blob(
              size: 200,
              color: AppTheme.primary.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

/// زر عائم ثلاثي الأبعاد متحرك → قسم العروض
class _OffersFloatingBadge3D extends StatefulWidget {
  const _OffersFloatingBadge3D({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_OffersFloatingBadge3D> createState() => _OffersFloatingBadge3DState();
}

class _OffersFloatingBadge3DState extends State<_OffersFloatingBadge3D>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _spin;
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Widget _offersGif() {
    return Image.asset(
      'assit/offers_gift.gif',
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppTheme.primary,
        child: Icon(
          Icons.card_giftcard_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _spin, _pulse]),
      builder: (context, _) {
        final floatY = Tween<double>(begin: -7, end: 7).evaluate(
          CurvedAnimation(parent: _float, curve: Curves.easeInOut),
        );
        final tiltX = Tween<double>(begin: -0.18, end: 0.14).evaluate(
          CurvedAnimation(parent: _spin, curve: Curves.easeInOut),
        );
        final tiltY = Tween<double>(begin: -0.22, end: 0.26).evaluate(
          CurvedAnimation(parent: _spin, curve: Curves.easeInOutSine),
        );
        final scale = Tween<double>(begin: 0.96, end: 1.05).evaluate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
        );
        final glow = Tween<double>(begin: 0.22, end: 0.42).evaluate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
        );

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0022)
              ..rotateX(tiltX + (_pressed ? 0.08 : 0))
              ..rotateY(tiltY)
              ..scaleByDouble(
                _pressed ? 0.92 : scale,
                _pressed ? 0.92 : scale,
                1,
                1,
              ),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) {
                setState(() => _pressed = false);
                widget.onTap();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF8EC),
                          Color(0xFFFFE0B8),
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: glow),
                          blurRadius: 22,
                          spreadRadius: 1,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: ColoredBox(
                        color: const Color(0xFFFFF8EC),
                        child: Transform.scale(
                          scale: 1.15,
                          child: _offersGif(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(-0.12)
                      ..rotateY(0.08),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryDark, AppTheme.primary],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'أحدث العروض',
                        style: AppFonts.tajawal(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({
    required this.animation,
    required this.child,
    this.begin = 0,
  });

  final Animation<double> animation;
  final Widget child;
  final double begin;

  @override
  Widget build(BuildContext context) {
    // لا نبدأ من شفافية صفر — كانت تسبب شاشة بيضاء إذا توقفت الحركة
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        begin.clamp(0.0, 0.7),
        1,
        curve: Curves.easeOutCubic,
      ),
    );

    final opacity = Tween<double>(begin: 0.55, end: 1).animate(curved);

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 4,
          height: subtitle == null ? 22 : 34,
          margin: const EdgeInsetsDirectional.only(end: 10, bottom: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.tajawal(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.cocoa,
                  height: 1.15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppFonts.tajawal(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _HomeDots extends StatelessWidget {
  const _HomeDots({
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active
                ? AppTheme.primary
                : AppTheme.cocoa.withValues(alpha: 0.14),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _HomeBannerSlider extends StatefulWidget {
  const _HomeBannerSlider();

  @override
  State<_HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<_HomeBannerSlider> {
  late final PageController _controller;
  Timer? _autoPlay;
  int _index = 0;
  double _page = 0;

  List<HomeBanner> get _banners => MockStoreData.banners;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _controller.addListener(_onScroll);
    _startAutoPlay();
  }

  void _onScroll() {
    if (!mounted || !_controller.hasClients) return;
    final page = _controller.page;
    if (page == null) return;
    setState(() => _page = page);
  }

  void _startAutoPlay() {
    _autoPlay?.cancel();
    if (_banners.length < 2) return;
    _autoPlay = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openBanner(HomeBanner banner) async {
    if (!banner.hasLink) return;

    if (banner.linkType == 'category') {
      final id = int.tryParse(banner.linkValue ?? '');
      if (id == null) return;
      Category? category;
      for (final c in MockStoreData.categories) {
        if (c.id == id) {
          category = c;
          break;
        }
      }
      if (category == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryProductsScreen(category: category!),
        ),
      );
      return;
    }

    if (banner.linkType == 'product') {
      final id = int.tryParse(banner.linkValue ?? '');
      final product = id == null ? null : MockStoreData.byId(id);
      if (product == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      );
      return;
    }

    if (banner.linkType == 'url') {
      final raw = banner.linkValue;
      if (raw == null || raw.isEmpty) return;
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _build3DPage(HomeBanner banner, int index) {
    final delta = _page - index;
    final abs = delta.abs().clamp(0.0, 1.0);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dir = rtl ? -1.0 : 1.0;

    return Transform(
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0018)
        ..rotateY(dir * delta * 0.95)
        ..rotateX(abs * 0.08)
        ..scaleByDouble(1 - abs * 0.1, 1 - abs * 0.1, 1, 1)
        ..translateByDouble(dir * delta * -12, abs * 8, 0, 1),
      child: Opacity(
        opacity: (1.0 - abs * 0.4).clamp(0.35, 1.0),
        child: GestureDetector(
          onTap: () => _openBanner(banner),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cocoa.withValues(alpha: 0.16 * (1 - abs)),
                  blurRadius: 18,
                  offset: Offset(dir * delta * 6, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(
                color: Colors.white,
                child: StoreNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banners = _banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1122 / 820,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            padEnds: true,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: _build3DPage(banners[index], index),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _HomeDots(count: banners.length, index: _index),
      ],
    );
  }
}

class _CategoriesCircleSlider extends StatefulWidget {
  const _CategoriesCircleSlider();

  @override
  State<_CategoriesCircleSlider> createState() =>
      _CategoriesCircleSliderState();
}

class _CategoriesCircleSliderState extends State<_CategoriesCircleSlider> {
  late final PageController _controller;
  double _page = 0;

  List<Category> get _categories => MockStoreData.categories;

  int get _pageCount =>
      _categories.isEmpty ? 0 : (_categories.length / 3).ceil();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openCategory(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(category: category),
      ),
    );
  }

  List<Category?> _categoriesForPage(int pageIndex) {
    final start = pageIndex * 3;
    return List<Category?>.generate(3, (i) {
      final index = start + i;
      if (index >= _categories.length) return null;
      return _categories[index];
    });
  }

  Widget _categoryItem(Category category) {
    return GestureDetector(
      onTap: () => _openCategory(category),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary,
                  AppTheme.primaryDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: StoreNetworkImage(
                  imageUrl: category.imageUrl,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              category.name.replaceFirst('قسم ', ''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppFonts.tajawal(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                height: 1.2,
                color: AppTheme.cocoa,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pageCount == 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            reverse: true,
            itemCount: _pageCount,
            itemBuilder: (context, pageIndex) {
              final items = _categoriesForPage(pageIndex);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (final category in items)
                      Expanded(
                        child: category == null
                            ? const SizedBox.shrink()
                            : _categoryItem(category),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        _HomeDots(
          count: _pageCount,
          index: _page.round().clamp(0, _pageCount - 1),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _CategoryProductsHomeSection extends StatelessWidget {
  const _CategoryProductsHomeSection({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final products = MockStoreData.byCategory(category.id);
    if (products.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 14, 8),
            child: _HomeSectionHeader(
              title: category.name,
              subtitle: '${products.length} منتج متاح',
              trailing: Material(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CategoryProductsScreen(category: category),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض الكل',
                          style: AppFonts.tajawal(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.rotate(
                          angle: math.pi,
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _HomeProductsTripleSlider(
            products: products,
            autoPlayOffset: Duration(milliseconds: 550 * (category.id % 5)),
          ),
        ],
      ),
    );
  }
}

class _HomeProductsTripleSlider extends StatefulWidget {
  const _HomeProductsTripleSlider({
    required this.products,
    this.autoPlayOffset = Duration.zero,
  });

  final List<Product> products;
  final Duration autoPlayOffset;

  @override
  State<_HomeProductsTripleSlider> createState() =>
      _HomeProductsTripleSliderState();
}

class _HomeProductsTripleSliderState extends State<_HomeProductsTripleSlider> {
  late final PageController _controller;
  Timer? _autoPlay;
  Timer? _startDelay;
  int _index = 0;

  List<Product> get _products => widget.products;

  int get _pageCount {
    final n = _products.length;
    if (n == 0) return 0;
    return (n / 3).ceil();
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.98);
    if (widget.autoPlayOffset == Duration.zero) {
      _startAutoPlay();
    } else {
      _startDelay = Timer(widget.autoPlayOffset, _startAutoPlay);
    }
  }

  @override
  void didUpdateWidget(covariant _HomeProductsTripleSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  void _startAutoPlay() {
    _autoPlay?.cancel();
    if (_pageCount < 2) return;
    _autoPlay = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _pageCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _startDelay?.cancel();
    _autoPlay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(product: product),
      ),
    );
  }

  List<Product> _productsForPage(int page) {
    final start = page * 3;
    final end = (start + 3).clamp(0, _products.length);
    return _products.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    if (products.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          SizedBox(
            height: 278,
            child: PageView.builder(
              controller: _controller,
              itemCount: _pageCount,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, page) {
                final pageProducts = _productsForPage(page);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: i < pageProducts.length
                              ? _HomeProductSlideCard(
                                  product: pageProducts[i],
                                  onTap: () =>
                                      _openProduct(pageProducts[i]),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _HomeDots(count: _pageCount, index: _index),
        ],
      ),
    );
  }
}

class _HomeProductSlideCard extends StatefulWidget {
  const _HomeProductSlideCard({
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  State<_HomeProductSlideCard> createState() => _HomeProductSlideCardState();
}

class _HomeProductSlideCardState extends State<_HomeProductSlideCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final favorites = context.watch<FavoritesController>();
    final cart = context.read<CartController>();
    final isFavorite = favorites.contains(product.id);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFFF3EC),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cocoa.withValues(alpha: _pressed ? 0.06 : 0.1),
                blurRadius: _pressed ? 10 : 18,
                offset: Offset(0, _pressed ? 4 : 10),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 55,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: StoreNetworkImage(imageUrl: product.imageUrl),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryDark],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _CircleAction(
                        icon: isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        onTap: () {
                          final added = favorites.toggle(product);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? 'تمت الإضافة إلى المفضلة'
                                    : 'تمت الإزالة من المفضلة',
                                style: AppFonts.tajawal(),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
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
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryDark],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'خصم',
                            style: AppFonts.tajawal(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: AddToCartButton(
                        onPressed: (buttonKey) async {
                          cart.add(product);
                          await CartAnimation.play(
                            context: context,
                            buttonKey: buttonKey,
                          );
                          if (context.mounted) {
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
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 40,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.tajawal(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          height: 1.25,
                          color: AppTheme.cocoa,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${product.price.toStringAsFixed(0)} ${AppConfig.currency}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.tajawal(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(height: 3),
                        Text(
                          product.comparePrice!.toStringAsFixed(0),
                          style: AppFonts.tajawal(
                            color: AppTheme.muted.withValues(alpha: 0.75),
                            decoration: TextDecoration.lineThrough,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
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

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppTheme.cocoa.withValues(alpha: 0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 15, color: AppTheme.primary),
        ),
      ),
    );
  }
}
