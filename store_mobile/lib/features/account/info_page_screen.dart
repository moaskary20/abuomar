import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../widgets/brand_hero_panel.dart';

class InfoPageScreen extends StatelessWidget {
  const InfoPageScreen({
    super.key,
    required this.title,
    required this.sections,
    this.variant = InfoPageVariant.privacy,
  });

  final String title;
  final List<(String, String)> sections;
  final InfoPageVariant variant;

  @override
  Widget build(BuildContext context) {
    final meta = switch (variant) {
      InfoPageVariant.privacy => (
          Icons.privacy_tip_rounded,
          'كيف نحمي بياناتك داخل التطبيق',
          'آخر تحديث: أغسطس 2026',
        ),
      InfoPageVariant.terms => (
          Icons.description_rounded,
          'شروط الاستخدام والطلب والتوصيل',
          'سارية على جميع طلبات التطبيق',
        ),
    };

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
                    _LegalTopBar(
                      title: title,
                      subtitle: meta.$2,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 14),
                    _LegalHero3D(
                      icon: meta.$1,
                      title: title,
                      subtitle: meta.$2,
                      badge: meta.$3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            sliver: SliverList.separated(
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final (heading, body) = sections[index];
                return _LegalSectionCard3D(
                  index: index + 1,
                  heading: heading,
                  body: body,
                  accent: variant == InfoPageVariant.privacy
                      ? const Color(0xFF1F7A6E)
                      : AppTheme.primary,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum InfoPageVariant { privacy, terms }

class _LegalTopBar extends StatelessWidget {
  const _LegalTopBar({
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

class _LegalHero3D extends StatelessWidget {
  const _LegalHero3D({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {

    return BrandHeroPanel3D(
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateX(-0.28)
                            ..rotateY(0.32),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withValues(alpha: 0.16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(icon, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppFonts.tajawal(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
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
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              badge,
                              style: AppFonts.tajawal(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          Text(
                            AppConfig.appNameAr,
                            style: AppFonts.tajawal(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
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

class _LegalSectionCard3D extends StatefulWidget {
  const _LegalSectionCard3D({
    required this.index,
    required this.heading,
    required this.body,
    required this.accent,
  });

  final int index;
  final String heading;
  final String body;
  final Color accent;

  @override
  State<_LegalSectionCard3D> createState() => _LegalSectionCard3DState();
}

class _LegalSectionCard3DState extends State<_LegalSectionCard3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(_pressed ? 0.01 : -0.03)
          ..rotateY(_pressed ? 0 : 0.015)
          ..translateByDouble(0, _pressed ? 3 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              color: widget.accent.withValues(alpha: _pressed ? 0.1 : 0.18),
              blurRadius: _pressed ? 10 : 18,
              offset: Offset(0, _pressed ? 5 : 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(0.2)
                ..rotateX(-0.12),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      widget.accent,
                      Color.lerp(widget.accent, Colors.black, 0.18)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  '${widget.index}',
                  style: AppFonts.tajawal(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.heading,
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.body,
                    style: AppFonts.tajawal(
                      color: AppTheme.cocoa.withValues(alpha: 0.78),
                      height: 1.7,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalContent {
  LegalContent._();

  static const privacySections = <(String, String)>[
    (
      'مقدمة',
      'نحترم خصوصيتك في تطبيق حلوانى ابوعمر. توضح هذه السياسة كيف نجمع بياناتك ونستخدمها ونحميها عند استخدامك للتطبيق أو إجراء الطلبات.',
    ),
    (
      'البيانات التي نجمعها',
      'قد نجمع اسمك، رقم الجوال، البريد الإلكتروني، عنوان التوصيل، بيانات الطلبات، ونقاط الولاء المرتبطة بحسابك، بالإضافة إلى بيانات تقنية بسيطة لتحسين أداء التطبيق.',
    ),
    (
      'كيف نستخدم البيانات',
      'نستخدم بياناتك لإتمام الطلبات، التواصل بخصوص الشحن، إدارة نقاط الولاء والكوبونات، وتحسين تجربة التسوق وخدمة العملاء.',
    ),
    (
      'مشاركة البيانات',
      'لا نبيع بياناتك الشخصية. قد نشارك معلومات محدودة مع مزودي خدمة التوصيل أو الدفع بالقدر اللازم فقط لتنفيذ طلبك.',
    ),
    (
      'حماية المعلومات',
      'نتخذ إجراءات تقنية وتنظيمية مناسبة لحماية بياناتك من الوصول غير المصرح به أو الفقد أو التعديل.',
    ),
    (
      'حقوقك',
      'يمكنك طلب الاطلاع على بياناتك أو تحديثها أو حذف حسابك عبر التواصل معنا من داخل التطبيق.',
    ),
    (
      'التحديثات',
      'قد نحدّث سياسة الخصوصية من وقت لآخر، وسيظهر أحدث إصدار داخل التطبيق.',
    ),
  ];

  static const termsSections = <(String, String)>[
    (
      'القبول بالشروط',
      'باستخدامك تطبيق حلوانى ابوعمر فإنك توافق على هذه الشروط والأحكام الخاصة بالتصفح والطلب والدفع والتوصيل.',
    ),
    (
      'الطلبات والأسعار',
      'الأسعار المعروضة داخل التطبيق بالجنيه المصري وقد تتغير دون إشعار مسبق. يتم تأكيد الطلب بعد مراجعته من المتجر حسب التوفر.',
    ),
    (
      'الدفع والتوصيل',
      'يتوفر الدفع عند الاستلام ووسائل دفع أخرى حسب الإعدادات. مواعيد التوصيل تقديرية وقد تختلف حسب المنطقة وظروف التشغيل.',
    ),
    (
      'الكوبونات ونقاط الولاء',
      'تخضع الكوبونات ونقاط الولاء لشروط الحد الأدنى والصلاحية وحدود الاستخدام المحددة في النظام.',
    ),
    (
      'الإلغاء والاسترجاع',
      'يمكن طلب إلغاء الطلب قبل بدء التجهيز. المنتجات الغذائية قد تخضع لسياسة استرجاع خاصة حسب الحالة وسبب الإرجاع.',
    ),
    (
      'مسؤولية المستخدم',
      'أنت مسؤول عن صحة بيانات الحساب والعنوان ورقم التواصل، وعن الحفاظ على سرية بيانات الدخول.',
    ),
    (
      'تعديل الشروط',
      'نحتفظ بحق تعديل هذه الشروط عند الحاجة، ويُعد استمرار استخدام التطبيق موافقة على النسخة المحدّثة.',
    ),
  ];
}
