import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/catalog_store.dart';
import '../../models/store_models.dart';
import '../../widgets/store_network_image.dart';
import 'product_details_screen.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogStore>();
    final results = catalog.search(_query);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          style: AppFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.cocoa,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث عن كنافة، جاتوه، بقلاوة...',
            hintStyle: AppFonts.tajawal(color: AppTheme.muted, fontSize: 14),
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
      body: _query.trim().isEmpty
          ? Center(
              child: Text(
                'اكتب اسم المنتج للبحث',
                style: AppFonts.tajawal(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : results.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد نتائج لـ "$_query"',
                    style: AppFonts.tajawal(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _SearchTile(product: results[index]);
                  },
                ),
    );
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: StoreNetworkImage(imageUrl: product.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.tajawal(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.cocoa,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(0)} ${AppConfig.currency}',
                      style: AppFonts.tajawal(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: () {
                  cart.add(product);
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
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
