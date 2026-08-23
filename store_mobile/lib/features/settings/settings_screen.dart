import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/settings_controller.dart';
import '../../widgets/brand_hero_panel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: AppFonts.tajawal(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          BrandHeroPanel3D(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: [
                const BrandHeroIcon3D(icon: Icons.settings_rounded, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات التطبيق',
                        style: AppFonts.tajawal(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'خصّص الإشعارات والخصوصية',
                        style: AppFonts.tajawal(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard3D(
            title: 'الإشعارات',
            icon: Icons.notifications_active_rounded,
            depth: 1,
            children: [
              _SwitchTile3D(
                icon: Icons.notifications_active_outlined,
                title: 'تفعيل الإشعارات',
                subtitle: 'التحكم العام بكل الإشعارات',
                value: settings.notificationsEnabled,
                onChanged: (v) => settings.update(notificationsEnabled: v),
              ),
              _SwitchTile3D(
                icon: Icons.local_shipping_outlined,
                title: 'تحديثات الطلبات',
                subtitle: 'إشعار بحالة الشحن والتسليم',
                value: settings.orderUpdatesNotify,
                enabled: settings.notificationsEnabled,
                onChanged: (v) => settings.update(orderUpdatesNotify: v),
              ),
              _SwitchTile3D(
                icon: Icons.local_offer_outlined,
                title: 'العروض والخصومات',
                subtitle: 'كوبونات وعروض حلوانى ابوعمر',
                value: settings.offersNotify,
                enabled: settings.notificationsEnabled,
                onChanged: (v) => settings.update(offersNotify: v),
              ),
              _SwitchTile3D(
                icon: Icons.stars_outlined,
                title: 'نقاط الولاء',
                subtitle: 'تنبيهات الكسب والاستبدال',
                value: settings.loyaltyNotify,
                enabled: settings.notificationsEnabled,
                onChanged: (v) => settings.update(loyaltyNotify: v),
              ),
              _SwitchTile3D(
                icon: Icons.volume_up_outlined,
                title: 'صوت الإشعار',
                value: settings.soundEnabled,
                enabled: settings.notificationsEnabled,
                onChanged: (v) => settings.update(soundEnabled: v),
              ),
              _SwitchTile3D(
                icon: Icons.vibration,
                title: 'الاهتزاز',
                value: settings.vibrationEnabled,
                enabled: settings.notificationsEnabled,
                onChanged: (v) => settings.update(vibrationEnabled: v),
              ),
            ],
          ),
          _SectionCard3D(
            title: 'الخصوصية والأمان',
            icon: Icons.shield_rounded,
            depth: 3,
            children: [
              _SwitchTile3D(
                icon: Icons.fingerprint,
                title: 'تسجيل الدخول بالبصمة',
                subtitle: 'يتطلب دعماً من الجهاز',
                value: settings.biometricLogin,
                onChanged: (v) {
                  settings.update(biometricLogin: v);
                  _toast(
                    context,
                    v ? 'سيتم تفعيل البصمة عند ربط الجهاز' : 'تم إيقاف البصمة',
                  );
                },
              ),
              _SwitchTile3D(
                icon: Icons.lock_outline,
                title: 'تذكر الجلسة',
                subtitle: 'البقاء متصلاً على هذا الجهاز',
                value: settings.rememberSession,
                onChanged: (v) => settings.update(rememberSession: v),
              ),
              _SwitchTile3D(
                icon: Icons.security_outlined,
                title: 'تنبيهات الأمان',
                subtitle: 'إشعارات عند تسجيل الدخول',
                value: settings.twoStepHints,
                onChanged: (v) => settings.update(twoStepHints: v),
              ),
              _SwitchTile3D(
                icon: Icons.recommend_outlined,
                title: 'عروض مخصصة',
                subtitle: 'اقتراحات حسب اهتماماتك',
                value: settings.personalizedOffers,
                onChanged: (v) => settings.update(personalizedOffers: v),
              ),
              _SwitchTile3D(
                icon: Icons.analytics_outlined,
                title: 'تحسين التجربة (تحليلات)',
                subtitle: 'بيانات مجهولة لتحسين التطبيق',
                value: settings.analyticsEnabled,
                onChanged: (v) => settings.update(analyticsEnabled: v),
              ),
              _SwitchTile3D(
                icon: Icons.location_on_outlined,
                title: 'مشاركة الموقع للتوصيل',
                value: settings.shareLocationForDelivery,
                onChanged: (v) => settings.update(shareLocationForDelivery: v),
              ),
              _SwitchTile3D(
                icon: Icons.history,
                title: 'حفظ سجل البحث',
                value: settings.saveSearchHistory,
                onChanged: (v) => settings.update(saveSearchHistory: v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: AppFonts.tajawal())),
    );
  }
}

class _SectionCard3D extends StatelessWidget {
  const _SectionCard3D({
    required this.title,
    required this.icon,
    required this.children,
    this.depth = 1,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final tilt = 0.012 + (depth * 0.004);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-tilt)
          ..rotateY(tilt * 0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 2, 6, 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryDark, AppTheme.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: AppFonts.tajawal(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.cocoa,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Colors.white, Color(0xFFFFF4EF)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cocoa.withValues(alpha: 0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i != children.length - 1)
                        Divider(
                          height: 1,
                          indent: 64,
                          endIndent: 14,
                          color: AppTheme.cocoa.withValues(alpha: 0.06),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCube3D extends StatelessWidget {
  const _IconCube3D({
    required this.icon,
    this.enabled = true,
  });

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateY(-0.16)
        ..rotateX(-0.08),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled
                ? const [AppTheme.primaryDark, AppTheme.primary]
                : [
                    AppTheme.muted.withValues(alpha: 0.45),
                    AppTheme.muted.withValues(alpha: 0.25),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: (enabled ? AppTheme.primary : AppTheme.muted)
                  .withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _SwitchTile3D extends StatefulWidget {
  const _SwitchTile3D({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  State<_SwitchTile3D> createState() => _SwitchTile3DState();
}

class _SwitchTile3DState extends State<_SwitchTile3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onChanged(!widget.value);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_pressed ? 0.01 : -0.012)
          ..translateByDouble(0, _pressed ? 2 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        color: _pressed
            ? AppTheme.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        child: Row(
          children: [
            _IconCube3D(icon: widget.icon, enabled: widget.enabled),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: widget.enabled ? AppTheme.cocoa : AppTheme.muted,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle!,
                      style: AppFonts.tajawal(
                        color: AppTheme.muted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(0.12),
              child: Switch.adaptive(
                value: widget.value,
                onChanged: widget.enabled ? widget.onChanged : null,
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

