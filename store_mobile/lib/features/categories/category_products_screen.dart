import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/catalog_store.dart';
import '../../models/store_models.dart';
import '../../widgets/store_cards.dart';
import '../home/product_details_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogStore>();
    final categories = catalog.categories;

    if (catalog.loading && categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!catalog.loading && categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(catalog.error ?? 'لا توجد تصنيفات حالياً'),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => catalog.load(force: true),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryProductsScreen(category: category),
              ),
            );
          },
        );
      },
    );
  }
}

class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final products = context.watch<CatalogStore>().byCategory(category.id);

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: products.isEmpty
          ? const Center(child: Text('لا توجد منتجات في هذا التصنيف حالياً'))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
