import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// يمكن تمريره عند التشغيل أو البناء:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.44:8000
  /// flutter build appbundle --dart-define=API_BASE_URL=https://api.example.com
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// رابط الـ API للإنتاج (HTTPS فقط). غيّره لنطاق السيرفر الفعلي قبل الرفع.
  static const String productionApiBaseUrl = 'https://aboomarpastry.com';

  /// IP جهاز الكمبيوتر على نفس شبكة الموبايل (للتطوير فقط)
  static const String lanHost = '192.168.1.44';
  static const int apiPort = 8000;

  /// استخدم صور السيرفر من قاعدة البيانات (لوحة التحكم)
  static const bool preferBundledMedia = false;

  static String get apiBaseUrl => apiBaseCandidates.first;

  /// جرّب عنوان الشبكة ثم المحاكي ثم localhost حتى يعمل الهاتف والمحاكي.
  static List<String> get apiBaseCandidates {
    if (_envApiBaseUrl.isNotEmpty) {
      return [_envApiBaseUrl];
    }

    final urls = <String>[];
    void add(String url) {
      if (!urls.contains(url)) {
        urls.add(url);
      }
    }

    if (kReleaseMode) {
      add(productionApiBaseUrl);
      return urls;
    }

    if (kIsWeb) {
      add('http://127.0.0.1:$apiPort');
      add('http://localhost:$apiPort');
      return urls;
    }

    add('http://$lanHost:$apiPort');
    if (defaultTargetPlatform == TargetPlatform.android) {
      add('http://10.0.2.2:$apiPort');
    }
    add('http://127.0.0.1:$apiPort');
    return urls;
  }

  /// Laravel غالباً يُرجع صور 127.0.0.1 — نبدّلها بعنوان الـ API الفعلي.
  static String rewriteMediaUrl(String url, String apiBase) {
    final cleaned = url.trim();
    if (cleaned.isEmpty) {
      return cleaned;
    }
    final uri = Uri.tryParse(cleaned);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return cleaned;
    }
    const loopback = {'127.0.0.1', 'localhost'};
    if (!loopback.contains(uri.host)) {
      return cleaned;
    }
    final base = Uri.tryParse(apiBase);
    if (base == null || base.host.isEmpty) {
      return cleaned;
    }
    return uri
        .replace(
          scheme: base.scheme.isEmpty ? uri.scheme : base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : uri.port,
        )
        .toString();
  }

  static const String appName = 'Helwany Abu Omar';
  static const String appNameAr = 'حلوانى ابوعمر';
  static const String currency = 'ج.م';

  static const String storePhone = '15548';
  static const String storeWhatsApp = '01270163333';

  /// رقم واتساب بصيغة دولية لرابط wa.me
  static String get storeWhatsAppIntl {
    final digits = storeWhatsApp.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      return '20${digits.substring(1)}';
    }
    return digits;
  }
  static const String storeEmail = 'info@aboomarpastry.com';
  static const String storeWebsite = 'https://aboomarpastry.com';
  static const String privacyPolicyUrl = '$storeWebsite/privacy.html';
  static const String termsUrl = '$storeWebsite/terms.html';
  static const String storeFacebook =
      'https://www.facebook.com/share/1EgJ8oiL77/?mibextid=wwXIfr';
  static const String storeTikTok =
      'https://www.tiktok.com/@aboomarpastry1?_r=1&_t=ZS-98slTnE7MYu';
  static const String appShareUrl = 'https://aboomarpastry.com';
  static const String appShareMessage =
      'جرّب تطبيق حلوانى ابوعمر — حلويات طازجة من الفرن إلى بابك\n$appShareUrl';

  /// صور المنتجات والتصنيفات
  /// - asset:... للصور المضمّنة
  /// - http... من السيرفر عند تعطيل preferBundledMedia
  static String mediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return '';
    }
    final cleaned = path.trim();
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }
    if (cleaned.startsWith('asset:')) {
      return cleaned;
    }

    final normalized = cleaned.startsWith('/') ? cleaned.substring(1) : cleaned;
    final relative = normalized.startsWith('storage/')
        ? normalized.substring('storage/'.length)
        : normalized;

    // أصول محلية داخل مجلد assit/
    if (relative.startsWith('assit/')) {
      return 'asset:$relative';
    }

    if (preferBundledMedia) {
      return 'asset:assets/store/$relative';
    }

    if (normalized.startsWith('storage/')) {
      return '$apiBaseUrl/$normalized';
    }
    return '$apiBaseUrl/storage/$normalized';
  }
}
