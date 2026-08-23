import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class ConfettiRain extends StatefulWidget {
  const ConfettiRain({
    super.key,
    this.pieceCount = 92,
  });

  final int pieceCount;

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final List<_Paper> _papers;
  final _random = math.Random();

  static const _colors = [
    AppTheme.primary,
    AppTheme.primaryDark,
    Color(0xFFE8A07A),
    Color(0xFFFFD27A),
    Color(0xFFFFF3E8),
    Colors.white,
    Color(0xFFC47A1A),
  ];

  @override
  void initState() {
    super.initState();
    _papers = List.generate(widget.pieceCount, (_) => _spawn(initial: true));
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  _Paper _spawn({bool initial = false}) {
    return _Paper(
      x: _random.nextDouble(),
      y: initial ? _random.nextDouble() * -1.1 : -0.12 - _random.nextDouble() * 0.35,
      speed: 0.18 + _random.nextDouble() * 0.28,
      sway: _random.nextDouble() * math.pi * 2,
      swaySpeed: 1.2 + _random.nextDouble() * 2.4,
      angle: _random.nextDouble() * math.pi,
      spin: (_random.nextDouble() - 0.5) * 6,
      color: _colors[_random.nextInt(_colors.length)],
      width: 6 + _random.nextDouble() * 8,
      height: 10 + _random.nextDouble() * 12,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ticker,
        builder: (context, _) {
          const dt = 1 / 60;
          for (var i = 0; i < _papers.length; i++) {
            final paper = _papers[i];
            paper.y += paper.speed * dt;
            paper.sway += paper.swaySpeed * dt;
            paper.angle += paper.spin * dt;
            if (paper.y > 1.12) {
              _papers[i] = _spawn();
            }
          }
          return CustomPaint(
            painter: _ConfettiPainter(List<_Paper>.from(_papers)),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Paper {
  _Paper({
    required this.x,
    required this.y,
    required this.speed,
    required this.sway,
    required this.swaySpeed,
    required this.angle,
    required this.spin,
    required this.color,
    required this.width,
    required this.height,
  });

  double x;
  double y;
  final double speed;
  double sway;
  final double swaySpeed;
  double angle;
  final double spin;
  final Color color;
  final double width;
  final double height;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.papers);

  final List<_Paper> papers;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final paper in papers) {
      final dx = paper.x * size.width + math.sin(paper.sway) * 18;
      final dy = paper.y * size.height;
      paint.color = paper.color;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(paper.angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: paper.width,
            height: paper.height,
          ),
          const Radius.circular(1.6),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
