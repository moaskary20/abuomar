import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/store_models.dart';
import 'api_client.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get lineTotal => product.price * quantity;
}

class CartController extends ChangeNotifier {
  CartController({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;
  final List<CartItem> _items = [];
  StoreCoupon? _appliedCoupon;
  String? _couponMessage;

  static const double defaultShipping = 25;

  List<CartItem> get items => List.unmodifiable(_items);

  StoreCoupon? get appliedCoupon => _appliedCoupon;

  String? get couponMessage => _couponMessage;

  bool get hasCoupon => _appliedCoupon != null;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  /// توافق مع الشاشات القديمة
  double get total => subtotal;

  double get shippingAmount => _items.isEmpty ? 0 : defaultShipping;

  double get discountAmount {
    final coupon = _appliedCoupon;
    if (coupon == null) {
      return 0;
    }
    if (coupon.validateFor(subtotal) != null) {
      return 0;
    }
    return coupon.calculateDiscount(subtotal);
  }

  double get payableTotal {
    final value = subtotal - discountAmount + shippingAmount;
    return value < 0 ? 0 : value;
  }

  void add(Product product, {int quantity = 1}) {
    final qty = quantity < 1 ? 1 : quantity;
    final index = _items.indexWhere((e) => e.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += qty;
    } else {
      _items.add(CartItem(product: product, quantity: qty));
    }
    _revalidateCoupon();
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((e) => e.product.id == productId);
    _revalidateCoupon();
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    final index = _items.indexWhere((e) => e.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      _revalidateCoupon();
      notifyListeners();
    }
  }

  /// يعيد رسالة خطأ أو null عند النجاح
  Future<String?> applyCouponCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      _couponMessage = 'أدخل رمز الكوبون';
      notifyListeners();
      return _couponMessage;
    }

    try {
      final json = await _api.post(
        '/api/coupons/validate',
        body: {
          'code': code,
          'subtotal': subtotal,
        },
      );
      final data = json['data'];
      if (data is! Map<String, dynamic>) {
        _appliedCoupon = null;
        _couponMessage = 'استجابة غير صالحة من الخادم';
        notifyListeners();
        return _couponMessage;
      }

      final coupon = StoreCoupon.fromJson(data);
      final error = coupon.validateFor(subtotal);
      if (error != null) {
        _appliedCoupon = null;
        _couponMessage = error;
        notifyListeners();
        return error;
      }

      _appliedCoupon = coupon;
      _couponMessage = 'تم تطبيق كوبون ${coupon.code} (${coupon.valueLabelAr})';
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _appliedCoupon = null;
      _couponMessage = e.message;
      notifyListeners();
      return e.message;
    } catch (_) {
      _appliedCoupon = null;
      _couponMessage = 'تعذر التحقق من الكوبون';
      notifyListeners();
      return _couponMessage;
    }
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _couponMessage = null;
    notifyListeners();
  }

  void markCouponUsed() {
    _appliedCoupon?.usedCount++;
  }

  void clear() {
    _items.clear();
    _appliedCoupon = null;
    _couponMessage = null;
    notifyListeners();
  }

  void _revalidateCoupon() {
    final coupon = _appliedCoupon;
    if (coupon == null) {
      return;
    }
    final error = coupon.validateFor(subtotal);
    if (error != null) {
      _appliedCoupon = null;
      _couponMessage = error;
    }
  }
}

class CouponCatalog {
  CouponCatalog._();

  /// كوبونات مطابقة للوحة التحكم + أمثلة إضافية للتجربة
  static final List<StoreCoupon> coupons = [
    StoreCoupon(
      id: 1,
      code: 'WELCOME10',
      name: 'خصم ترحيبي 10%',
      type: 'percentage',
      value: 10,
      minOrderAmount: 100,
      usageLimit: 100,
      usedCount: 0,
      isActive: true,
    ),
    StoreCoupon(
      id: 2,
      code: 'ABOOMAR50',
      name: 'خصم 50 ج.م',
      type: 'fixed',
      value: 50,
      minOrderAmount: 200,
      usageLimit: 50,
      usedCount: 0,
      isActive: true,
    ),
    StoreCoupon(
      id: 3,
      code: 'PASTRY15',
      name: 'خصم 15%',
      type: 'percentage',
      value: 15,
      minOrderAmount: 150,
      maxDiscount: 75,
      usageLimit: 200,
      usedCount: 0,
      isActive: true,
    ),
  ];

