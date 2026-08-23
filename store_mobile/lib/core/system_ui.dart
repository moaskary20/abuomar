import 'package:flutter/services.dart';

/// شريط الحالة (ساعة/بطارية) وشريط التنقل السفلي — ثابت وواضح في كل الشاشات.
abstract final class AppSystemUi {
  static const Color _statusBar = Color(0xFFFFF8F3);
  static const Color _navBar = Color(0xFFFFFFFF);

  static const SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
    statusBarColor: _statusBar,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: true,
    systemNavigationBarColor: _navBar,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Color(0x00000000),
    systemNavigationBarContrastEnforced: false,
  );

  static Future<void> apply() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(overlay);
  }
}
