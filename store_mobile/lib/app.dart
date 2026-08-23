import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/system_ui.dart';
import 'core/theme.dart';
import 'data/app_state.dart';
import 'data/catalog_store.dart';
import 'data/mock_store_data.dart';
import 'data/notifications_controller.dart';
import 'data/settings_controller.dart';
import 'features/splash/splash_screen.dart';
import 'models/store_models.dart';
import 'widgets/in_app_order_banner.dart';

class AboOmarApp extends StatelessWidget {
  const AboOmarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final catalog = CatalogStore();
            MockStoreData.bind(catalog);
            catalog.addListener(() {
              PaymentMethodsCatalog.replaceAll(catalog.paymentMethods);
            });
            return catalog;
          },
        ),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => FavoritesController()),
        ChangeNotifierProvider(create: (_) => LoyaltyController()),
        ChangeNotifierProvider(create: (_) => OrdersController()),
        ChangeNotifierProvider(create: (_) => ShellTabController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProxyProvider<AuthController, AddressesController>(
          create: (_) => AddressesController(),
          update: (_, auth, addresses) {
            final ctrl = addresses ?? AddressesController();
            ctrl.syncUser(auth.user);
            return ctrl;
          },
        ),
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProxyProvider3<AuthController, OrdersController,
            SettingsController, NotificationsController>(
          create: (_) => NotificationsController(),
          update: (_, auth, orders, settings, previous) {
            final ctrl = previous ?? NotificationsController();
            ctrl.sync(auth: auth, orders: orders, settings: settings);
            return ctrl;
          },
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appNameAr,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return AnnotatedRegion(
            value: AppSystemUi.overlay,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: DefaultTextStyle(
                style: AppFonts.tajawal(
                  color: AppTheme.cocoa,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                child: IconTheme(
                  data: const IconThemeData(color: AppTheme.cocoa),
                  child: InAppOrderBannerHost(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
