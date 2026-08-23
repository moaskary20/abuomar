import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/system_ui.dart';
import '../../data/settings_controller.dart';
import '../shell/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _asset = 'assit/splash.mp4';

  VideoPlayerController? _controller;
  Timer? _fallbackTimer;
  bool _navigated = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    AppSystemUi.apply();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final settings = context.read<SettingsController>();
    if (!settings.showSplashVideo) {
      _goHome();
      return;
    }
    await _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(_asset);
      _controller = controller;
      await controller.initialize().timeout(const Duration(seconds: 8));
      if (!mounted || _navigated) {
        await controller.dispose();
        _controller = null;
        return;
      }

      final size = controller.value.size;
      if (size.width <= 0 || size.height <= 0) {
        throw StateError('Splash video has invalid size');
      }

      await controller.setLooping(false);
      await controller.setVolume(kIsWeb ? 0 : 1);
      await controller.play();
      if (!mounted || _navigated) {
        return;
      }

      controller.addListener(_onVideoTick);
      setState(() => _ready = true);

      final duration = controller.value.duration;
      final wait = duration > Duration.zero
          ? duration + const Duration(milliseconds: 800)
          : const Duration(seconds: 6);
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(wait, _goHome);
    } catch (e, st) {
      debugPrint('Splash video failed: $e\n$st');
      _goHome();
    }
  }

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.hasError) {
      _goHome();
      return;
    }
    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 250)) {
      _goHome();
    }
  }

  void _goHome() {
    if (_navigated || !mounted) {
      return;
    }
    _navigated = true;
    _fallbackTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    AppSystemUi.apply();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const MainShell(),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    final controller = _controller;
    _controller = null;
    controller?.removeListener(_onVideoTick);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goHome,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: ColoredBox(
          color: Colors.black,
          child: _ready && _controller != null
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                )
              : const SizedBox.expand(
                  child: ColoredBox(color: Colors.black),
                ),
        ),
      ),
    );
  }
}
