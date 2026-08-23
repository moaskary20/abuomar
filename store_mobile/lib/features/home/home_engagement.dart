import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/catalog_store.dart';
import '../../models/store_models.dart';
import '../../widgets/store_network_image.dart';
import 'product_search_screen.dart';

class HomeGreetingSection extends StatelessWidget {
  const HomeGreetingSection({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'نهارك سعيد';
    return 'مساء الخير';
  }

  String _firstName(String? full) {
    final name = full?.trim() ?? '';
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final name = _firstName(auth.user?.name);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name.isEmpty ? _greeting() : '${_greeting()}، $name',
            style: AppFonts.tajawal(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.cocoa,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'عاوز تاكل حلو إيه النهارده ؟',
            style: AppFonts.tajawal(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 12),
          _SearchBar(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductSearchScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class HomeEngagementSection extends StatelessWidget {
  const HomeEngagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: _ReorderCard(),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cocoa.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                'ابحث عن كنافة، جاتوه، بقلاوة...',
                style: AppFonts.tajawal(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderCard extends StatelessWidget {
  const _ReorderCard();

  Future<void> _reorder(BuildContext context, StoreOrder order) async {
    final catalog = context.read<CatalogStore>();
    final cart = context.read<CartController>();
    var added = 0;
    for (final line in order.items) {
      final product = catalog.byId(line.productId);
      if (product == null) continue;
      cart.add(product, quantity: line.quantity);
      added++;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'تعذر إيجاد منتجات هذا الطلب حالياً'
              : 'تمت إضافة $added منتجاً من طلبك السابق إلى السلة',
          style: AppFonts.tajawal(),
        ),
      ),
    );
    if (added > 0) {
      context.read<ShellTabController>().openCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isLoggedIn) return const SizedBox.shrink();

    final order = context.watch<OrdersController>().latestReorderable;
    if (order == null) return const SizedBox.shrink();

    final preview = order.items.take(3).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اطلب مرة أخرى',
              style: AppFonts.tajawal(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppTheme.cocoa,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'طلب ${order.orderNumber} · ${order.statusLabelAr}',
              style: AppFonts.tajawal(
                color: AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ...preview.map(
                  (line) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: StoreNetworkImage(imageUrl: line.imageUrl),
                      ),
                    ),
                  ),
                ),
                if (order.items.length > 3)
                  Text(
                    '+${order.items.length - 3}',
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.muted,
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () => _reorder(context, order),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'أضف للسلة',
                    style: AppFonts.tajawal(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