  static StoreCoupon? findByCode(String code) {
    final normalized = code.trim().toUpperCase();
    try {
      return coupons.firstWhere((c) => c.code.toUpperCase() == normalized);
    } catch (_) {
      return null;
    }
  }
}

class FavoritesController extends ChangeNotifier {
  FavoritesController({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;
  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);

  int get count => _items.length;

  bool get isEmpty => _items.isEmpty;

  bool get _isAuthed => _api.token != null && _api.token!.isNotEmpty;

  bool contains(int productId) => _items.any((p) => p.id == productId);

  Future<void> load() async {
    if (!_isAuthed) {
      return;
    }
    try {
      final json = await _api.get('/api/favorites', auth: true);
      final raw = json['data'];
      _items
        ..clear()
        ..addAll(
          raw is List
              ? raw
                  .whereType<Map>()
                  .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
              : const <Product>[],
        );
      notifyListeners();
    } catch (e) {
      debugPrint('Favorites load failed: $e');
    }
  }

  /// يعيد `true` إذا أُضيف، و`false` إذا أُزيل
  bool toggle(Product product) {
    final index = _items.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _items.removeAt(index);
      notifyListeners();
      unawaited(_remoteRemove(product.id));
      return false;
    }

    _items.add(product);
    notifyListeners();
    unawaited(_remoteAdd(product.id));
    return true;
  }

  void add(Product product) {
    if (contains(product.id)) {
      return;
    }
    _items.add(product);
    notifyListeners();
    unawaited(_remoteAdd(product.id));
  }

