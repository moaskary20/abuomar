import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController() {
    _load();
  }

  static const _prefix = 'abo_omar_settings_';

  bool _loaded = false;
  bool get isLoaded => _loaded;

  // الإشعارات
  bool notificationsEnabled = true;
  bool orderUpdatesNotify = true;
  bool offersNotify = true;
  bool loyaltyNotify = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  // المظهر
  bool darkMode = false;
  double textScale = 1.0; // 0.9 | 1.0 | 1.15
  bool reduceMotion = false;

  // اللغة والعملة
  String languageCode = 'ar';
  String currencyCode = 'EGP';

  // التسوق
  bool keepCartAfterLogout = true;
  bool confirmBeforeCheckout = true;
  bool defaultCodPayment = true;
  bool showOutOfStock = false;
  bool quickAddToCart = true;

  // الخصوصية
  bool personalizedOffers = true;
  bool analyticsEnabled = false;
  bool shareLocationForDelivery = true;
  bool saveSearchHistory = true;

  // الحساب والأمان
  bool biometricLogin = false;
  bool rememberSession = true;
  bool twoStepHints = false;

  // التطبيق
  bool showSplashVideo = true;
  bool autoPlayProductMedia = true;
  bool dataSaver = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool('${_prefix}notifications') ?? true;
    orderUpdatesNotify = prefs.getBool('${_prefix}order_updates') ?? true;
    offersNotify = prefs.getBool('${_prefix}offers') ?? true;
    loyaltyNotify = prefs.getBool('${_prefix}loyalty_notify') ?? true;
    soundEnabled = prefs.getBool('${_prefix}sound') ?? true;
    vibrationEnabled = prefs.getBool('${_prefix}vibration') ?? true;

    darkMode = prefs.getBool('${_prefix}dark_mode') ?? false;
    textScale = prefs.getDouble('${_prefix}text_scale') ?? 1.0;
    reduceMotion = prefs.getBool('${_prefix}reduce_motion') ?? false;

    languageCode = prefs.getString('${_prefix}language') ?? 'ar';
    currencyCode = prefs.getString('${_prefix}currency') ?? 'EGP';

    keepCartAfterLogout = prefs.getBool('${_prefix}keep_cart') ?? true;
    confirmBeforeCheckout = prefs.getBool('${_prefix}confirm_checkout') ?? true;
    defaultCodPayment = prefs.getBool('${_prefix}default_cod') ?? true;
    showOutOfStock = prefs.getBool('${_prefix}show_oos') ?? false;
    quickAddToCart = prefs.getBool('${_prefix}quick_add') ?? true;

    personalizedOffers = prefs.getBool('${_prefix}personalized') ?? true;
    analyticsEnabled = prefs.getBool('${_prefix}analytics') ?? false;
    shareLocationForDelivery = prefs.getBool('${_prefix}share_location') ?? true;
    saveSearchHistory = prefs.getBool('${_prefix}search_history') ?? true;

    biometricLogin = prefs.getBool('${_prefix}biometric') ?? false;
    rememberSession = prefs.getBool('${_prefix}remember_session') ?? true;
    twoStepHints = prefs.getBool('${_prefix}two_step') ?? false;

    showSplashVideo = prefs.getBool('${_prefix}splash_video') ?? true;
    autoPlayProductMedia = prefs.getBool('${_prefix}autoplay_media') ?? true;
    dataSaver = prefs.getBool('${_prefix}data_saver') ?? false;

    _loaded = true;
    notifyListeners();
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
  }

  Future<void> _setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$_prefix$key', value);
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', value);
  }

  Future<void> update({
    bool? notificationsEnabled,
    bool? orderUpdatesNotify,
    bool? offersNotify,
    bool? loyaltyNotify,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? darkMode,
    double? textScale,
    bool? reduceMotion,
    String? languageCode,
    String? currencyCode,
    bool? keepCartAfterLogout,
    bool? confirmBeforeCheckout,
    bool? defaultCodPayment,
    bool? showOutOfStock,
    bool? quickAddToCart,
    bool? personalizedOffers,
    bool? analyticsEnabled,
    bool? shareLocationForDelivery,
    bool? saveSearchHistory,
    bool? biometricLogin,
    bool? rememberSession,
    bool? twoStepHints,
    bool? showSplashVideo,
    bool? autoPlayProductMedia,
    bool? dataSaver,
  }) async {
    if (notificationsEnabled != null) {
      this.notificationsEnabled = notificationsEnabled;
      await _setBool('notifications', notificationsEnabled);
    }
    if (orderUpdatesNotify != null) {
      this.orderUpdatesNotify = orderUpdatesNotify;
      await _setBool('order_updates', orderUpdatesNotify);
    }
    if (offersNotify != null) {
      this.offersNotify = offersNotify;
      await _setBool('offers', offersNotify);
    }
    if (loyaltyNotify != null) {
      this.loyaltyNotify = loyaltyNotify;
      await _setBool('loyalty_notify', loyaltyNotify);
    }
    if (soundEnabled != null) {
      this.soundEnabled = soundEnabled;
      await _setBool('sound', soundEnabled);
    }
    if (vibrationEnabled != null) {
      this.vibrationEnabled = vibrationEnabled;
      await _setBool('vibration', vibrationEnabled);
    }
    if (darkMode != null) {
      this.darkMode = darkMode;
      await _setBool('dark_mode', darkMode);
    }
    if (textScale != null) {
      this.textScale = textScale;
      await _setDouble('text_scale', textScale);
    }
    if (reduceMotion != null) {
      this.reduceMotion = reduceMotion;
      await _setBool('reduce_motion', reduceMotion);
    }
    if (languageCode != null) {
      this.languageCode = languageCode;
      await _setString('language', languageCode);
    }
    if (currencyCode != null) {
      this.currencyCode = currencyCode;
      await _setString('currency', currencyCode);
    }
    if (keepCartAfterLogout != null) {
      this.keepCartAfterLogout = keepCartAfterLogout;
      await _setBool('keep_cart', keepCartAfterLogout);
    }
    if (confirmBeforeCheckout != null) {
      this.confirmBeforeCheckout = confirmBeforeCheckout;
      await _setBool('confirm_checkout', confirmBeforeCheckout);
    }
    if (defaultCodPayment != null) {
      this.defaultCodPayment = defaultCodPayment;
      await _setBool('default_cod', defaultCodPayment);
    }
    if (showOutOfStock != null) {
      this.showOutOfStock = showOutOfStock;
      await _setBool('show_oos', showOutOfStock);
    }
    if (quickAddToCart != null) {
      this.quickAddToCart = quickAddToCart;
      await _setBool('quick_add', quickAddToCart);
    }
    if (personalizedOffers != null) {
      this.personalizedOffers = personalizedOffers;
      await _setBool('personalized', personalizedOffers);
    }
    if (analyticsEnabled != null) {
      this.analyticsEnabled = analyticsEnabled;
      await _setBool('analytics', analyticsEnabled);
    }
    if (shareLocationForDelivery != null) {
      this.shareLocationForDelivery = shareLocationForDelivery;
      await _setBool('share_location', shareLocationForDelivery);
    }
    if (saveSearchHistory != null) {
      this.saveSearchHistory = saveSearchHistory;
      await _setBool('search_history', saveSearchHistory);
    }
    if (biometricLogin != null) {
      this.biometricLogin = biometricLogin;
      await _setBool('biometric', biometricLogin);
    }
    if (rememberSession != null) {
      this.rememberSession = rememberSession;
      await _setBool('remember_session', rememberSession);
    }
    if (twoStepHints != null) {
      this.twoStepHints = twoStepHints;
      await _setBool('two_step', twoStepHints);
    }
    if (showSplashVideo != null) {
      this.showSplashVideo = showSplashVideo;
      await _setBool('splash_video', showSplashVideo);
    }
    if (autoPlayProductMedia != null) {
      this.autoPlayProductMedia = autoPlayProductMedia;
      await _setBool('autoplay_media', autoPlayProductMedia);
    }
    if (dataSaver != null) {
      this.dataSaver = dataSaver;
      await _setBool('data_saver', dataSaver);
    }
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
    await _load();
  }

  String get languageLabel => languageCode == 'ar' ? 'العربية' : 'English';

  String get currencyLabel => switch (currencyCode) {
        'EGP' => 'جنيه مصري (ج.م)',
        'USD' => 'دولار أمريكي',
        'SAR' => 'ريال سعودي',
        _ => currencyCode,
      };

  String get textScaleLabel => switch (textScale) {
        0.9 => 'صغير',
        1.15 => 'كبير',
        _ => 'عادي',
      };
}
