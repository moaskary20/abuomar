import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/notifications_controller.dart';
import '../orders/order_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<NotificationsController>();
    final items = inbox.items;
    final dateFormat = DateFormat('d MMM · HH:mm', 'ar');

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(
          'الإشعارات',
          style: AppFonts.tajawal(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (inbox.unreadCount > 0)
            TextButton(
              onPressed: inbox.markAllRead,
              child: Text(
                'قراءة الكل',
                style: AppFonts.tajawal(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'لا توجد إشعارات بعد',
                style: AppFonts.tajawal(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Material(
                  color: item.read
                      ? Colors.white
                      : AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      inbox.markRead(item.id);
                      final orderId = item.orderId;
                      if (orderId == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(orderId: orderId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          Icon(
                            item.read
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: AppFonts.tajawal(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: AppTheme.cocoa,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.body,
                                  style: AppFonts.tajawal(
                                    fontSize: 12.5,
                                    color: AppTheme.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateFormat.format(item.createdAt),
                                  style: AppFonts.tajawal(
                                    fontSize: 11,
                                    color: AppTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!item.read)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