  void remove(int productId) {
    _items.removeWhere((p) => p.id == productId);
    notifyListeners();
    unawaited(_remoteRemove(productId));
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Future<void> _remoteAdd(int productId) async {
    if (!_isAuthed) {
      return;
    }
    try {
      await _api.post(
        '/api/favorites',
        body: {'product_id': productId},
        auth: true,
      );
    } catch (e) {
      debugPrint('Favorite add failed: $e');
    }
  }

  Future<void> _remoteRemove(int productId) async {
    if (!_isAuthed) {
      return;
    }
    try {
      await _api.delete('/api/favorites/$productId', auth: true);
    } catch (e) {
      debugPrint('Favorite remove failed: $e');
    }
  }
}

class OrdersController extends ChangeNotifier {
  OrdersController({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;
  final List<StoreOrder> _orders = [];

  List<StoreOrder> get orders => List.unmodifiable(_orders);

  StoreOrder? findById(int id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  StoreOrder? get latestReorderable {
    final list = _orders
        .where((o) => o.status != 'cancelled' && o.items.isNotEmpty)
        .toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.first;
  }

  List<StoreOrder> byStatus(String? status) {
    if (status == null || status == 'all') {
      return orders;
    }
    return _orders.where((o) => o.status == status).toList(growable: false);
  }

  Future<void> load() async {
    try {
      final json = await _api.get('/api/orders', auth: true);
      final raw = json['data'];
      _orders
        ..clear()
        ..addAll(
          raw is List
              ? raw
                  .whereType<Map>()
                  .map((e) => StoreOrder.fromJson(Map<String, dynamic>.from(e)))
              : const <StoreOrder>[],
        );
      notifyListeners();
    } catch (e) {
      debugPrint('Orders load failed: $e');
    }
  }

  Future<StoreOrder> placeOrder({
    required List<CartItem> cartItems,
    required AuthUser user,
    double shippingAmount = 25,
    double discountAmount = 0,
    String? couponCode,
    String paymentMethod = 'cod',
    String? shippingCity,
    String? shippingAddress,
    String? notes,
    int? shippingMethodId,
    int pointsToRedeem = 0,
  }) async {
    final json = await _api.post(
      '/api/orders',
      auth: true,
      body: {
        'items': cartItems
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'payment_method': paymentMethod,
        'shipping_method_id': ?shippingMethodId,
        if (couponCode != null && couponCode.trim().isNotEmpty)
          'coupon_code': couponCode.trim(),
        'points_to_redeem': pointsToRedeem,
        'customer_name': user.name.trim(),
        'customer_phone': (user.phone ?? '').trim(),
        'customer_email': user.email.trim(),
        'shipping_city': shippingCity ?? 'القاهرة',
        'shipping_address': shippingAddress ?? 'يُحدد عند التواصل',
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    final data = json['data'];
    if (data is! Map) {
      throw ApiException('استجابة غير صالحة من الخادم');
    }

    final order = StoreOrder.fromJson(Map<String, dynamic>.from(data));
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }
}

class LoyaltyTransactionItem {
  const LoyaltyTransactionItem({
    required this.title,
    required this.points,
    required this.createdAt,
    required this.type,
  });

  final String title;
  final int points;
  final DateTime createdAt;
  final String type; // earn | redeem | adjust
}

class LoyaltyController extends ChangeNotifier {
  LoyaltyController({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;
  int _points = 0;
  int _earnedTotal = 0;
  int _redeemedTotal = 0;
  final List<LoyaltyTransactionItem> _history = [];

  static const int minRedeem = 50;
  static const double egpPerPoint = 0.1; // 10 نقاط = 1 ج.م
  static const double pointsPerEgp = 1; // نقطة لكل جنيه

  int get points => _points;
  int get earnedTotal => _earnedTotal;
  int get redeemedTotal => _redeemedTotal;
  List<LoyaltyTransactionItem> get history => List.unmodifiable(_history);

  double get valueInEgp => _points * egpPerPoint;

  int earnableFromOrder(double orderTotal) => orderTotal.floor();

  int discountFromPoints(int amount) =>
      (amount * egpPerPoint).floor();

  Future<void> refresh() async {
    try {
      final json = await _api.get('/api/loyalty', auth: true);
      final data = json['data'];
      if (data is! Map) {
        return;
      }
      final map = Map<String, dynamic>.from(data);
      _points = _asInt(map['points']) ?? 0;
      _earnedTotal = _asInt(map['earned_total']) ?? 0;
      _redeemedTotal = _asInt(map['redeemed_total']) ?? 0;
      final hist = map['history'];
      _history
        ..clear()
        ..addAll(
          hist is List
              ? hist.whereType<Map>().map((e) {
                  final row = Map<String, dynamic>.from(e);
                  return LoyaltyTransactionItem(
                    title: (row['title'] as String?)?.trim() ?? '',
                    points: _asInt(row['points']) ?? 0,
                    createdAt: DateTime.tryParse('${row['created_at'] ?? ''}') ??
                        DateTime.now(),
                    type: (row['type'] as String?)?.trim() ?? 'adjust',
                  );
                })
              : const <LoyaltyTransactionItem>[],
        );
      notifyListeners();
    } catch (e) {
      debugPrint('Loyalty refresh failed: $e');
    }
  }

  void earnFromOrder(double orderTotal, {String? orderNumber}) {
    final gained = earnableFromOrder(orderTotal);
    if (gained <= 0) {
      return;
    }
    _points += gained;
    _earnedTotal += gained;
    _history.insert(
      0,
      LoyaltyTransactionItem(
        title: orderNumber == null
            ? 'كسب نقاط من طلب'
            : 'كسب نقاط من الطلب $orderNumber',
        points: gained,
        createdAt: DateTime.now(),
        type: 'earn',
      ),
    );
    notifyListeners();
  }

  bool redeem(int amount, {String? note}) {
    if (amount < minRedeem || amount > _points) {
      return false;
    }
    _points -= amount;
    _redeemedTotal += amount;
    _history.insert(
      0,
      LoyaltyTransactionItem(
        title: note ?? 'استبدال نقاط',
        points: -amount,
        createdAt: DateTime.now(),
        type: 'redeem',
      ),
    );
    notifyListeners();
    return true;
  }

  void addBonus(int amount, String title) {
    if (amount == 0) {
      return;
    }
    _points += amount;
    if (amount > 0) {
      _earnedTotal += amount;
    } else {
      _redeemedTotal += amount.abs();
    }
    _history.insert(
      0,
      LoyaltyTransactionItem(
        title: title,
        points: amount,
        createdAt: DateTime.now(),
        type: 'adjust',
      ),
    );
    notifyListeners();
  }
}

class AuthUser {
  const AuthUser({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarBytes,
  });

  final int? id;
  final String name;
  final String email;
  final String? phone;
  final Uint8List? avatarBytes;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? ''}'),
      name: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };

  AuthUser copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    Uint8List? avatarBytes,
    bool clearAvatar = false,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
    );
  }
}

/// للتنقل بين تبويبات الشريط السفلي من الشاشات الداخلية
class ShellTabController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void goTo(int index) {
    if (_index == index) {
      return;
    }
    _index = index;
    notifyListeners();
  }

  void openCart() => goTo(1);

  void openHome() => goTo(0);
}

class AuthController extends ChangeNotifier {
  AuthController() {
    _restoreSession();
  }

  AuthUser? _user;
  String? _token;
  bool _loading = false;
  bool _ready = false;

  static const _avatarKeyPrefix = 'abo_omar_avatar_';
  static const _sessionKey = 'abo_omar_auth_session';
  static const _tokenKey = 'abo_omar_auth_token';

  final ApiClient _api = ApiClient.instance;

  AuthUser? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null && (_token?.isNotEmpty ?? false);
  bool get isLoading => _loading;
  bool get isReady => _ready;

  String _avatarStorageKey(AuthUser user) {
    final phone = user.phone?.trim() ?? '';
    if (phone.isNotEmpty) {
      return phone;
    }
    if (user.email.trim().isNotEmpty) {
      return user.email.trim();
    }
    if (user.id != null) {
      return 'id_${user.id}';
    }
    return 'guest';
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final raw = prefs.getString(_sessionKey);

      if (token != null && token.isNotEmpty) {
        _token = token;
        _api.setToken(token);

        if (raw != null && raw.isNotEmpty) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final cached = AuthUser.fromJson(map);
          final avatar = await _loadAvatar(_avatarStorageKey(cached));
          _user = cached.copyWith(avatarBytes: avatar);
        }

        try {
          final me = await _api.get('/api/auth/me', auth: true);
          final userJson = me['user'];
          if (userJson is Map<String, dynamic>) {
            final remote = AuthUser.fromJson(userJson);
            final avatar = await _loadAvatar(_avatarStorageKey(remote));
            _user = remote.copyWith(avatarBytes: avatar);
            await _persistSession();
          }
        } on ApiException catch (e) {
          if (e.statusCode == 401) {
            await _clearLocalSession();
          } else {
            debugPrint('Auth me failed: $e');
          }
        } catch (e) {
          debugPrint('Auth me failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Auth restore failed: $e');
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _user;
    final token = _token;
    if (user == null || token == null || token.isEmpty) {
      await prefs.remove(_sessionKey);
      await prefs.remove(_tokenKey);
      return;
    }
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _clearLocalSession() async {
    _user = null;
    _token = null;
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_tokenKey);
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> json) async {
    final token = (json['token'] as String?)?.trim();
    final userJson = json['user'];
    if (token == null || token.isEmpty || userJson is! Map<String, dynamic>) {
      throw ApiException('استجابة غير صالحة من الخادم');
    }
    final remote = AuthUser.fromJson(userJson);
    final avatar = await _loadAvatar(_avatarStorageKey(remote));
    _token = token;
    _api.setToken(token);
    _user = remote.copyWith(avatarBytes: avatar);
    await _persistSession();
  }

  Future<Uint8List?> _loadAvatar(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('$_avatarKeyPrefix${key.toLowerCase()}');
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistAvatar(String key, Uint8List? bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = '$_avatarKeyPrefix${key.toLowerCase()}';
    if (bytes == null || bytes.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(storageKey, base64Encode(bytes));
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final json = await _api.post(
        '/api/auth/login',
        body: {
          'phone': phone.trim(),
          'password': password,
        },
      );
      await _applyAuthResponse(json);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'password': password,
      };
      final trimmedEmail = email?.trim() ?? '';
      if (trimmedEmail.isNotEmpty) {
        body['email'] = trimmedEmail;
      }
      final json = await _api.post(
        '/api/auth/register',
        body: body,
      );
      await _applyAuthResponse(json);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatar(Uint8List bytes) async {
    if (_user == null) {
      return;
    }
    _user = _user!.copyWith(avatarBytes: bytes);
    notifyListeners();
    await _persistAvatar(_avatarStorageKey(_user!), bytes);
  }

  Future<void> clearAvatar() async {
    if (_user == null) {
      return;
    }
    final key = _avatarStorageKey(_user!);
    _user = _user!.copyWith(clearAvatar: true);
    notifyListeners();
    await _persistAvatar(key, null);
  }

  Future<void> sendPasswordReset(String phone) async {
    _loading = true;
    notifyListeners();
    try {
      await _api.post(
        '/api/auth/forgot-password',
        body: {'phone': phone.trim()},
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await _api.post('/api/auth/logout', auth: true);
      }
    } catch (e) {
      debugPrint('Logout API failed: $e');
    }
    await _clearLocalSession();
    notifyListeners();
  }
}

/// عناوين التوصيل المرتبطة بحساب العميل عبر API
class AddressesController extends ChangeNotifier {
  AddressesController({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;
  String? _ownerKey;
  final List<DeliveryAddress> _items = [];
  bool _loaded = false;

  String? get ownerEmail => _ownerKey;
  bool get isLoaded => _loaded;
  List<DeliveryAddress> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  DeliveryAddress? get defaultAddress {
    for (final a in _items) {
      if (a.isDefault) {
        return a;
      }
    }
    return _items.isEmpty ? null : _items.first;
  }

  String? _userKey(AuthUser? user) {
    if (user == null) {
      return null;
    }
    if (user.id != null) {
      return 'id_${user.id}';
    }
    final phone = user.phone?.trim() ?? '';
    if (phone.isNotEmpty) {
      return phone.toLowerCase();
    }
    final email = user.email.trim().toLowerCase();
    return email.isEmpty ? null : email;
  }

  Future<void> syncUser(AuthUser? user) async {
    final key = _userKey(user);
    if (key == null) {
      _ownerKey = null;
      _items.clear();
      _loaded = true;
      notifyListeners();
      return;
    }

    if (_ownerKey == key && _loaded) {
      return;
    }

    _ownerKey = key;
    await _loadFromApi();
  }

  Future<void> _loadFromApi() async {
    _items.clear();
    try {
      final json = await _api.get('/api/addresses', auth: true);
      final raw = json['data'];
      if (raw is List) {
        _items.addAll(
          raw
              .whereType<Map>()
              .map((e) => DeliveryAddress.fromJson(Map<String, dynamic>.from(e))),
        );
      }
    } catch (e) {
      debugPrint('Addresses load failed: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _reload() async {
    _loaded = false;
    await _loadFromApi();
  }

  Map<String, dynamic> _body(DeliveryAddress address) => {
        'label': address.label,
        'recipient_name': address.recipientName,
        'phone': address.phone,
        'city': address.city,
        'area': address.area,
        'street': address.street,
        'building': address.building,
        'floor': address.floor,
        'apartment': address.apartment,
        'notes': address.notes,
        'is_default': address.isDefault,
      };

  Future<void> add(DeliveryAddress address) async {
    final payload = _body(address);
    if (_items.isEmpty) {
      payload['is_default'] = true;
    }
    await _api.post('/api/addresses', body: payload, auth: true);
    await _reload();
  }

  Future<void> update(DeliveryAddress address) async {
    await _api.put(
      '/api/addresses/${address.id}',
      body: _body(address),
      auth: true,
    );
    await _reload();
  }

  Future<void> remove(int id) async {
    await _api.delete('/api/addresses/$id', auth: true);
    await _reload();
  }

  Future<void> setDefault(int id) async {
    await _api.put(
      '/api/addresses/$id',
      body: {'is_default': true},
      auth: true,
    );
    await _reload();
  }
}


int? _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse('$v');
}
