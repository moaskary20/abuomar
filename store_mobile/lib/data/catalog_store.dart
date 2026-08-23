import 'package:flutter/foundation.dart' hide Category;

import '../models/store_models.dart';
import 'api_client.dart';

/// كتالوج المتجر من قاعدة البيانات عبر API
class CatalogStore extends ChangeNotifier {
  CatalogStore() {
    load();
  }

  final ApiClient _api = ApiClient.instance;

  List<HomeBanner> banners = [];
  List<Category> categories = [];
  List<Product> products = [];
  List<StorePaymentMethod> paymentMethods = [];
  List<ShippingOption> shippingMethods = [];

  bool loading = false;
  bool loaded = false;
  String? error;

  List<Product> get featured {
    final marked =
        products.where((p) => p.isFeatured).toList(growable: false);
    if (marked.isNotEmpty) {
      return marked;
    }
    return products.take(12).toList(growable: false);
  }

  List<Product> byCategory(int id) =>
      products.where((p) => p.categoryId == id).toList(growable: false);

  Product? byId(int id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Product> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.shortDescription?.toLowerCase().contains(q) ?? false) ||
          (p.categoryName?.toLowerCase().contains(q) ?? false);
    }).toList(growable: false);
  }

  StorePaymentMethod get defaultPaymentMethod {
    for (final m in paymentMethods) {
      if (m.isDefault && m.isActive) return m;
    }
    final active = paymentMethods.where((m) => m.isActive);
    return active.isNotEmpty
        ? active.first
        : const StorePaymentMethod(
            id: 0,
            code: 'cod',
            name: 'الدفع عند التوصيل',
            isDefault: true,
          );
  }

  List<StorePaymentMethod> get activePaymentMethods =>
      paymentMethods.where((m) => m.isActive).toList(growable: false);

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (loaded && !force) return;

    loading = true;
    error = null;
    notifyListeners();

    try {
      if (force) {
        _api.resetBase();
      }
      await _api.ensureBase();
      final results = await Future.wait([
        _safeGet('/api/banners'),
        _safeGet('/api/categories'),
        _safeGet('/api/products'),
        _safeGet('/api/payment-methods'),
        _safeGet('/api/shipping-methods'),
      ]);

      if (results[0] != null) {
        banners = _mapList(results[0], HomeBanner.fromJson);
      }
      if (results[1] != null) {
        categories = _mapList(results[1], Category.fromJson);
      }
      if (results[2] != null) {
        products = _mapList(results[2], Product.fromJson);
      }
      if (results[3] != null) {
        paymentMethods = _mapList(results[3], StorePaymentMethod.fromJson);
      }
      if (results[4] != null) {
        shippingMethods = _mapList(results[4], ShippingOption.fromJson);
      }

      if (products.isNotEmpty || categories.isNotEmpty) {
        loaded = true;
        error = null;
      } else {
        error = 'تعذر تحميل بيانات المتجر';
      }
    } catch (e, st) {
      error = e is ApiException ? e.message : 'تعذر تحميل بيانات المتجر';
      debugPrint('CatalogStore.load failed: $e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _safeGet(String path) async {
    try {
      return await _api.get(path);
    } catch (e, st) {
      debugPrint('CatalogStore $path failed: $e\n$st');
      return null;
    }
  }

  List<T> _mapList<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final raw = json?['data'];
    if (raw is! List) return [];
    final out = <T>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        out.add(mapper(Map<String, dynamic>.from(item)));
      } catch (e, st) {
        debugPrint('CatalogStore map item failed: $e\n$st');
      }
    }
    return out;
  }
}

class ShippingOption {
  const ShippingOption({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.estimatedDays,
  });

  final int id;
  final String name;
  final double price;
  final String? description;
  final int? estimatedDays;

  factory ShippingOption.fromJson(Map<String, dynamic> json) {
    return ShippingOption(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      price: _asDouble(json['price']) ?? 0,
      description: json['description'] as String?,
      estimatedDays: _asInt(json['estimated_days']),
    );
  }
}

int? _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse('$v');
}

double? _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse('$v');
}
