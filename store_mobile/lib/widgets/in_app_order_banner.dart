import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../data/notifications_controller.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/orders/order_details_screen.dart';

class InAppOrderBannerHost extends StatelessWidget {
  const InAppOrderBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final banner = context.watch<NotificationsController>().banner;

    return Stack(
      children: [
        child,
        if (banner != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            right: 12,
            child: _BannerCard(notification: banner),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final inbox = context.read<NotificationsController>();

    return Material(
      color: Colors.transparent,
      child: Dismissible(
        key: ValueKey(notification.id),
        direction: DismissDirection.up,
        onDismissed: (_) => inbox.dismissBanner(),
        child: GestureDetector(
          onTap: () {
            inbox.dismissBanner();
            inbox.markRead(notification.id);
            final orderId = notification.orderId;
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => orderId == null
                    ? const NotificationsScreen()
                    : OrderDetailsScreen(orderId: orderId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: AppFonts.tajawal(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppTheme.cocoa,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: AppFonts.tajawal(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: inbox.dismissBanner,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
