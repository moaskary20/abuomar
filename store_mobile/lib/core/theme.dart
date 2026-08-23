import 'package:flutter/material.dart';

import 'system_ui.dart';

/// خط Tajawal المضمّن محلياً (من عائلة Google Fonts) — بدون شبكة عند الإقلاع
class AppFonts {
  AppFonts._();

  static const String family = 'Tajawal';

  static TextStyle tajawal({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    double? letterSpacing,
    TextOverflow? overflow,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      overflow: overflow,
    );
  }

  static TextTheme textTheme([TextTheme? base]) {
    final source = base ?? ThemeData.light().textTheme;
    return source.apply(
      fontFamily: family,
      bodyColor: const Color(0xFF2B1A12),
      displayColor: const Color(0xFF2B1A12),
    );
  }
}

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFFDD1C1F);
  static const Color primaryDark = Color(0xFFB01416);
  static const Color cocoa = Color(0xFF2B1A12);
  static const Color cream = Color(0xFFFFF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF6D5C54);

  static const String fontFamily = AppFonts.family;

  static TextStyle text({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return AppFonts.tajawal(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  static ThemeData light() {
    final tajawal = AppFonts.textTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      textTheme: tajawal,
      primaryTextTheme: tajawal,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: cocoa,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: cocoa,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: AppSystemUi.overlay,
        titleTextStyle: AppFonts.tajawal(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: cocoa,
        ),
        toolbarTextStyle: AppFonts.tajawal(color: cocoa, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cocoa.withValues(alpha: 0.08)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(
          AppFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedLabelStyle: AppFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        extendedTextStyle: AppFonts.tajawal(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: AppFonts.tajawal(color: muted),
        hintStyle: AppFonts.tajawal(color: muted),
        helperStyle: AppFonts.tajawal(color: muted, fontSize: 12),
        errorStyle: AppFonts.tajawal(color: primary, fontSize: 12),
        floatingLabelStyle: AppFonts.tajawal(color: primary),
        prefixStyle: AppFonts.tajawal(color: cocoa),
        suffixStyle: AppFonts.tajawal(color: cocoa),
      ),
      chipTheme: ChipThemeData(
        labelStyle: AppFonts.tajawal(fontWeight: FontWeight.w600),
        secondaryLabelStyle: AppFonts.tajawal(fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: AppFonts.tajawal(color: Colors.white, fontSize: 14),
        actionTextColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: AppFonts.tajawal(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: cocoa,
        ),
        contentTextStyle: AppFonts.tajawal(color: cocoa, height: 1.5, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppFonts.tajawal(
          fontWeight: FontWeight.w700,
          color: cocoa,
          fontSize: 15,
        ),
        subtitleTextStyle: AppFonts.tajawal(color: muted, fontSize: 13),
        leadingAndTrailingTextStyle: AppFonts.tajawal(color: cocoa),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: AppFonts.tajawal(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppFonts.tajawal(fontWeight: FontWeight.w600),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: AppFonts.tajawal(color: Colors.white, fontSize: 12),
      ),
      popupMenuTheme: PopupMenuThemeData(
        textStyle: AppFonts.tajawal(color: cocoa, fontSize: 14),
        labelTextStyle: WidgetStatePropertyAll(
          AppFonts.tajawal(color: cocoa, fontSize: 14),
        ),
      ),
      badgeTheme: BadgeThemeData(
        textStyle: AppFonts.tajawal(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
