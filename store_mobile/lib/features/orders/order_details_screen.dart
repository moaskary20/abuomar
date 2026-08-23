import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../widgets/store_network_image.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrdersController>().findById(orderId);
    final dateFormat = DateFormat('yyyy/MM/dd - HH:mm');

    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('تفاصيل الطلب', style: AppFonts.tajawal(fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Text(
            'الطلب غير موجود',
            style: AppFonts.tajawal(color: AppTheme.muted),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تفاصيل الطلب',
          style: AppFonts.tajawal(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cocoa.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: AppFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateFormat.format(order.createdAt),
                  style: AppFonts.tajawal(color: AppTheme.muted),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: order.statusLabelAr, color: AppTheme.primary),
                    _Chip(label: order.paymentStatusLabelAr, color: const Color(0xFF2C7A7B)),
                    _Chip(label: order.paymentMethodLabelAr, color: AppTheme.cocoa),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'المنتجات',
            style: AppFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...order.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cocoa.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: StoreNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 64,
                      height: 64,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.tajawal(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} ${AppConfig.currency}',
                          style: AppFonts.tajawal(color: AppTheme.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.lineTotal.toStringAsFixed(0)} ${AppConfig.currency}',
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'التوصيل',
            style: AppFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _InfoBox(
            children: [
              _InfoRow(label: 'المدينة', value: order.shippingCity ?? '—'),
              _InfoRow(label: 'العنوان', value: order.shippingAddress ?? '—'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'الملخص',
            style: AppFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _InfoBox(
            children: [
              _InfoRow(
                label: 'المجموع الفرعي',
                value: '${order.subtotal.toStringAsFixed(0)} ${AppConfig.currency}',
              ),
              _InfoRow(
                label: 'الشحن',
                value: '${order.shippingAmount.toStringAsFixed(0)} ${AppConfig.currency}',
              ),
              if (order.discountAmount > 0)
                _InfoRow(
                  label: order.couponCode == null
                      ? 'الخصم'
                      : 'خصم الكوبون (${order.couponCode})',
                  value: '-${order.discountAmount.toStringAsFixed(0)} ${AppConfig.currency}',
                ),
              _InfoRow(
                label: 'نقاط الولاء المكتسبة',
                value: '+${order.pointsEarned}',
              ),
              const Divider(height: 20),
              _InfoRow(
                label: 'الإجمالي',
                value: '${order.total.toStringAsFixed(0)} ${AppConfig.currency}',
                emphasize: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.tajawal(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cocoa.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppFonts.tajawal(
              color: emphasize ? AppTheme.cocoa : AppTheme.muted,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: AppFonts.tajawal(
                fontWeight: FontWeight.w800,
                color: emphasize ? AppTheme.primary : AppTheme.cocoa,
                fontSize: emphasize ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
