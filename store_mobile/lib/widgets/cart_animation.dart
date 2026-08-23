import 'package:flutter/material.dart';

import '../core/theme.dart';

/// حركة إضافة للسلة: نبضة الزر + أيقونة تطير نحو شريط السلة
class CartAnimation {
  CartAnimation._();

  static Future<void> play({
    required BuildContext context,
    required GlobalKey buttonKey,
  }) async {
    final overlay = Overlay.maybeOf(context);
    final buttonContext = buttonKey.currentContext;
    if (overlay == null || buttonContext == null) {
      return;
    }

    final buttonBox = buttonContext.findRenderObject() as RenderBox?;
    if (buttonBox == null || !buttonBox.hasSize) {
      return;
    }

    final start = buttonBox.localToGlobal(
      Offset(buttonBox.size.width / 2, buttonBox.size.height / 2),
    );

    final size = MediaQuery.sizeOf(context);
    // تبويب السلة هو الثاني من اليمين في RTL تقريباً عند 3/8 العرض
    final end = Offset(size.width * 0.62, size.height - 42);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _FlyingCartIcon(
          start: start,
          end: end,
          onDone: () {
            entry.remove();
          },
        );
      },
    );

    overlay.insert(entry);
  }
}

class _FlyingCartIcon extends StatefulWidget {
  const _FlyingCartIcon({
    required this.start,
    required this.end,
    required this.onDone,
  });

  final Offset start;
  final Offset end;
  final VoidCallback onDone;

  @override
  State<_FlyingCartIcon> createState() => _FlyingCartIconState();
}

class _FlyingCartIconState extends State<_FlyingCartIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _position;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _position = Tween<Offset>(begin: widget.start, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.35), weight: 70),
    ]).animate(_controller);
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1)),
    );

    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned(
                left: _position.value.dx - 18,
                top: _position.value.dy - 18,
                child: Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.35),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

/// زر إضافة للسلة مع حركة نبض
class AddToCartButton extends StatefulWidget {
  const AddToCartButton({
    super.key,
    required this.onPressed,
    this.compact = true,
    this.label,
  });

  final Future<void> Function(GlobalKey buttonKey) onPressed;
  final bool compact;
  final String? label;

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton>
    with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  late final AnimationController _bounce;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.82), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.12), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 25),
    ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    _bounce.forward(from: 0);
    await widget.onPressed(_key);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.compact
          ? IconButton.filled(
              key: _key,
              onPressed: _handleTap,
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            )
          : FilledButton.icon(
              key: _key,
              onPressed: _handleTap,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                widget.label ?? 'أضف إلى السلة',
                style: AppFonts.tajawal(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}
