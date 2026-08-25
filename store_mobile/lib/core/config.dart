class AppConfig {
  AppConfig._();

  /// يمكن تجاوزه عند الحاجة:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.44:8000
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// سيرفر التطبيق الخارجي — كل البيانات تُسحب منه.
  static const String productionApiBaseUrl =
      'https://abouomar.caesar-agency.co.uk';

  static const bool preferBundledMedia = false;

  static String get apiBaseUrl => apiBaseCandidates.first;

  static List<String> get apiBaseCandidates {
    if (_envApiBaseUrl.isNotEmpty) {
      return [_envApiBaseUrl.replaceAll(RegExp(r'/+$'), '')];
    }
    return [productionApiBaseUrl];
  }

  /// Laravel قد يُرجع صور localhost أو نطاق قديم — نحوّلها لعنوان الـ API.
  static String rewriteMediaUrl(String url, String apiBase) {
    final cleaned = url.trim();
    if (cleaned.isEmpty) {
      return cleaned;
    }
    final uri = Uri.tryParse(cleaned);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return cleaned;
    }
    final base = Uri.tryParse(apiBase);
    if (base == null || base.host.isEmpty) {
      return cleaned;
    }
    const rewriteHosts = {
      '127.0.0.1',
      'localhost',
      '10.0.2.2',
      'aboomarpastry.com',
      'www.aboomarpastry.com',
    };
    final shouldRewrite = rewriteHosts.contains(uri.host) ||
        uri.host.startsWith('192.168.') ||
        uri.host == '0.0.0.0';
    if (!shouldRewrite) {
      return cleaned;
    }
    return uri
        .replace(
          scheme: base.scheme.isEmpty ? uri.scheme : base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : (base.scheme == 'https' ? 443 : 80),
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
  static const String privacyPolicyUrl =
      'https://abouomar.caesar-agency.co.uk/privacy-policy';
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
      return rewriteMediaUrl(cleaned, apiBaseUrl);
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
