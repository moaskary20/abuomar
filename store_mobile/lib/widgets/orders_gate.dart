import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/catalog_store.dart';

/// يتحقق من أن التطبيق يستقبل الطلبات؛ إن لم يكن يعرض رسالة الإيقاف.
Future<bool> ensureOrdersEnabled(BuildContext context) async {
  final catalog = context.read<CatalogStore>();
  await catalog.refreshStoreStatus();
  if (!context.mounted) {
    return false;
  }

  if (catalog.ordersEnabled) {
    return true;
  }

  final message = catalog.appInactiveMessage;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'الطلبات متوقفة مؤقتاً',
          style: AppFonts.tajawal(fontWeight: FontWeight.w900),
        ),
        content: Text(
          message,
          style: AppFonts.tajawal(height: 1.5, color: AppTheme.cocoa),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'حسناً',
              style: AppFonts.tajawal(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    },
  );

  return false;
}
