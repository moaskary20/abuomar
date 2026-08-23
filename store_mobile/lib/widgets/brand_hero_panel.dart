import 'package:flutter/material.dart';

import '../core/theme.dart';

/// بانر علوي أحمر ثلاثي الأبعاد — الأحمر فوق التأثير الأبيض (خلف البطاقة).
class BrandHeroPanel3D extends StatelessWidget {
  const BrandHeroPanel3D({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 20, 18, 18),
    this.borderRadius = 26,
    this.applyTilt = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool applyTilt;

  static const gradient = LinearGradient(
    colors: [
      Color(0xFF7A0C10),
      AppTheme.primaryDark,
      AppTheme.primary,
      Color(0xFFE85A3C),
    ],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final panel = Stack(
      clipBehavior: Clip.none,
      children: [
        // التأثير الأبيض خلف البطاقة الحمراء
        Positioned(
          top: -28,
          left: -18,
          child: Transform.rotate(
            angle: -0.4,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.white.withValues(alpha: 0.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -36,
          right: -14,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.32),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        // المستطيل الأحمر فوق التأثير الأبيض
        Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.36),
                blurRadius: 26,
                offset: const Offset(0, 14),
                spreadRadius: -6,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );

    if (!applyTilt) {
      return panel;
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.00115)
        ..rotateX(-0.05)
        ..rotateY(0.03),
      child: panel,
    );
  }
}

/// أيقونة زجاجية ثلاثية الأبعاد داخل البانر الأحمر
class BrandHeroIcon3D extends StatelessWidget {
  const BrandHeroIcon3D({
    super.key,
    required this.icon,
    this.size = 54,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(-0.28)
        ..rotateY(0.32),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.52),
      ),
    );
  }
}
