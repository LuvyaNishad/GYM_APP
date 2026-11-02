import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Preload the lightweight navigator, then warm its screen during idle time.
/// Selecting it earlier mounts immediately; an already loaded tab stays alive.
class DeferredTab extends StatefulWidget {
  const DeferredTab({required this.index, required this.child, super.key});
  final int index;
  final Widget child;

  @override
  State<DeferredTab> createState() => _DeferredTabState();
}

class _DeferredTabState extends State<DeferredTab> {
  bool _loaded = false;
  Timer? _warmup;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _scheduleWarmup);
    _scheduleWarmup();
  }

  void _scheduleWarmup() {
    if (_loaded || _warmup?.isActive == true) return;
    _warmup = Timer(Duration(milliseconds: 500 + widget.index * 180), () {
      SchedulerBinding.instance.scheduleTask(
        () {
          if (!mounted || _loaded) return;
          final state = WidgetsBinding.instance.lifecycleState;
          if (state != null && state != AppLifecycleState.resumed) return;
          setState(() => _loaded = true);
        },
        Priority.idle,
        debugLabel: 'Warm tab ${widget.index}',
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) {
      _loaded = true;
      _warmup?.cancel();
    }
  }

  @override
  void dispose() {
    _warmup?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _loaded ? widget.child : const SizedBox.shrink();
}
