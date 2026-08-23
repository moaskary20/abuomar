import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'settings_controller.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final int? orderId;
  bool read;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: '${json['id'] ?? ''}',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      orderId: json['order_id'] is int
          ? json['order_id'] as int
          : int.tryParse('${json['order_id'] ?? ''}'),
      read: json['read'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'order_id': orderId,
        'read': read,
      };
}

/// إشعارات داخل التطبيق + مراقبة تغيّر حالة الطلبات.
class NotificationsController extends ChangeNotifier {
  NotificationsController();

  static const _inboxKey = 'abo_omar_inapp_notifications';
  static const _pollEvery = Duration(seconds: 20);

  AuthController? _auth;
  OrdersController? _orders;
  SettingsController? _settings;

  Timer? _timer;
  bool _polling = false;
  bool _seenReady = false;
  int? _userId;
  Map<int, String> _seen = {};
  final List<AppNotification> _items = [];
  AppNotification? _banner;

  List<AppNotification> get items => List.unmodifiable(_items);
  AppNotification? get banner => _banner;
  int get unreadCount => _items.where((e) => !e.read).length;

  void sync({
    required AuthController auth,
    required OrdersController orders,
    required SettingsController settings,
  }) {
    _auth = auth;
    _orders = orders;
    _settings = settings;
    final id = auth.user?.id;
    if (id != _userId) {
      _userId = id;
      _seen = {};
      _seenReady = false;
    }
    if (auth.isLoggedIn) {
      _ensureTimer();
    } else {
      _stopTimer();
      _banner = null;
    }
  }

  String get _seenKey => 'abo_omar_order_seen_${_userId ?? 0}';

  void _ensureTimer() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(_pollEvery, (_) => unawaited(pollNow()));
    unawaited(pollNow());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> pollNow() async {
    final auth = _auth;
    final orders = _orders;
    if (auth == null || orders == null || !auth.isLoggedIn || _polling) {
      return;
    }
    _polling = true;
    try {
      await _loadSeen();
      await _loadInbox();
      await orders.load();
      _diffStatuses();
    } catch (e) {
      debugPrint('Notifications poll failed: $e');
    } finally {
      _polling = false;
    }
  }

  Future<void> _loadSeen() async {
    if (_seenReady) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_seenKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _seen = {
            for (final e in decoded.entries)
              int.tryParse('${e.key}') ?? 0: '${e.value}',
          }..remove(0);
        }
      }
    } catch (e) {
      debugPrint('Load seen statuses failed: $e');
    }
    _seenReady = true;
  }

  Future<void> _saveSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _seenKey,
        jsonEncode({for (final e in _seen.entries) '${e.key}': e.value}),
      );
    } catch (e) {
      debugPrint('Save seen statuses failed: $e');
    }
  }

  bool _inboxLoaded = false;

  Future<void> _loadInbox() async {
    if (_inboxLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_inboxKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items
            ..clear()
            ..addAll(
              decoded.whereType<Map>().map(
                    (e) => AppNotification.fromJson(Map<String, dynamic>.from(e)),
                  ),
            );
        }
      }
    } catch (e) {
      debugPrint('Load inbox failed: $e');
    }
    _inboxLoaded = true;
    notifyListeners();
  }

  Future<void> _saveInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _inboxKey,
        jsonEncode(_items.take(40).map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Save inbox failed: $e');
    }
  }

  void _diffStatuses() {
    final orders = _orders;
    if (orders == null || !_seenReady) return;

    final current = {for (final o in orders.orders) o.id: o.status};
    if (_seen.isEmpty) {
      _seen = current;
      unawaited(_saveSeen());
      return;
    }

    for (final order in orders.orders) {
      final previous = _seen[order.id];
      if (previous != null && previous != order.status) {
        _pushOrderUpdate(order.orderNumber, order.statusLabelAr, order.id);
      }
    }

    _seen = current;
    unawaited(_saveSeen());
  }

  void _pushOrderUpdate(String orderNumber, String statusLabel, int orderId) {
    final settings = _settings;
    if (settings != null &&
        (!settings.notificationsEnabled || !settings.orderUpdatesNotify)) {
      return;
    }

    final item = AppNotification(
      id: '${orderId}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'تحديث الطلب $orderNumber',
      body: 'حالة طلبك الآن: $statusLabel',
      createdAt: DateTime.now(),
      orderId: orderId,
    );
    _items.insert(0, item);
    if (_items.length > 40) {
      _items.removeRange(40, _items.length);
    }
    _banner = item;
    unawaited(_saveInbox());
    _playFeedback();
    notifyListeners();

    Timer(const Duration(seconds: 6), () {
      if (_banner?.id == item.id) {
        dismissBanner();
      }
    });
  }

  void _playFeedback() {
    final settings = _settings;
    if (settings == null) return;
    if (settings.vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (settings.soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void dismissBanner() {
    if (_banner == null) return;
    _banner = null;
    notifyListeners();
  }

  void markRead(String id) {
    for (final item in _items) {
      if (item.id == id && !item.read) {
        item.read = true;
        unawaited(_saveInbox());
        notifyListeners();
        return;
      }
    }
  }

  void markAllRead() {
    var changed = false;
    for (final item in _items) {
      if (!item.read) {
        item.read = true;
        changed = true;
      }
    }
    if (changed) {
      unawaited(_saveInbox());
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
