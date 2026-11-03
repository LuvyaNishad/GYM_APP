import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Draws before storage opens, and never mounts data-dependent screens early.
class AppStartup extends StatefulWidget {
  const AppStartup({
    required this.initialize,
    required this.onReady,
    required this.failureBuilder,
    required this.child,
    super.key,
  });

  final Future<void> Function() initialize;
  final VoidCallback onReady;
  final Widget Function(Object error) failureBuilder;
  final Widget child;

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool _ready = false, _finished = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    try {
      await widget.initialize();
      if (!mounted) return;
      widget.onReady();
      setState(() => _ready = true);
    } catch (error, stack) {
      debugPrint('LEON bootstrap failed: $error\n$stack');
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error case final error?) return widget.failureBuilder(error);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            widget.child
          else
            const ColoredBox(color: AppColors.background),
          if (!_finished)
            LaunchLogo(
              ready: _ready,
              onFinished: () {
                if (mounted) setState(() => _finished = true);
              },
            ),
        ],
      ),
    );
  }
}

/// A single light sweep; readiness interrupts it instead of adding a delay.
class LaunchLogo extends StatefulWidget {
  const LaunchLogo({required this.ready, required this.onFinished, super.key});
  final bool ready;
  final VoidCallback onFinished;

  @override
  State<LaunchLogo> createState() => _LaunchLogoState();
}

class _LaunchLogoState extends State<LaunchLogo> with TickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final _exit =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 160),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      });
  bool _reduced = false, _started = false, _exiting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _sweep.value = 1;
    } else if (!_started) {
      _sweep.forward();
    }
    _started = true;
    if (widget.ready) _finish();
  }

  @override
  void didUpdateWidget(LaunchLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready) _finish();
  }

  void _finish() {
    if (_exiting) return;
    _exiting = true;
    // The destination gets its first layout before the overlay fades away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sweep.stop();
      if (_reduced) {
        widget.onFinished();
      } else {
        _sweep.animateTo(
          1,
          duration: _exit.duration,
          curve: Curves.easeOutCubic,
        );
        _exit.forward();
      }
    });
  }

  @override
  void dispose() {
    _sweep.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: widget.ready,
    child: FadeTransition(
      opacity: ReverseAnimation(_exit),
      child: ColoredBox(
        color: AppColors.background,
        child: Center(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sweep,
              child: Semantics(
                label: 'LEON logo',
                image: true,
                child: Image.asset(
                  'assets/images/aeon_logo_static.png',
                  width: 96,
                  height: 96,
                  cacheWidth: (96 * MediaQuery.devicePixelRatioOf(context))
                      .ceil(),
                ),
              ),
              builder: (context, child) => Transform.scale(
                scale: _reduced
                    ? 1
                    : .985 + .015 * Curves.easeOutCubic.transform(_sweep.value),
                child: _reduced || _sweep.value <= 0 || _sweep.value >= 1
                    ? child
                    : ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (bounds) {
                          final progress = _reduced ? 1.0 : _sweep.value;
                          final x = bounds.width * (-.5 + 2 * progress);
                          return LinearGradient(
                            colors: [
                              Colors.transparent,
                              progress > 0 && progress < 1
                                  ? const Color(0x24FFFFFF)
                                  : Colors.transparent,
                              Colors.transparent,
                            ],
                          ).createShader(
                            Rect.fromLTWH(
                              x - bounds.width * .22,
                              0,
                              bounds.width * .44,
                              bounds.height,
                            ),
                          );
                        },
                        child: child,
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
