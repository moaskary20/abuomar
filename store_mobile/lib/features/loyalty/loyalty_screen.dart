import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../widgets/brand_hero_panel.dart';
import '../auth/login_screen.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthController>().isLoggedIn) {
        context.read<LoyaltyController>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loyalty = context.watch<LoyaltyController>();
    final auth = context.watch<AuthController>();
    final dateFormat = DateFormat('yyyy/MM/dd - HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(
          'نقاط الولاء',
          style: AppFonts.tajawal(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          BrandHeroPanel3D(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandHeroIcon3D(icon: Icons.stars_rounded, size: 54),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رصيدك الحالي',
                            style: AppFonts.tajawal(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${loyalty.points}',
                            style: AppFonts.tajawal(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          Text(
                            '≈ ${loyalty.valueInEgp.toStringAsFixed(1)} ${AppConfig.currency}',
                            style: AppFonts.tajawal(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat3D(
                        label: 'مكتسب',
                        value: '${loyalty.earnedTotal}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStat3D(
                        label: 'مستبدل',
                        value: '${loyalty.redeemedTotal}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle3D(
            title: 'قواعد البرنامج',
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 10),
          const _InfoCard3D(
            icon: Icons.add_circle_outline_rounded,
            title: 'كيف تكسب؟',
            body: 'نقطة واحدة مقابل كل 1 ج.م من قيمة الطلب بعد الدفع.',
            depth: 1,
          ),
          const SizedBox(height: 12),
          const _InfoCard3D(
            icon: Icons.card_giftcard_rounded,
            title: 'كيف تستبدل؟',
            body: 'كل 10 نقاط = 1 ج.م خصم، والحد الأدنى للاستبدال 50 نقطة.',
            depth: 2,
          ),
          const SizedBox(height: 22),
          const _SectionTitle3D(
            title: 'استبدال سريع',
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RedeemButton3D(
                  points: 50,
                  discountLabel:
                      '${loyalty.discountFromPoints(50).toStringAsFixed(0)} ${AppConfig.currency}',
                  enabled: loyalty.points >= 50,
                  onTap: () => _redeem(context, auth, loyalty, 50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RedeemButton3D(
                  points: 100,
                  discountLabel:
                      '${loyalty.discountFromPoints(100).toStringAsFixed(0)} ${AppConfig.currency}',
                  enabled: loyalty.points >= 100,
                  onTap: () => _redeem(context, auth, loyalty, 100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle3D(
            title: 'سجل الحركات',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 10),
          if (loyalty.history.isEmpty)
            const _EmptyHistory3D()
          else
            ...loyalty.history.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _HistoryCard3D(
                title: item.title,
                dateLabel: dateFormat.format(item.createdAt),
                points: item.points,
                depth: index,
              );
            }),
        ],
      ),
    );
  }

  void _redeem(
    BuildContext context,
    AuthController auth,
    LoyaltyController loyalty,
    int points,
  ) {
    if (!auth.isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final ok = loyalty.redeem(
      points,
      note:
          'استبدال $points نقطة (${loyalty.discountFromPoints(points)} ${AppConfig.currency})',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'تم استبدال $points نقطة بنجاح'
              : 'الرصيد غير كافٍ أو أقل من الحد الأدنى',
          style: AppFonts.tajawal(),
        ),
      ),
    );
  }
}

class _SectionTitle3D extends StatelessWidget {
  const _SectionTitle3D({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(-0.18)
            ..rotateX(-0.08),
          child: Container(
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
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.cocoa,
          ),
        ),
      ],
    );
  }
}

class _HeroStat3D extends StatelessWidget {
  const _HeroStat3D({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateX(-0.08),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.tajawal(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppFonts.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard3D extends StatefulWidget {
  const _InfoCard3D({
    required this.icon,
    required this.title,
    required this.body,
    this.depth = 1,
  });

  final IconData icon;
  final String title;
  final String body;
  final int depth;

  @override
  State<_InfoCard3D> createState() => _InfoCard3DState();
}

class _InfoCard3DState extends State<_InfoCard3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tilt = 0.02 + (widget.depth * 0.008);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(_pressed ? 0.01 : -tilt)
          ..rotateY(_pressed ? 0 : 0.015)
          ..translateByDouble(0, _pressed ? 3 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Color(0xFFFFF4EF)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: _pressed ? 0.1 : 0.16),
              blurRadius: _pressed ? 10 : 18,
              offset: Offset(0, _pressed ? 5 : 10),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                ..rotateX(-0.1),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.18),
                      AppTheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: AppTheme.primary, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppFonts.tajawal(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppTheme.cocoa,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.body,
                    style: AppFonts.tajawal(
                      color: AppTheme.muted,
                      height: 1.5,
                      fontSize: 13,
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

class _RedeemButton3D extends StatefulWidget {
  const _RedeemButton3D({
    required this.points,
    required this.discountLabel,
    required this.enabled,
    required this.onTap,
  });

  final int points;
  final String discountLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_RedeemButton3D> createState() => _RedeemButton3DState();
}

class _RedeemButton3DState extends State<_RedeemButton3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(_pressed ? 0.02 : -0.05)
          ..translateByDouble(0, _pressed ? 4 : 0, 0, 1),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.enabled
                ? const [AppTheme.primaryDark, AppTheme.primary, Color(0xFFE85A3C)]
                : [
                    AppTheme.muted.withValues(alpha: 0.55),
                    AppTheme.muted.withValues(alpha: 0.35),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.enabled ? AppTheme.primary : AppTheme.muted)
                  .withValues(alpha: _pressed ? 0.18 : 0.32),
              blurRadius: _pressed ? 10 : 18,
              offset: Offset(0, _pressed ? 5 : 10),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'استبدال ${widget.points}',
              style: AppFonts.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '= ${widget.discountLabel}',
              style: AppFonts.tajawal(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard3D extends StatefulWidget {
  const _HistoryCard3D({
    required this.title,
    required this.dateLabel,
    required this.points,
    this.depth = 0,
  });

  final String title;
  final String dateLabel;
  final int points;
  final int depth;

  @override
  State<_HistoryCard3D> createState() => _HistoryCard3DState();
}

class _HistoryCard3DState extends State<_HistoryCard3D> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final positive = widget.points >= 0;
    final accent = positive ? const Color(0xFF276749) : AppTheme.primary;
    final tilt = 0.015 + ((widget.depth % 3) * 0.006);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_pressed ? 0.01 : -tilt)
            ..rotateY(_pressed ? 0 : 0.012)
            ..translateByDouble(0, _pressed ? 2 : 0, 0, 1),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Colors.white, Color(0xFFFFF4EF)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: _pressed ? 0.08 : 0.14),
                blurRadius: _pressed ? 8 : 14,
                offset: Offset(0, _pressed ? 4 : 8),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Row(
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateY(0.22)
                  ..rotateX(-0.1),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: accent.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    positive
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppFonts.tajawal(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.cocoa,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.dateLabel,
                      style: AppFonts.tajawal(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: accent.withValues(alpha: 0.1),
                ),
                child: Text(
                  '${positive ? '+' : ''}${widget.points}',
                  style: AppFonts.tajawal(
                    fontWeight: FontWeight.w900,
                    color: accent,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory3D extends StatelessWidget {
  const _EmptyHistory3D();

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.03),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF4EF)],
          ),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cocoa.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 36,
              color: AppTheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              'لا توجد حركات بعد',
              style: AppFonts.tajawal(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
