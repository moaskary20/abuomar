import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/catalog_store.dart';
import '../../data/notifications_controller.dart';
import '../../models/store_models.dart';
import '../../widgets/store_network_image.dart';
import '../account/account_screen.dart';
import '../cart/cart_screen.dart';
import '../categories/category_products_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );
  late final List<_TabNavObserver> _observers;
  late final AnimationController _sidebarCtrl;

  static const _titles = [
    'الرئيسية',
    'السلة',
    'التصنيفات',
    'حسابي',
  ];

  static const _roots = <Widget>[
    HomeScreen(),
    CartScreen(),
    CategoriesScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _sidebarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    WidgetsBinding.instance.addObserver(this);
    _observers = List.generate(
      4,
      (_) => _TabNavObserver(() {
        if (mounted) {
          setState(() {});
        }
      }),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sidebarCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationsController>().pollNow();
    }
  }

  TextStyle get _navLabelStyle => AppFonts.tajawal(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      );

  Text _navLabel(String text) => Text(text, style: _navLabelStyle);

  bool _tabCanPop(int index) =>
      _navKeys[index].currentState?.canPop() ?? false;

  void _pushInActiveTab(Route<dynamic> route) {
    final shellTab = context.read<ShellTabController>();
    _navKeys[shellTab.index].currentState?.push(route);
  }

  Future<void> _openSidebar() async {
    await _sidebarCtrl.forward();
  }

  Future<void> _closeSidebar() async {
    await _sidebarCtrl.reverse();
  }

  void _openFavorites() {
    _pushInActiveTab(
      MaterialPageRoute(
        builder: (_) => const FavoritesScreen(),
      ),
    );
  }

  Future<void> _openCategory(Category category) async {
    await _closeSidebar();
    if (!mounted) {
      return;
    }
    _pushInActiveTab(
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(category: category),
      ),
    );
  }

  void _onTabTap(int index) {
    if (_sidebarCtrl.value > 0) {
      _closeSidebar();
    }
    final shellTab = context.read<ShellTabController>();
    if (shellTab.index == index) {
      _navKeys[index].currentState?.popUntil((route) => route.isFirst);
      setState(() {});
      return;
    }
    shellTab.goTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().totalQuantity;
    final favCount = context.watch<FavoritesController>().count;
    final shellTab = context.watch<ShellTabController>();
    final index = shellTab.index;
    final nestedOpen = _tabCanPop(index);
    final size = MediaQuery.sizeOf(context);
    final sidebarWidth = size.width * 0.78;

    final mainScaffold = Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: nestedOpen
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                tooltip: 'التصنيفات',
                onPressed: _openSidebar,
                icon: const Icon(Icons.menu_rounded),
              ),
              title: Text(
                _titles[index],
                style: AppFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.cocoa,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'الإشعارات',
                  onPressed: () {
                    _pushInActiveTab(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: Badge(
                    isLabelVisible:
                        context.watch<NotificationsController>().unreadCount > 0,
                    backgroundColor: AppTheme.primary,
                    label: Text(
                      '${context.watch<NotificationsController>().unreadCount}',
                      style: AppFonts.tajawal(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                ),
                IconButton(
                  tooltip: 'المفضلة',
                  onPressed: _openFavorites,
                  icon: Badge(
                    isLabelVisible: favCount > 0,
                    backgroundColor: AppTheme.primary,
                    label: Text(
                      '$favCount',
                      style: AppFonts.tajawal(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Icon(
                      favCount > 0 ? Icons.favorite_rounded : Icons.favorite_border,
                      color: favCount > 0 ? AppTheme.primary : AppTheme.cocoa,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'السلة',
                  onPressed: () => _onTabTap(1),
                  icon: Badge(
                    isLabelVisible: cartCount > 0,
                    backgroundColor: AppTheme.primary,
                    label: Text(
                      '$cartCount',
                      style: AppFonts.tajawal(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Icon(
                      cartCount > 0
                          ? Icons.shopping_bag_rounded
                          : Icons.shopping_bag_outlined,
                      color: cartCount > 0 ? AppTheme.primary : AppTheme.cocoa,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: IndexedStack(
        index: index,
        children: List.generate(4, (i) {
          return Navigator(
            key: _navKeys[i],
            observers: [_observers[i]],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _roots[i],
              );
            },
          );
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SalomonBottomBar(
            currentIndex: index,
            onTap: _onTabTap,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.muted,
            itemPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home_rounded),
                title: _navLabel('الرئيسية'),
              ),
              SalomonBottomBarItem(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  backgroundColor: AppTheme.primary,
                  label: Text(
                    '$cartCount',
                    style: AppFonts.tajawal(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: cartCount > 0,
                  backgroundColor: AppTheme.primary,
                  label: Text(
                    '$cartCount',
                    style: AppFonts.tajawal(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Icon(Icons.shopping_bag_rounded),
                ),
                title: _navLabel('السلة'),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.grid_view_outlined),
                activeIcon: const Icon(Icons.grid_view_rounded),
                title: _navLabel('التصنيفات'),
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person_rounded),
                title: _navLabel('حسابي'),
              ),
            ],
          ),
        ),
      ),
    );

    return Material(
      color: AppTheme.primaryDark,
      child: AnimatedBuilder(
        animation: _sidebarCtrl,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_sidebarCtrl.value);

          // محتوى التطبيق يتحرك لليسار مع دوران منظوري ثلاثي الأبعاد
          final contentTransform = Matrix4.identity()
            ..setEntry(3, 2, 0.00115)
            ..translateByDouble(-sidebarWidth * 0.72 * t, 20.0 * t, 0, 1)
            ..rotateY(0.55 * t)
            ..scaleByDouble(1 - 0.14 * t, 1 - 0.14 * t, 1, 1);

          return Stack(
            children: [
              // لوحة التصنيفات من اليمين
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: sidebarWidth,
                child: Transform.translate(
                  offset: Offset(sidebarWidth * (1 - t) * 0.35, 0),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: _CategoriesSidebar(
                      onClose: _closeSidebar,
                      onCategoryTap: _openCategory,
                      onOpenAllCategories: () async {
                        await _closeSidebar();
                        if (!mounted) {
                          return;
                        }
                        _onTabTap(2);
                      },
                    ),
                  ),
                ),
              ),
              // المحتوى الرئيسي بتأثير 3D
              Transform(
                alignment: Alignment.centerLeft,
                transform: contentTransform,
                child: GestureDetector(
                  onTap: t > 0.05 ? _closeSidebar : null,
                  child: AbsorbPointer(
                    absorbing: t > 0.05,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28 * t),
                      child: Stack(
                        children: [
                          mainScaffold,
                          if (t > 0.01)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.18 * t),
                                    borderRadius: BorderRadius.circular(28 * t),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.35 * t),
                                        blurRadius: 28,
                                        offset: Offset(-12 * t, 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoriesSidebar extends StatelessWidget {
  const _CategoriesSidebar({
    required this.onClose,
    required this.onCategoryTap,
    required this.onOpenAllCategories,
  });

  final VoidCallback onClose;
  final ValueChanged<Category> onCategoryTap;
  final VoidCallback onOpenAllCategories;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CatalogStore>().categories;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConfig.appNameAr,
                        style: AppFonts.tajawal(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'التصنيفات',
                        style: AppFonts.tajawal(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _SidebarCategoryTile(
                    category: category,
                    onTap: () => onCategoryTap(category),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: onOpenAllCategories,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'عرض كل التصنيفات',
                style: AppFonts.tajawal(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarCategoryTile extends StatelessWidget {
  const _SidebarCategoryTile({
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: StoreNetworkImage(imageUrl: category.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: AppFonts.tajawal(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabNavObserver extends NavigatorObserver {
  _TabNavObserver(this.onChange);

  final VoidCallback onChange;

  void _notify() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _notify();
}
