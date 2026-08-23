import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/brand_hero_panel.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر فتح الرابط', style: AppFonts.tajawal()),
        ),
      );
    }
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label', style: AppFonts.tajawal()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channels = <_ContactChannel>[
      _ContactChannel(
        icon: Icons.phone_rounded,
        title: 'اتصال هاتفي',
        subtitle: AppConfig.storePhone,
        hint: 'اتصل مباشرة بالمتجر',
        accent: const Color(0xFF2F6B3A),
        onTap: () => _launch(
          context,
          Uri(scheme: 'tel', path: AppConfig.storePhone),
        ),
        onLongPress: () => _copy(context, AppConfig.storePhone, 'رقم الهاتف'),
      ),
      _ContactChannel(
        icon: Icons.chat_rounded,
        title: 'واتساب',
        subtitle: AppConfig.storeWhatsApp,
        hint: 'راسلنا فوراً عبر واتساب',
        accent: const Color(0xFF1F7A6E),
        onTap: () => _launch(
          context,
          Uri.parse('https://wa.me/${AppConfig.storeWhatsAppIntl}'),
        ),
        onLongPress: () =>
            _copy(context, AppConfig.storeWhatsApp, 'رقم واتساب'),
      ),
      _ContactChannel(
        icon: Icons.facebook_rounded,
        title: 'فيسبوك',
        subtitle: AppConfig.appNameAr,
        hint: 'تابع صفحتنا على فيسبوك',
        accent: const Color(0xFF1877F2),
        onTap: () => _launch(context, Uri.parse(AppConfig.storeFacebook)),
        onLongPress: () =>
            _copy(context, AppConfig.storeFacebook, 'رابط فيسبوك'),
      ),
      _ContactChannel(
        icon: Icons.music_note_rounded,
        title: 'تيك توك',
        subtitle: '@aboomarpastry1',
        hint: 'شاهد فيديوهاتنا على تيك توك',
        accent: const Color(0xFF111111),
        onTap: () => _launch(context, Uri.parse(AppConfig.storeTikTok)),
        onLongPress: () =>
            _copy(context, AppConfig.storeTikTok, 'رابط تيك توك'),
      ),
      _ContactChannel(
        icon: Icons.email_rounded,
        title: 'البريد الإلكتروني',
        subtitle: AppConfig.storeEmail,
        hint: 'للاستفسارات الرسمية',
        accent: const Color(0xFF9B4D1B),
        onTap: () => _launch(
          context,
          Uri(
            scheme: 'mailto',
            path: AppConfig.storeEmail,
            query:
                'subject=${Uri.encodeComponent('استفسار من تطبيق ${AppConfig.appNameAr}')}',
          ),
        ),
        onLongPress: () => _copy(context, AppConfig.storeEmail, 'البريد'),
      ),
      _ContactChannel(
        icon: Icons.language_rounded,
        title: 'الموقع الإلكتروني',
        subtitle: AppConfig.storeWebsite,
        hint: 'تصفّح المتجر على الويب',
        accent: AppTheme.primary,
        onTap: () => _launch(context, Uri.parse(AppConfig.storeWebsite)),
        onLongPress: () =>
            _copy(context, AppConfig.storeWebsite, 'رابط الموقع'),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    _PageTopBar(
                      title: 'تواصل معنا',
                      subtitle: 'قنوات الدعم بتجربة ثلاثية الأبعاد',
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 14),
                    const _ContactHero3D(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                'قنوات التواصل',
                style: AppFonts.tajawal(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList.separated(
              itemCount: channels.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == channels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'اضغط مطولاً على أي خيار لنسخه',
                      textAlign: TextAlign.center,
                      style: AppFonts.tajawal(
                        color: AppTheme.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  );
                }
                return _ContactCard3D(channel: channels[index], depth: index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChannel {
  const _ContactChannel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String hint;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
}

class _PageTopBar extends StatelessWidget {
  const _PageTopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundBack3D(onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.cocoa,
                ),
              ),
              Text(
                subtitle,
                style: AppFonts.tajawal(
                  color: AppTheme.muted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundBack3D extends StatefulWidget {
  const _RoundBack3D({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RoundBack3D> createState() => _RoundBack3DState();
}

class _RoundBack3DState extends State<_RoundBack3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoa.withValues(alpha: _pressed ? 0.06 : 0.12),
              blurRadius: _pressed ? 6 : 14,
              offset: Offset(0, _pressed ? 2 : 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppTheme.cocoa,
        ),
      ),
    );
  }
}

class _ContactHero3D extends StatelessWidget {
  const _ContactHero3D();

  @override
  Widget build(BuildContext context) {

    return BrandHeroPanel3D(
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Row(
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(-0.28)
                        ..rotateY(0.35),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConfig.appNameAr,
                            style: AppFonts.tajawal(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'نحن هنا لمساعدتك في الطلبات والاستفسارات',
                            style: AppFonts.tajawal(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.35,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ContactCard3D extends StatefulWidget {
  const _ContactCard3D({
    required this.channel,
    required this.depth,
  });

  final _ContactChannel channel;
  final int depth;

  @override
  State<_ContactCard3D> createState() => _ContactCard3DState();
}

class _ContactCard3DState extends State<_ContactCard3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.channel;
    final tilt = 0.012 + (widget.depth % 3) * 0.004;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        c.onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        c.onLongPress();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(_pressed ? 0.01 : -0.03)
          ..rotateY(_pressed ? 0 : tilt)
          ..translateByDouble(0, _pressed ? 3 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF8F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: c.accent.withValues(alpha: _pressed ? 0.12 : 0.22),
              blurRadius: _pressed ? 10 : 18,
              offset: Offset(0, _pressed ? 5 : 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(0.2)
                ..rotateX(-0.1),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      c.accent.withValues(alpha: 0.2),
                      c.accent.withValues(alpha: 0.06),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.accent.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(c.icon, color: c.accent, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.tajawal(
                      color: AppTheme.cocoa.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.hint,
                    style: AppFonts.tajawal(
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(-0.25),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: c.accent.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.chevron_left_rounded, color: c.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
