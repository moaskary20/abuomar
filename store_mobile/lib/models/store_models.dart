import '../core/config.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String imageUrl;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _jsonInt(json['id']) ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      imageUrl: AppConfig.mediaUrl(json['image_url'] as String?),
    );
  }
}

/// بانر سلايدر الرئيسية — مربوط بجدول banners في لوحة التحكم
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.linkType = 'none',
    this.linkValue,
    this.sortOrder = 0,
  });

  final int id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String linkType; // none | category | product | url
  final String? linkValue;
  final int sortOrder;

  bool get hasLink => linkType != 'none' && (linkValue?.isNotEmpty ?? false);

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: _jsonInt(json['id']) ?? 0,
      imageUrl: AppConfig.mediaUrl(json['image_url'] as String?),
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      linkType: (json['link_type'] as String?) ?? 'none',
      linkValue: json['link_value'] as String?,
      sortOrder: _jsonInt(json['sort_order']) ?? 0,
    );
  }
}

class ProductReview {
  const ProductReview({
    required this.customerName,
    required this.rating,
    this.title,
    this.comment,
  });

  final String customerName;
  final int rating; // 1-5
  final String? title;
  final String? comment;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      customerName: (json['customer_name'] as String?)?.trim() ?? 'عميل',
      rating: _jsonInt(json['rating']) ?? 5,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.imageUrl,
    this.slug,
    this.sku,
    this.barcode,
    this.categoryName,
    this.shortDescription,
    this.description,
    this.comparePrice,
    this.quantity = 0,
    this.lowStockThreshold = 5,
    this.trackQuantity = true,
    this.isFeatured = false,
    this.galleryUrls = const [],
    this.weight,
    this.unit = 'قطعة',
    this.reviews = const [],
  });

  final int id;
  final String name;
  final String? slug;
  final String? sku;
  final String? barcode;
  final int categoryId;
  final String? categoryName;
  final String? shortDescription;
  final String? description;
  final double price;
  final double? comparePrice;
  final int quantity;
  final int lowStockThreshold;
  final bool trackQuantity;
  final bool isFeatured;
  final String imageUrl;
  final List<String> galleryUrls;
  final double? weight;
  final String unit;
  final List<ProductReview> reviews;

  factory Product.fromJson(Map<String, dynamic> json) {
    final reviewsRaw = json['reviews'];
    final reviews = reviewsRaw is List
        ? reviewsRaw
            .whereType<Map>()
            .map((e) => ProductReview.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <ProductReview>[];
    final galleryRaw = json['gallery_urls'];
    final gallery = galleryRaw is List
        ? galleryRaw
            .map((e) => AppConfig.mediaUrl('$e'))
            .where((e) => e.trim().isNotEmpty)
            .toList()
        : const <String>[];

    return Product(
      id: _jsonInt(json['id']) ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      slug: json['slug'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      categoryId: _jsonInt(json['category_id']) ?? 0,
      categoryName: json['category_name'] as String?,
      shortDescription: json['short_description'] as String?,
      description: json['description'] as String?,
      price: _jsonDouble(json['price']) ?? 0,
      comparePrice: _jsonDouble(json['compare_price']),
      quantity: _jsonInt(json['quantity']) ?? 0,
      lowStockThreshold: _jsonInt(json['low_stock_threshold']) ?? 5,
      trackQuantity: _jsonBool(json['track_quantity'], fallback: true),
      isFeatured: _jsonBool(json['is_featured']),
      imageUrl: AppConfig.mediaUrl(json['image_url'] as String?),
      galleryUrls: gallery,
      weight: _jsonDouble(json['weight']),
      unit: (json['unit'] as String?)?.trim().isNotEmpty == true
          ? (json['unit'] as String).trim()
          : 'قطعة',
      reviews: reviews,
    );
  }

  bool get hasDiscount =>
      comparePrice != null && comparePrice! > price;

  int? get discountPercent {
    if (!hasDiscount) {
      return null;
    }
    return (((comparePrice! - price) / comparePrice!) * 100).round();
  }

  /// الصورة الرئيسية + معرض الإدارة
  List<String> get allImages {
    final seen = <String>{};
    final out = <String>[];
    for (final url in [imageUrl, ...galleryUrls]) {
      if (url.trim().isEmpty || seen.contains(url)) {
        continue;
      }
      seen.add(url);
      out.add(url);
    }
    return out;
  }

  bool get isInStock => !trackQuantity || quantity > 0;

  bool get isLowStock =>
      trackQuantity && quantity > 0 && quantity <= lowStockThreshold;

  bool get isOutOfStock => trackQuantity && quantity <= 0;

  double get averageRating {
    if (reviews.isEmpty) {
      return 0;
    }
    final sum = reviews.fold<int>(0, (s, r) => s + r.rating);
    return sum / reviews.length;
  }
}

class StoreCoupon {
  StoreCoupon({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscount,
    this.usageLimit,
    this.usedCount = 0,
    this.startsAt,
    this.expiresAt,
    this.isActive = true,
  });

  final int id;
  final String code;
  final String name;
  final String type; // percentage | fixed
  final double value;
  final double? minOrderAmount;
  final double? maxDiscount;
  final int? usageLimit;
  int usedCount;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final bool isActive;

  String get typeLabelAr =>
      type == 'percentage' ? 'نسبة مئوية' : 'قيمة ثابتة';

  String get valueLabelAr => type == 'percentage'
      ? '${value.toStringAsFixed(0)}%'
      : '${value.toStringAsFixed(0)} ج.م';

  String? validateFor(double subtotal, {DateTime? now}) {
    final at = now ?? DateTime.now();
    if (!isActive) {
      return 'هذا الكوبون غير مفعّل';
    }
    if (startsAt != null && at.isBefore(startsAt!)) {
      return 'هذا الكوبون لم يبدأ بعد';
    }
    if (expiresAt != null && at.isAfter(expiresAt!)) {
      return 'انتهت صلاحية هذا الكوبون';
    }
    if (usageLimit != null && usedCount >= usageLimit!) {
      return 'تم استهلاك حد استخدام هذا الكوبون';
    }
    if (minOrderAmount != null && subtotal < minOrderAmount!) {
      return 'الحد الأدنى للطلب ${minOrderAmount!.toStringAsFixed(0)} ج.م';
    }
    return null;
  }

  double calculateDiscount(double subtotal) {
    if (subtotal <= 0) {
      return 0;
    }
    double discount;
    if (type == 'percentage') {
      discount = subtotal * (value / 100);
    } else {
      discount = value;
    }
    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }
    if (discount > subtotal) {
      discount = subtotal;
    }
    return double.parse(discount.toStringAsFixed(2));
  }

  factory StoreCoupon.fromJson(Map<String, dynamic> json) {
    return StoreCoupon(
      id: _jsonInt(json['id']) ?? 0,
      code: (json['code'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      type: (json['type'] as String?)?.trim() ?? 'fixed',
      value: _jsonDouble(json['value']) ?? 0,
      minOrderAmount: _jsonDouble(json['min_order_amount']),
      maxDiscount: _jsonDouble(json['max_discount']),
      usageLimit: _jsonInt(json['usage_limit']),
      usedCount: _jsonInt(json['used_count']) ?? 0,
      startsAt: DateTime.tryParse('${json['starts_at'] ?? ''}'),
      expiresAt: DateTime.tryParse('${json['expires_at'] ?? ''}'),
      isActive: _jsonBool(json['is_active'], fallback: true),
    );
  }
}

/// وسيلة دفع من لوحة التحكم (payment_methods)
class StorePaymentMethod {
  const StorePaymentMethod({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.icon = 'payments',
    this.sortOrder = 0,
    this.isActive = true,
    this.isDefault = false,
    this.requiresOnline = false,
    this.gateway,
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final String icon;
  final int sortOrder;
  final bool isActive;
  final bool isDefault;
  final bool requiresOnline;
  final Map<String, dynamic>? gateway;

  bool get isFawry => code == 'fawry';

  factory StorePaymentMethod.fromJson(Map<String, dynamic> json) {
    return StorePaymentMethod(
      id: _jsonInt(json['id']) ?? 0,
      code: (json['code'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      description: json['description'] as String?,
      icon: (json['icon'] as String?)?.trim().isNotEmpty == true
          ? (json['icon'] as String).trim()
          : 'payments',
      sortOrder: _jsonInt(json['sort_order']) ?? 0,
      isActive: _jsonBool(json['is_active'], fallback: true),
      isDefault: _jsonBool(json['is_default']),
      requiresOnline: _jsonBool(json['requires_online']),
      gateway: json['gateway'] is Map
          ? Map<String, dynamic>.from(json['gateway'] as Map)
          : null,
    );
  }
}

/// كتالوج وسائل الدفع — يُحدَّث من API
class PaymentMethodsCatalog {
  PaymentMethodsCatalog._();

  static List<StorePaymentMethod> methods = [];

  static void replaceAll(List<StorePaymentMethod> items) {
    methods = List<StorePaymentMethod>.from(items);
  }

  static List<StorePaymentMethod> get active =>
      methods.where((m) => m.isActive).toList(growable: false);

  static StorePaymentMethod get defaultMethod {
    for (final m in active) {
      if (m.isDefault) {
        return m;
      }
    }
    return active.isNotEmpty
        ? active.first
        : const StorePaymentMethod(
            id: 0,
            code: 'cod',
            name: 'الدفع عند التوصيل',
            isDefault: true,
          );
  }

  static String labelFor(String code) {
    for (final m in methods) {
      if (m.code == code) {
        return m.name;
      }
    }
    return switch (code) {
      'cod' => 'الدفع عند التوصيل',
      'card' => 'بطاقة بنكية',
      'transfer' => 'تحويل بنكي',
      'wallet' => 'محفظة إلكترونية',
      _ => code,
    };
  }
}

/// عنوان توصيل مرتبط بحساب العميل (customer_addresses)
class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.city,
    required this.street,
    this.phone,
    this.area,
    this.building,
    this.floor,
    this.apartment,
    this.notes,
    this.isDefault = false,
  });

  final int id;
  final String label;
  final String recipientName;
  final String? phone;
  final String city;
  final String? area;
  final String street;
  final String? building;
  final String? floor;
  final String? apartment;
  final String? notes;
  final bool isDefault;

  String get fullAddress {
    final parts = <String>[
      city,
      if (area != null && area!.trim().isNotEmpty) area!.trim(),
      street,
      if (building != null && building!.trim().isNotEmpty) 'مبنى ${building!.trim()}',
      if (floor != null && floor!.trim().isNotEmpty) 'دور ${floor!.trim()}',
      if (apartment != null && apartment!.trim().isNotEmpty) 'شقة ${apartment!.trim()}',
    ];
    return parts.join(' - ');
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: _jsonInt(json['id']) ?? 0,
      label: (json['label'] as String?)?.trim() ?? 'عنوان',
      recipientName: (json['recipient_name'] as String?)?.trim() ??
          (json['recipientName'] as String?)?.trim() ??
          '',
      phone: json['phone'] as String?,
      city: (json['city'] as String?)?.trim() ?? '',
      area: json['area'] as String?,
      street: (json['street'] as String?)?.trim() ?? '',
      building: json['building'] as String?,
      floor: json['floor'] as String?,
      apartment: json['apartment'] as String?,
      notes: json['notes'] as String?,
      isDefault: _jsonBool(json['is_default'] ?? json['isDefault']),
    );
  }

  DeliveryAddress copyWith({
    int? id,
    String? label,
    String? recipientName,
    String? phone,
    String? city,
    String? area,
    String? street,
    String? building,
    String? floor,
    String? apartment,
    String? notes,
    bool? isDefault,
  }) {
    return DeliveryAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      area: area ?? this.area,
      street: street ?? this.street,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      apartment: apartment ?? this.apartment,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'city': city,
        'area': area,
        'street': street,
        'building': building,
        'floor': floor,
        'apartment': apartment,
        'notes': notes,
        'is_default': isDefault,
      };
}

class OrderLineItem {
  const OrderLineItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  final int productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      productId: _jsonInt(json['product_id']) ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      imageUrl: AppConfig.mediaUrl(json['image_url'] as String?),
      unitPrice: _jsonDouble(json['unit_price']) ?? 0,
      quantity: _jsonInt(json['quantity']) ?? 1,
    );
  }
}

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.shippingAmount,
    required this.discountAmount,
    required this.pointsEarned,
    required this.total,
    required this.createdAt,
    this.shippingCity,
    this.shippingAddress,
    this.notes,
    this.couponCode,
  });

  final int id;
  final String orderNumber;
  final String status; // pending | confirmed | processing | shipped | delivered | cancelled
  final String paymentStatus; // unpaid | paid | partial | refunded
  final String paymentMethod; // cod | card | transfer | wallet
  final List<OrderLineItem> items;
  final double subtotal;
  final double shippingAmount;
  final double discountAmount;
  final int pointsEarned;
  final double total;
  final DateTime createdAt;
  final String? shippingCity;
  final String? shippingAddress;
  final String? notes;
  final String? couponCode;

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusLabelAr => switch (status) {
        'pending' => 'قيد الانتظار',
        'confirmed' => 'مؤكد',
        'processing' => 'قيد التجهيز',
        'shipped' => 'تم الشحن',
        'delivered' => 'تم التسليم',
        'cancelled' => 'ملغي',
        _ => status,
      };

  String get paymentStatusLabelAr => switch (paymentStatus) {
        'unpaid' => 'غير مدفوع',
        'paid' => 'مدفوع',
        'partial' => 'مدفوع جزئياً',
        'refunded' => 'مسترجع',
        _ => paymentStatus,
      };

  String get paymentMethodLabelAr => PaymentMethodsCatalog.labelFor(paymentMethod);

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => OrderLineItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <OrderLineItem>[];
    return StoreOrder(
      id: _jsonInt(json['id']) ?? 0,
      orderNumber: (json['order_number'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      paymentStatus: (json['payment_status'] as String?) ?? 'unpaid',
      paymentMethod: (json['payment_method'] as String?) ?? 'cod',
      items: items,
      subtotal: _jsonDouble(json['subtotal']) ?? 0,
      shippingAmount: _jsonDouble(json['shipping_amount']) ?? 0,
      discountAmount: _jsonDouble(json['discount_amount']) ?? 0,
      pointsEarned: _jsonInt(json['points_earned']) ?? 0,
      total: _jsonDouble(json['total']) ?? 0,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      shippingCity: json['shipping_city'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      notes: json['notes'] as String?,
      couponCode: json['coupon_code'] as String?,
    );
  }
}

bool _jsonBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = '$v'.trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no' || s == 'null' || s == '') {
    return false;
  }
  return fallback;
}

int? _jsonInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse('$v');
}

double? _jsonDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse('$v');
}
